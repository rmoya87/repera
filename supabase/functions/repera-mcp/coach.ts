import { z } from "npm:zod@4.3.6";
import type { McpServer } from "npm:@modelcontextprotocol/server@2.0.0";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2.58.0";

const result = (data: unknown) => ({
  content: [{ type: "text" as const, text: JSON.stringify(data) }],
});
const day = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);
const weeks = z.number().int().min(1).max(52);
const phase = z.strictObject({
  title: z.string().trim().min(2).max(100),
  weeks: weeks,
  focus: z.string().trim().min(3).max(400),
  targetSessionsPerWeek: z.number().int().min(1).max(7),
  progressionRule: z.string().trim().min(3).max(400),
});
type Entry = { exercise?: { name?: string; catalogId?: string; targetMuscle?: string;
  primaryRegions?: string[]; secondaryRegions?: string[]; secondaryMuscles?: string[] };
  loggedSets?: Array<{ reps?: number; weightKg?: number; rir?: number; phase?: string;
    kind?: string; toFailure?: boolean; quantityUnit?: string; durationSeconds?: number }> };
type Session = { id: string; finished_at: string; exercises: Entry[] };
function normalized(v: string) { return v.trim().normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase(); }
const gearAliases: Record<string,string> = {
  "barra":"barbell","barra olimpica":"barbell","barbell":"barbell",
  "mancuernas":"dumbbells","mancuerna":"dumbbells","dumbbells":"dumbbells",
  "gomas":"resistance_band","bandas":"resistance_band","bandas elasticas":"resistance_band",
  "resistance bands":"resistance_band","resistance_band":"resistance_band",
  "anillas":"gymnastic_rings","rings":"gymnastic_rings",
  "cajon":"plyometric_box","cajon pliometrico":"plyometric_box","box":"plyometric_box",
  "kettlebell":"kettlebell","pesa rusa":"kettlebell",
  "comba":"jump_rope","cuerda de saltar":"jump_rope","jump_rope":"jump_rope",
  "peso corporal":"bodyweight","sin material":"bodyweight","bodyweight":"bodyweight",
  "disco":"weight_plate","weight_plate":"weight_plate",
  "polea":"cable_machine","cable_machine":"cable_machine",
  "balon medicinal":"medicine_ball","medicine_ball":"medicine_ball",
  "trineo":"sled","sled":"sled","saco":"sandbag","sandbag":"sandbag",
  "air bike":"air_bike","air_bike":"air_bike","echo bike":"echo_bike","echo_bike":"echo_bike",
  "bicicleta estatica":"stationary_bike","stationary_bike":"stationary_bike",
};
function canonicalGear(v:string):string { return gearAliases[normalized(v)] ?? normalized(v); }

function isoWeek(date: string): string {
  const d = new Date(date.slice(0, 10) + "T12:00:00Z");
  const offset = (d.getUTCDay() + 6) % 7;
  d.setUTCDate(d.getUTCDate() - offset + 3);
  const year = d.getUTCFullYear(), first = new Date(Date.UTC(year, 0, 4, 12));
  const weeks = Math.floor((d.getTime() - first.getTime()) / 604800000) + 1;
  return year + "-W" + String(weeks).padStart(2, "0");
}
function scoreSessions(rows: Session[]) {
  const weeks: Record<string, { sessions: number; working_sets: number; volume_kg: number; muscle_sets: Record<string,number> }> = {};
  const exercises: Record<string, { name: string; sessions: number; working_sets: number; max_kg: number; estimated_1rm_kg: number|null }> = {};
  let total = 0, withRir = 0, withCatalog = 0, totalExercises = 0, unclassified = 0, unweighted = 0;
  for (const row of rows) {
    if (!row.finished_at) continue;
    const bucket = weeks[isoWeek(row.finished_at)] ??= { sessions: 0, working_sets: 0, volume_kg: 0, muscle_sets: {} };
    bucket.sessions++;
    for (const e of row.exercises ?? []) {
      totalExercises++;
      if (e.exercise?.catalogId) withCatalog++;
      const id = e.exercise?.catalogId || "free:" + normalized(e.exercise?.name || "unknown");
      const perf = exercises[id] ??= { name: e.exercise?.name || "Ejercicio sin identificar",
        sessions: 0, working_sets: 0, max_kg: 0, estimated_1rm_kg: null };
      perf.sessions++;
      const muscle = new Map<string,number>();
      for (const m of e.exercise?.primaryRegions ?? []) muscle.set(m, 1);
      if (e.exercise?.targetMuscle) muscle.set(e.exercise.targetMuscle, 1);
      (e.exercise?.secondaryRegions ?? e.exercise?.secondaryMuscles ?? []).forEach((m,i) => {
        if (!muscle.has(m)) muscle.set(m, i===0?0.55:0.35);
      });
      if (!muscle.size) unclassified++;
      for (const set of e.loggedSets ?? []) {
        total++;
        if (set.rir != null) withRir++;
        if (set.phase === "warmup" || !(set.reps && set.reps > 0)) continue;
        // A logged kcal, meters or timed cardio interval is NOT a kg-based set.
        if (set.quantityUnit === "calories" || set.quantityUnit === "meters"
          || (set.durationSeconds && set.weightKg == null)) {
          unweighted++; continue;
        }
        perf.working_sets++;
        bucket.working_sets++;
        if (set.weightKg != null && Number.isFinite(set.weightKg) && set.weightKg >= 0) {
          const vol = set.reps * set.weightKg;
          bucket.volume_kg += vol;
          perf.max_kg = Math.max(perf.max_kg, set.weightKg);
          if (set.reps <= 12 && set.weightKg > 0) {
            perf.estimated_1rm_kg = Math.max(perf.estimated_1rm_kg ?? 0,
              set.weightKg * (1 + set.reps / 30));
          }
        }
        for (const [m, w] of muscle) bucket.muscle_sets[m] = (bucket.muscle_sets[m] ?? 0) + w;
      }
    }
  }
  const sortedWeeks = Object.entries(weeks).sort(([a],[b])=>a.localeCompare(b));
  return {
    workout_count: rows.length,
    recorded_sets: total, working_strength_sets: Object.values(weeks).reduce((x,w)=>x+w.working_sets,0),
    cardio_or_nonweight_sets: unweighted,
    data_quality: { catalog_mapped_exercises: withCatalog, exercise_entries: totalExercises,
      with_rir_sets: withRir, total_sets: total, unclassified_exercise_entries: unclassified },
    weekly: sortedWeeks.map(([week, data])=>({ week, ...data, volume_kg: Math.round(data.volume_kg) })),
    exercise_progress: Object.entries(exercises).map(([id,v])=>({ catalog_key: id.startsWith("free:") ? null : id, ...v }))
      .sort((a,b)=>b.working_sets-a.working_sets).slice(0,100),
    caveats: [
      "RIR and catalog mapping coverage are reported rather than guessed.",
      "Weighted muscular sets are estimated volume, NOT measured fatigue or readiness.",
      "One-rep max uses Epley only for loaded sets of 1–12 reps and is not a tested max.",
      "Unlogged workouts and cardio may be missing; do not infer physiological recovery.",
    ],
  };
}

export function registerCoachTools(
  server: McpServer, db: SupabaseClient, ownerId: string, tokenId: string,
  canWrite = true,
) {
  async function history(days: number): Promise<Session[]> {
    const after = new Date(Date.now()-days*86400000).toISOString();
    const { data, error } = await db.from("athlete_workouts")
      .select("id,finished_at,exercises").eq("owner_id", ownerId)
      .gte("finished_at", after).order("finished_at", {ascending:false}).limit(3000);
    if (error) throw new Error("No se pudo consultar el historial deportivo");
    return data as Session[] ?? [];
  }
  server.registerTool("get_training_profile", {
    description: "Infer only observed training habits from the saved workout history. Return missing goals, material availability and duration as questions for conversation; do not assume equipment is available because it was used before.",
    inputSchema: z.strictObject({}), annotations:{readOnlyHint:true},
  }, async () => {
    const {data,error}=await db.from("athlete_training_profiles").select(
      "primary_goal,experience_level,training_days_per_week,preferred_weekdays,session_minutes,equipment,preferences,coaching_enabled,updated_at"
    ).eq("owner_id",ownerId).maybeSingle();
    if(error) throw new Error("Error al leer las preferencias deportivas");
    const recent = await history(90);
    const days = new Set(recent.map(r => (r.finished_at || "").slice(0,10)).filter(Boolean));
    const weeks = new Set(recent.map(r => isoWeek(r.finished_at || "")).filter(Boolean));
    const names = new Map<string,number>();
    for (const row of recent) for (const entry of row.exercises ?? []) {
      const name = entry.exercise?.name?.trim();
      if (name) names.set(name,(names.get(name) ?? 0)+1);
    }
    const frequentlyUsed = [...names.entries()].sort((a,b)=>b[1]-a[1]).slice(0,15)
      .map(([name, entries]) => ({name, entries}));
    const missingQuestions = [];
    if (!data || data.primary_goal === "general") missingQuestions.push("¿Qué objetivo quieres priorizar ahora?");
    if (!data?.training_days_per_week) missingQuestions.push("¿Cuántos días a la semana quieres entrenar, y cuáles tienes libres?");
    if (!data?.session_minutes) missingQuestions.push("¿De cuánto tiempo dispones por sesión?");
    if (!data?.equipment?.length) missingQuestions.push("¿Con qué material cuentas para tus próximos entrenamientos: barra, mancuernas, gomas, anillas, máquinas o solo peso corporal?");
    return result({
      explicit_preferences: data ?? null,
      observed_from_history: {
        window_days:90, completed_workouts:recent.length,
        distinct_training_days:days.size, active_weeks:weeks.size,
        average_sessions_per_active_week: weeks.size ? Number((recent.length/weeks.size).toFixed(2)) : null,
        frequently_logged_movements:frequentlyUsed,
      },
      questions_to_ask_before_building_a_program:missingQuestions,
      reliability:recent.length<6?"insufficient_history_for_stable_habits":"observational_only",
      caveat:"Observed frequency is not available training time. Observed equipment is not a declaration of what is available. Never infer injury status, preferences, commitment or physiology from workouts.",
    });
  });
  if (canWrite) {
  server.registerTool("set_training_preferences", {
    description: "Save sporting goals and available gear explicitly confirmed in conversation by the athlete. Ask first; never save guessed availability, health details or injuries.",
    inputSchema: z.strictObject({
      confirmedByAthlete: z.literal(true),
      primaryGoal: z.enum(["general","strength","hypertrophy","endurance","crossfit","weightlifting","mobility"]),
      trainingDaysPerWeek: z.number().int().min(1).max(7).optional(),
      preferredWeekdays: z.array(z.number().int().min(1).max(7)).max(7).optional(),
      sessionMinutes: z.number().int().min(15).max(240).optional(),
      availableEquipment: z.array(z.string().trim().min(2).max(60)).max(20).optional(),
    }),
    annotations:{readOnlyHint:false,destructiveHint:false},
  },async ({primaryGoal,trainingDaysPerWeek,preferredWeekdays,sessionMinutes,availableEquipment})=>{
    const {data:old,error:readError}=await db.from("athlete_training_profiles")
      .select("primary_goal,experience_level,training_days_per_week,preferred_weekdays,session_minutes,equipment,preferences")
      .eq("owner_id",ownerId).maybeSingle();
    if(readError)throw new Error("No se pudieron consultar las preferencias existentes");
    // An upsert updates all columns, so preserve previously confirmed fields
    // instead of silently resetting availability when the athlete edits a goal.
    const patch: Record<string,unknown> = {
      owner_id:ownerId,primary_goal:primaryGoal,
      experience_level:old?.experience_level??"unspecified",
      training_days_per_week:trainingDaysPerWeek??old?.training_days_per_week??null,
      preferred_weekdays:preferredWeekdays!=null?[...new Set(preferredWeekdays)].sort():old?.preferred_weekdays??[],
      session_minutes:sessionMinutes??old?.session_minutes??null,
      equipment:availableEquipment!=null?[...new Set(availableEquipment.map(canonicalGear))]:old?.equipment??[],
      preferences:old?.preferences??{},coaching_enabled:true,updated_at:new Date().toISOString(),
    };
    const {data,error}=await db.from("athlete_training_profiles").upsert(patch,{onConflict:"owner_id"})
      .select("primary_goal,training_days_per_week,preferred_weekdays,session_minutes,equipment,updated_at").single();
    if(error) throw new Error("No se pudieron guardar las preferencias confirmadas");
    return result({saved:data,source:"explicit_chat_confirmation"});
  });
  }
  server.registerTool("get_training_calendar", {
    description: "Read a current local-first snapshot of personal scheduled and recurring workouts, plus AI proposals; check freshness and never overwrite occupied days.",
    inputSchema: z.strictObject({days:z.number().int().min(7).max(180).default(90)}),
    annotations:{readOnlyHint:true},
  }, async ({days})=>{
    const [snapshot, ai]=await Promise.all([
      db.from("athlete_training_calendar_snapshots").select("items,horizon_start,horizon_end,time_zone,updated_at")
        .eq("owner_id",ownerId).maybeSingle(),
      db.from("ai_training_plans").select("id,title,scheduled_date,scheduled_time_minutes,status,program_id")
        .eq("owner_id",ownerId).gte("scheduled_date",new Date().toISOString().slice(0,10))
        .order("scheduled_date").limit(300),
    ]);
    if(snapshot.error||ai.error) throw new Error("No se pudo leer el calendario deportivo");
    return result({
      local_calendar: snapshot.data ?? null, ai_proposals: ai.data ?? [],
      requested_days: days,
      snapshot_stale: !snapshot.data || Date.now()-Date.parse(snapshot.data.updated_at)>86400000,
      coverage_warning: "Personal snapshot includes dated and weekday-recurring routines; professional sessions may not be included until synchronized. Never assume empty means free.",
    });
  });
  server.registerTool("get_training_analysis",{
    description:"Reliable historical weekly volume, exercise progression and missing-data coverage. No Apple Health, location or medical readiness.",
    inputSchema:z.strictObject({days:z.number().int().min(7).max(365).default(90)}),
    annotations:{readOnlyHint:true},
  },async({days})=>result({days,...scoreSessions(await history(days))}));
  server.registerTool("get_exercise_performance",{
    description:"Exercise-specific progression by stable catalog key (preferred) or normalized name; includes Epley estimate and RIR coverage.",
    inputSchema:z.strictObject({catalogKey:z.string().min(3).max(160).optional(),
      name:z.string().min(2).max(120).optional(),days:z.number().int().min(7).max(365).default(180)})
      .refine(v=>(v.catalogKey!=null)!==(v.name!=null),{
        message:"Use exactly one of catalogKey or name, never both",path:["catalogKey"],
      }),
    annotations:{readOnlyHint:true},
  },async({catalogKey,name,days})=>{
    const key=normalized(name||"");
    let nativeId: string|null = null;
    let officialName = "";
    if (catalogKey) {
      const {data:byKey}=await db.from("training_exercise_metadata")
        .select("native_catalog_id").eq("catalog_key",catalogKey).maybeSingle();
      nativeId=byKey?.native_catalog_id??null;
      const {data:label}=await db.from("business_exercise_catalog")
        .select("name").eq("catalog_key",catalogKey).maybeSingle();
      officialName=normalized(label?.name??"");
    }
    const out=(await history(days)).flatMap(row=>(row.exercises??[])
      .filter(e=>catalogKey ? (
        e.exercise?.catalogId===catalogKey
        || (nativeId!=null && e.exercise?.catalogId===nativeId)
        || (officialName.length>0 && normalized(e.exercise?.name||"")===officialName)
      ) : normalized(e.exercise?.name||"")===key)
      .map(e=>({date:row.finished_at,exercise:e.exercise?.name,catalog_key:e.exercise?.catalogId||null,
        sets:(e.loggedSets??[]).filter(s=>s.phase!=="warmup").map(s=>({
          reps:s.reps??null,quantity:s.reps??null,kg:s.weightKg??null,rir:s.rir??null,
          unit:s.quantityUnit??null,duration_seconds:s.durationSeconds??null,
          epley_1rm_kg:s.weightKg!=null&&(s.quantityUnit==null||s.quantityUnit==="reps")
            &&s.reps!=null&&s.reps>=1&&s.reps<=12
            ? Math.round(s.weightKg*(1+s.reps/30)*10)/10:null,
        }))})));
    const logged=out.flatMap(e=>e.sets);
    const best=(unit:string)=>{const values=logged.filter(s=>s.unit===unit)
      .map(s=>s.quantity).filter((n):n is number=>typeof n==="number"&&n>0);
      return values.length?Math.max(...values):null;};
    return result({exercise_matches:out.length,history:out,
      cardio_records:{max_meters:best("meters"),max_calories:best("calories")},
      unit_notes:"Meters, calories and repetitions are distinct. Missing quantityUnit is unknown rather than assumed repetitions.",
      warning:"1RM is a weight-only estimate, not a tested 1RM. Match using catalogKey when available."});
  });
  server.registerTool("get_exercise_alternatives", {
    description:"Look up VERIFIED substitutions, metadata and ES/EN aliases. Return an empty list when metadata is not known; never hallucinate substitutions.",
    inputSchema:z.strictObject({catalogKey:z.string().min(3).max(160)}),
    annotations:{readOnlyHint:true},
  }, async({catalogKey})=>{
    const {data,error}=await db.from("training_exercise_metadata")
      .select("catalog_key,native_catalog_id,metadata_source,aliases,primary_muscles,secondary_muscles,equipment,required_equipment,joint_demands,movement_pattern,skill_level,alternatives")
      .eq("catalog_key",catalogKey).maybeSingle();
    if(error) throw new Error("No se pudo leer metadatos del ejercicio");
    return result(data??{catalog_key:catalogKey,alternatives:[],warning:"No hay equivalencias validadas"});
  });
  server.registerTool("find_equipment_alternatives", {
    description:"Find candidates matching the main muscle groups AND confirmed available equipment. Joint demand hints are non-clinical and do not certify safety or exercise equivalence. Ask the user about available gear first.",
    inputSchema:z.strictObject({
      catalogKey:z.string().min(3).max(160),
      availableEquipment:z.array(z.string().min(2).max(80)).max(25),
      avoidJointDemands:z.array(z.enum(["shoulder","elbow","wrist","hip","knee","ankle","spine"])).max(7).default([]),
      limit:z.number().int().min(1).max(15).default(8),
    }),annotations:{readOnlyHint:true},
  },async ({catalogKey,availableEquipment,avoidJointDemands,limit})=>{
    const {data:origin,error:originError}=await db.from("training_exercise_metadata")
      .select("catalog_key,primary_muscles,required_equipment,joint_demands,movement_pattern")
      .eq("catalog_key",catalogKey).maybeSingle();
    if(originError||!origin) throw new Error("No se encontró el ejercicio solicitado");
    if(!origin.primary_muscles?.length)
      return result({candidates:[],reason:"El ejercicio carece de músculo principal de fuerza; no se infiere equivalencia de cardio."});
    const {data:meta,error:metaError}=await db.from("training_exercise_metadata")
      .select("catalog_key,primary_muscles,secondary_muscles,required_equipment,joint_demands,metadata_source,movement_pattern")
      .limit(1500);
    const {data:names,error:namesError}=await db.from("business_exercise_catalog")
      .select("catalog_key,name,category").limit(1500);
    if(metaError||namesError)throw new Error("No se pudieron consultar alternativas");
    const gear=new Set(availableEquipment.map(canonicalGear));
    const labels=new Map((names??[]).map(x=>[x.catalog_key,x]));
    const candidates=(meta??[]).filter(x=>{
      if(x.catalog_key===catalogKey || !x.primary_muscles?.length) return false;
      if(!x.required_equipment?.length || x.required_equipment.includes("gym_machine_unspecified")) return false;
      if(!x.required_equipment.every((g:string)=>g==="bodyweight" || gear.has(normalized(g))))return false;
      if(avoidJointDemands.length) {
        // Unknown joint demands are explicitly excluded when requested.
        if(!x.joint_demands?.length) return false;
        if(x.joint_demands.some((j:string)=>avoidJointDemands.includes(j as typeof avoidJointDemands[number]))) return false;
      }
      return x.primary_muscles.some((m:string)=>origin.primary_muscles.includes(m));
    }).map(x=>({
      catalog_key:x.catalog_key,
      name:labels.get(x.catalog_key)?.name??x.catalog_key,
      required_equipment:x.required_equipment,
      joint_demands:x.joint_demands,
      metadata_source:x.metadata_source,
      shared_primary_muscles:x.primary_muscles.filter((m:string)=>origin.primary_muscles.includes(m)),
      is_verified_equivalent:false,
    })).sort((a,b)=>b.shared_primary_muscles.length-a.shared_primary_muscles.length || a.name.localeCompare(b.name));
    return result({candidates:candidates.slice(0,limit),total_candidates:candidates.length,
      caution:"Candidates share muscle regions and available equipment, not proven interchangeable mechanics. Joint tags are incomplete, not a safety screening; ask the athlete about pain/limitations and seek qualified advice if needed."});
  });
  server.registerTool("search_training_exercises_enriched",{
    description:"Find stable exercise IDs, localized alias matches and verified movement metadata in Repera's full exercise catalog.",
    inputSchema:z.strictObject({query:z.string().trim().min(2).max(100),limit:z.number().int().min(1).max(50).default(20)}),
    annotations:{readOnlyHint:true},
  },async({query,limit})=>{
    const raw=query.replace(/[%_\\]/g," ").trim(); const term=normalized(raw);
    const {data:all,error}=await db.from("business_exercise_catalog")
      .select("catalog_key,name,category").limit(1500);
    if(error) throw new Error("Catálogo no disponible");
    const {data:metadata,error:metaError}=await db.from("training_exercise_metadata")
      .select("catalog_key,native_catalog_id,metadata_source,aliases,primary_muscles,secondary_muscles,equipment,required_equipment,joint_demands,movement_pattern,skill_level,alternatives").limit(1500);
    if(metaError) throw new Error("Metadatos de catálogo no disponibles");
    const index=new Map((metadata??[]).map(m=>[m.catalog_key,m]));
    const hyroxKeys = new Set(["catalog:Carrera","catalog:SkiErg","catalog:Sled push",
      "catalog:Sled pull","catalog:Burpee Broad Jump","catalog:Remo máquina",
      "catalog:Farmer carry","catalog:Sandbag Lunges","catalog:Wall ball"]);
    const matches=(all??[]).filter(e=>(term==="hyrox" && hyroxKeys.has(e.catalog_key))
      || normalized(e.name).includes(term)
      || (index.get(e.catalog_key)?.aliases??[]).some(a=>normalized(a).includes(term)));
    return result({results:matches.slice(0,limit).map(e=>({...e,metadata:index.get(e.catalog_key)??null})),
      total_matches:matches.length,note:"Missing metadata is explicit; no inferred muscle assignment."});
  });
  server.registerTool("get_training_programs",{
    description:"List saved macrocycles, revision and phases. Programs are proposals; local exercise sessions are authoritative.",
    inputSchema:z.strictObject({
      limit:z.number().int().min(1).max(50).default(20),
      cursor:z.string().regex(/^[A-Za-z0-9_-]{1,64}$/).optional(),
    }),
    annotations:{readOnlyHint:true},
  },async({limit,cursor})=>{
    let offset=0;
    if(cursor) {
      try {
        const encoded=atob(cursor);
        if(!/^[0-9]+$/.test(encoded))throw Error("bad");
        offset=Number(encoded);
        if(!Number.isSafeInteger(offset)||offset<0||offset>100000)throw Error("bad");
      }catch{throw Error("INVALID_CURSOR: paginación no válida");}
    }
    const {data,error}=await db.from("athlete_training_programs")
      .select("id,title,primary_goal,start_date,start_time_zone,duration_weeks,phases,status,revision,updated_at")
      .eq("owner_id",ownerId).order("created_at",{ascending:false}).order("id",{ascending:true})
      .range(offset,offset+limit);
    if(error) throw new Error("No se pudieron leer los programas");
    const rows=data??[],hasMore=rows.length>limit;
    const nextCursor=hasMore?btoa(String(offset+limit)).replace(/=+$/,""):null;
    return result({items:rows.slice(0,limit),hasMore,nextCursor});
  });
  if (canWrite) {
  server.registerTool("create_training_program",{
    description:"Persist a 1–52 week program with validated phases. Does not overwrite calendar or schedule sessions; use create_training_plan to queue next 14 workouts explicitly.",
    inputSchema:z.strictObject({title:z.string().trim().min(2).max(120),
      primaryGoal:z.string().trim().min(2).max(500),startDate:day,
      startTimeZone:z.string().trim().min(3).max(80),durationWeeks:weeks,
      phases:z.array(phase).min(1).max(12)}),
    annotations:{readOnlyHint:false,destructiveHint:false},
  },async({title,primaryGoal,startDate,startTimeZone,durationWeeks,phases})=>{
    try { new Intl.DateTimeFormat("en-US",{timeZone:startTimeZone}); }
    catch { throw Error("INVALID_TIME_ZONE: startTimeZone debe ser una zona IANA válida"); }
    const date=new Date(startDate+"T12:00:00Z");
    if(!Number.isFinite(+date)||date.toISOString().slice(0,10)!==startDate) throw Error("Fecha inválida");
    if(date.getTime()<Date.now()-2*86400000||date.getTime()>Date.now()+365*86400000)
      throw Error("Fecha de inicio fuera del horizonte disponible");
    if(phases.reduce((total,p)=>total+p.weeks,0)!==durationWeeks)
      throw Error("La suma de semanas de fases debe coincidir con la duración del programa");
    const {data,error}=await db.from("athlete_training_programs").insert({
      owner_id:ownerId,created_by_token_id:tokenId,title,primary_goal:primaryGoal,
      start_date:startDate,start_time_zone:startTimeZone,
      duration_weeks:durationWeeks,phases,status:"proposed",
    }).select("id,title,status,revision,phases").single();
    if(error) throw new Error("No se pudo guardar el programa");
    return result({program:data,delivery:"Macroprograma guardado. Para recibir sesiones concretas en Repera, envía un máximo de 14 cada vez con create_training_plan y programId."});
  });
  }
  server.registerTool("review_training_program",{
    description:"Review completion, gaps and weekly trends for a program, without inferring recovery, readiness or success from unlogged sessions.",
    inputSchema:z.strictObject({programId:z.string().uuid()}),annotations:{readOnlyHint:true},
  },async({programId})=>{
    const {data:program,error}=await db.from("athlete_training_programs").select(
      "id,title,start_date,start_time_zone,duration_weeks,phases,primary_goal,status,revision"
    ).eq("owner_id",ownerId).eq("id",programId).maybeSingle();
    if(error||!program) throw new Error("Programa no encontrado");
    const start=program.start_date;const end=new Date(Date.parse(start+"T12:00:00Z")+program.duration_weeks*7*86400000).toISOString().slice(0,10);
    const [plans,done]=await Promise.all([
      db.from("ai_training_plans").select("id,scheduled_date,status").eq("owner_id",ownerId)
        .eq("program_id",programId).limit(1000),
      db.from("athlete_workouts").select("id,finished_at").eq("owner_id",ownerId)
        .gte("finished_at",start+"T00:00:00Z").lte("finished_at",end+"T23:59:59Z").limit(1500),
    ]);
    if(plans.error||done.error)throw new Error("No se pudo comparar la planificación");
    const plannedDays=new Set((plans.data??[]).map(x=>x.scheduled_date));
    const completedDays=new Set((done.data??[]).map(x=>x.finished_at?.slice(0,10)).filter(Boolean));
    const matching=[...plannedDays].filter(x=>completedDays.has(x)).length;
    return result({program,planned_sessions:plans.data?.length??0,applied_proposals:plans.data?.filter(x=>x.status==="applied").length??0,
      recorded_sessions:done.data?.length??0,planned_days_with_recorded_workouts:matching,
      adherence_proxy:plannedDays.size?Math.round(matching/plannedDays.size*100):null,
      limitations:"Same-day completion is a proxy, not proven linkage. Workouts outside Repera or unlogged are unknown. Review goals before adapting future sessions."});
  });
  if (canWrite) {
  server.registerTool("adjust_training_program",{
    description:"Explicit user-requested revision of a stored program's future phases; optimistic revision check. Does not modify completed workouts or already queued daily sessions.",
    inputSchema:z.strictObject({programId:z.string().uuid(),expectedRevision:z.number().int().min(1),
      phases:z.array(phase).min(1).max(12),reason:z.string().trim().min(3).max(500)}),
    annotations:{readOnlyHint:false,destructiveHint:false},
  },async({programId,expectedRevision,phases,reason})=>{
    const {data:original,error:readError}=await db.from("athlete_training_programs")
      .select("duration_weeks,status").eq("id",programId).eq("owner_id",ownerId).maybeSingle();
    if(readError||!original)throw Error("Programa no encontrado");
    if(["completed","cancelled"].includes(original.status))throw Error("No se puede ajustar un programa cerrado");
    if(phases.reduce((n,p)=>n+p.weeks,0)!==original.duration_weeks)throw Error("Duración y fases no coinciden");
    const {data,error}=await db.from("athlete_training_programs").update({
      phases, revision:expectedRevision+1,updated_at:new Date().toISOString(),
    }).eq("owner_id",ownerId).eq("id",programId).eq("revision",expectedRevision)
      .select("id,revision,status,phases").maybeSingle();
    if(error||!data)throw Error("Revisión obsoleta o fallo de actualización: recarga el programa antes de reintentar");
    return result({program:data,reason,notice:"No se han reescrito sesiones existentes; crea nuevas propuestas fechadas explícitamente."});
  });  }

}
