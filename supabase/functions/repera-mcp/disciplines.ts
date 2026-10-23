import { z } from "npm:zod@4.3.6";
import type { McpServer } from "npm:@modelcontextprotocol/server@2.0.0";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2.58.0";

/**
 * Planificador por disciplinas. Las referencias son reglas de prescripción, NO datos
 * personales ni equivalencias médicas. Las entradas reales salen del catálogo SQL.
 * Nunca se crea un UUID de catálogo ficticio ni se estima un PR desde cardio/movilidad.
 */
const discipline = z.enum(["crossfit", "weightlifting", "mobility", "warmup"]);
type Discipline = z.infer<typeof discipline>;
type Entry = {
  exercise?: { name?: string; catalogId?: string };
  loggedSets?: Array<{
    reps?: number; weightKg?: number; durationSeconds?: number;
    quantityUnit?: string; phase?: string; rir?: number;
  }>;
};
type Session = {
  id: string; title: string; started_at?: string | null; finished_at?: string | null;
  exercises?: Entry[]; wod_results?: unknown[];
};
const reply = (data: unknown) => ({
  content: [{ type: "text" as const, text: JSON.stringify(data) }],
});
const round = (value: number) => Math.round(value * 10) / 10;
const folded = (value: string) => value.normalize("NFD")
  .replace(/[\u0300-\u036f]/g, "").trim().toLowerCase();
const DATE_MS = 86_400_000;

/** Selection criteria; not mandatory one-size-fits-all session templates. */
export const disciplineGuides = {
  crossfit: {
    label: "CrossFit",
    official_identity: "Gimnasia, levantamientos y acondicionamiento en formatos variados; no confundir técnica con velocidad.",
    compatible_formats: ["strength", "amrap", "emom", "forTime", "tabata", "chipper",
      "roundsForQuality", "circuit", "partner", "ladder"],
    construction: [
      "Calentamiento general progresivo y movilidad/activación específicas de los patrones del WOD",
      "Bloque técnico o de fuerza cuando sea necesario, con repeticiones, descansos y RIR adecuados",
      "Metcon con objetivo explícito: técnica, aeróbico sostenido, intervalos o intensidad competitiva",
      "Escalado independiente de la carga, habilidad, volumen o complejidad manteniendo el estímulo",
    ],
    programming: [
      "Alternar los patrones dominantes (sentadilla, bisagra, tirón, empuje, tronco, carrera/ergómetros) y evitar sobrecarga repetida sin recuperación observada",
      "Priorizar competencia técnica antes de kipping, levantamientos complejos o movimientos fatigados",
      "Definir timeCapMinutes en AMRAP; en For Time usar tiempo transcurrido real; en EMOM/Tabata registrar por intervalo y movimiento",
      "Revisar semanas previas, volumen por patrón, exposición reciente, marcas comparables y preferencias explícitas antes de fijar dificultad",
      "No comparar WODs Rx con scaled ni scores de WOD distintos como si fueran récords equivalentes",
    ],
    measures: ["repeticiones", "rondas completas + reps parciales en AMRAP", "tiempo en For Time",
      "RIR/peso/e1RM estimado solo para fuerza", "metros/calorías separados", "frecuencia y volumen observados"],
    needs: ["nivel y movimientos dominados", "días y minutos disponibles", "material confirmado",
      "preferencia fuerza/metcon/técnica", "limitaciones y tolerancia expresadas por la persona"],
  },
  weightlifting: {
    label: "Halterofilia",
    official_identity: "Arrancada, dos tiempos, tirones, recepciones, variantes y fuerza complementaria.",
    compatible_formats: ["strength", "roundsForQuality", "emom"],
    construction: [
      "Preparación de tobillo, cadera, columna torácica, hombro y muñeca según movilidad real",
      "Técnica de barra ligera o pica y posiciones antes de cargas progresivas",
      "Levantamiento principal con repeticiones bajas y descansos suficientes",
      "Variaciones de recepción, tirón y sentadilla solo si son pertinentes para el nivel",
      "Accesorios y recuperación de la sesión ajustados al trabajo reciente",
    ],
    programming: [
      "Identificar nivel de dominio de snatch/clean/jerk y contexto de supervisión técnica",
      "Usar %1RM únicamente cuando exista máximo de referencia verificado para ESE levantamiento; un e1RM por Epley no sustituye un 1RM técnico",
      "Si no hay 1RM probado, prescribir técnica por RIR/esfuerzo declarado y carga conservadora, sin asumir porcentajes",
      "Organizar progresión y descarga de acuerdo con respuesta observada, días disponibles y competición objetivo",
      "Evitar altas intensidades técnicas bajo fatiga marcada o dolor; priorizar control de la recepción y trayectoria",
    ],
    measures: ["carga y repeticiones por variante", "RIR cuando aplica", "consistencia técnica reportada",
      "frecuencia de exposición", "volumen levantado verificado", "1RM comprobado por variante si el usuario lo facilita"],
    needs: ["experiencia técnica y levantamientos que domina", "máximos comprobados o su ausencia",
      "acceso a barra y discos", "frecuencia disponible", "objetivo técnico o competición"],
  },
  mobility: {
    label: "Movilidad",
    official_identity: "Rango activo, control articular, exploración gradual y estiramientos; no equivale a series de fuerza ni a rehabilitación.",
    compatible_formats: ["roundsForQuality", "circuit"],
    construction: [
      "Seleccionar regiones y posiciones relevantes para el objetivo (tobillo, cadera, dorsal, hombro, muñeca...)",
      "Distinguir movilidad dinámica/repeticiones de posiciones sostenidas/segundos por lado",
      "Utilizar progresión suave de control, consistencia, frecuencia y tolerancia, nunca forzar rango doloroso",
      "Evitar asignar fatiga muscular, tonelaje o e1RM a estas sesiones",
    ],
    programming: [
      "Usar entradas verificadas de la categoría Movilidad (82 movimientos propuestos en la rama nativa de movilidad), sin fabricar nombres",
      "Antes de una sesión intensa, priorizar movilidad activa y progresiva; las posiciones sostenidas extensas se reservan según contexto",
      "El MCP actual no transporta targetDurationSeconds por movimiento hasta el importador nativo: los segundos por lado van en wodNotes o se usan circuit.workSeconds uniforme cuando corresponde",
      "No convertir 30 segundos en 30 repeticiones ni afirmar un rango de movimiento medido si el usuario no lo ha registrado",
    ],
    measures: ["duración real solo si consta en registros", "veces realizadas", "repeticiones dinámicas",
      "rango o sensación subjetiva solamente si se proporcionó explícitamente"],
    needs: ["objetivo de movilidad", "regiones que se desean trabajar", "tiempo y material real",
      "dolor o limitaciones declaradas sin deducir un diagnóstico"],
  },
  warmup: {
    label: "Calentamiento",
    official_identity: "Fase de preparación contextual; reutiliza movimientos del catálogo y no crea ejercicios duplicados.",
    compatible_formats: ["roundsForQuality", "circuit", "strength"],
    construction: [
      "General 2–6 min: elevación gradual de pulso según exigencia posterior y nivel",
      "Movilidad dinámica 3–6 min: articulaciones y patrones concretos del bloque principal",
      "Activación 2–5 min: musculatura y estabilidad necesarias, sin fatiga significativa",
      "Aproximaciones técnicas 3–12 min según carga y complejidad; siempre aumentar gradualmente",
    ],
    programming: [
      "Para arranque y envión: priorizar tobillo, cadera, tórax, hombro, muñeca y barra ligera antes de las series principales",
      "Para WOD con dominadas: adaptar escápulas, agarre, hombros y tracción sin agotar el patrón",
      "Para carrera/HYROX: trote progresivo, tobillo/cadera dinámicos y ensayos específicos de las estaciones",
      "Para movilidad suave autónoma: puede bastar preparación breve; no imponer el mismo protocolo completo",
      "No contar calentamiento como récord, trabajo principal ni mejora de e1RM. El payload actual no distingue sets 'warmup': añadir nota explícita y evitar inventar métricas",
    ],
    measures: ["minutos de preparación prescritos", "movimientos/variaciones realizados", "sensación informada"],
    needs: ["sesión principal y patrones", "equipamiento disponible", "duración y nivel", "necesidad de preparación individual"],
  },
} as const;

const catalogCategories: Record<Discipline, string[] | null> = {
  // CrossFit draws from gymnastics, barbell and conventional strength without relabelling them.
  crossfit: ["CrossFit", "Gimnasia", "Halterofilia", "Fuerza"],
  weightlifting: ["Halterofilia", "Fuerza"],
  mobility: ["Movilidad"], warmup: null,
};
const warmupIdeas: Record<string, string[]> = {
  "weightlifting": ["CARs de hombro", "90/90 de cadera", "Rodilla a pared para tobillo",
    "Rotación torácica en cuadrupedia", "Pasadas de hombros con pica", "Buenos días con pica"],
  "crossfit": ["World's Greatest Stretch", "Inchworm", "Gato-vaca",
    "Círculos de hombros", "90/90 de cadera", "Sentadilla profunda con balanceo"],
  "hyrox": ["Rodilla a pared para tobillo", "CARs de cadera", "Estiramiento dinámico de isquios",
    "Zancada Spiderman con rotación", "Círculos de hombros", "Inchworm"],
  "strength": ["Gato-vaca", "90/90 de cadera", "Bisagra de cadera sin carga",
    "CARs de hombro", "Rodilla a pared para tobillo"],
  "mobility": ["Círculos de hombros", "Círculos de tobillo",
    "CARs de cadera", "Rotación torácica en cuadrupedia"],
};

const warmupMovementFocus = [
  {tokens:["snatch","arrancada","jerk","envion","cargada","clean","press","overhead"],
    focus:"sobre-cabeza y recepción",
    exercises:["CARs de hombro","Pasadas de hombros con pica","Rotación torácica en cuadrupedia","Movilidad de muñeca en extensión"]},
  {tokens:["sentadilla","squat","thruster","lunge","zancada"],
    focus:"sentadilla y pierna",
    exercises:["Rodilla a pared para tobillo","90/90 de cadera","Sentadilla profunda con balanceo","Estiramiento del flexor de cadera"]},
  {tokens:["pull-up","pull up","dominada","muscle-up","muscle up","ring","anilla","rope","cuerda"],
    focus:"tracción y hombro",
    exercises:["Círculos de hombros","Protracción y retracción escapular","Colgado activo","Rotación externa de hombro con banda"]},
  {tokens:["correr","carrera","run","sprint","sled","trineo","farmer","ski","remo maquina","row"],
    focus:"locomoción y tracción",
    exercises:["Rodilla a pared para tobillo","CARs de cadera","Estiramiento dinámico de isquios","Zancada Spiderman con rotación"]},
] as const;
const gearAliases:Record<string,string> = {
  "bodyweight":"bodyweight","peso corporal":"bodyweight","sin material":"bodyweight",
  "bandas":"resistance_band","gomas":"resistance_band","banda elastica":"resistance_band",
  "resistance_band":"resistance_band","pica":"pvc_pipe","pvc":"pvc_pipe",
  "pvc_pipe":"pvc_pipe","pared":"wall","wall":"wall",
  "barra de dominadas":"pullup_bar","pullup_bar":"pullup_bar",
  "banco":"bench","bench":"bench","rodillo":"foam_roller","foam roller":"foam_roller",
  "foam_roller":"foam_roller","marco de puerta":"door_frame","door_frame":"door_frame",
};
function equipmentStatus(requirements:string[],available?:string[]) {
  const needs=requirements.filter(x=>x!=="bodyweight");
  if(!needs.length)return "sin_material";
  if(available==null)return "pendiente_confirmacion";
  const declared=new Set(available.map(x=>gearAliases[folded(x)]??folded(x)));
  return needs.every(x=>declared.has(x))?"disponible_declarado":"no_declarado";
}

function periodTotals(rows: Session[], since: number, until: number) {
  let workouts=0, workSets=0, strengthSets=0, volumeKg=0;
  let meters=0, calories=0, measuredSeconds=0, unknownUnitSets=0;
  let rirSum=0,rirSamples=0;
  const days=new Set<string>();
  for(const row of rows) {
    const at=Date.parse(row.finished_at??"");
    if(!Number.isFinite(at)||at<since||at>=until)continue;
    workouts++;days.add((row.finished_at??"").slice(0,10));
    for(const e of row.exercises??[])for(const set of e.loggedSets??[]) {
      if(set.phase==="warmup" || !((set.reps??0)>0 || (set.durationSeconds??0)>0))continue;
      workSets++;
      if(set.rir!=null&&Number.isFinite(set.rir)&&set.rir>=0&&set.rir<=10){
        rirSum+=set.rir;rirSamples++;
      }
      const n=Math.max(0,set.reps??0);
      if(set.durationSeconds!=null&&set.durationSeconds>0)measuredSeconds+=set.durationSeconds;
      switch(set.quantityUnit){
        case "meters":meters+=n;break;
        case "calories":calories+=n;break;
        case "reps":
        case undefined:
        case null:
          if(set.quantityUnit==null)unknownUnitSets++;
          if(set.weightKg!=null && Number.isFinite(set.weightKg) && set.weightKg>0) {
            strengthSets++;
            if(set.quantityUnit==="reps")volumeKg+=n*set.weightKg;
          }
          break;
      }
    }
  }
  return {workouts,distinct_recorded_days:days.size,working_sets:workSets,
    weighted_sets_with_load:strengthSets,verified_tonnage_kg:round(volumeKg),
    logged_meters:meters,logged_calories:calories,
    set_duration_seconds_total:measuredSeconds,
    recorded_rir_average:rirSamples?round(rirSum/rirSamples):null,
    sets_with_rir:rirSamples,unknown_unit_sets:unknownUnitSets};
}
function exerciseSummaries(rows: Session[], limit: number) {
  const map=new Map<string,{name:string;catalog_key:string|null;sessions:number;
    max_weight_kg:number|null;e1rm_estimated_kg:number|null;max_meters:number|null;
    max_calories:number|null;max_reps:number|null;last_recorded_at:string|null;
    unknown_unit_sets:number}>();
  for(const row of rows){
    for(const e of row.exercises??[]){
      const name=e.exercise?.name?.trim() || "Sin identificar";
      const key=e.exercise?.catalogId || "free:"+folded(name);
      let item=map.get(key);
      if(!item){item={name,catalog_key:e.exercise?.catalogId??null,sessions:0,max_weight_kg:null,
        e1rm_estimated_kg:null,max_meters:null,max_calories:null,max_reps:null,
        last_recorded_at:null,unknown_unit_sets:0};map.set(key,item);}
      item.sessions++;
      if(!item.last_recorded_at || (row.finished_at??"")>item.last_recorded_at)
        item.last_recorded_at=row.finished_at??null;
      for(const set of e.loggedSets??[]){
        if(set.phase==="warmup" || !((set.reps??0)>0))continue;
        const n=set.reps??0,unit=set.quantityUnit;
        if(unit==="meters") item.max_meters=Math.max(item.max_meters??0,n);
        else if(unit==="calories")item.max_calories=Math.max(item.max_calories??0,n);
        else if(unit==="reps"){
          item.max_reps=Math.max(item.max_reps??0,n);
          if(set.weightKg!=null&&set.weightKg>0&&Number.isFinite(set.weightKg)){
            item.max_weight_kg=Math.max(item.max_weight_kg??0,set.weightKg);
            if(n<=12)item.e1rm_estimated_kg=round(Math.max(item.e1rm_estimated_kg??0,set.weightKg*(1+n/30)));
          }
        }else item.unknown_unit_sets++;
      }
    }
  }
  return [...map.values()].sort((a,b)=>b.sessions-a.sessions||a.name.localeCompare(b.name)).slice(0,limit);
}
const errorIf = (error: {message?:string}|null,reason:string) => {if(error)throw new Error(reason);};

export function registerDisciplinePlanningTools(server:McpServer,db:SupabaseClient,ownerId:string) {
  server.registerTool("get_training_discipline_reference",{
    description:"Read discipline-specific evidence-based planning guardrails and real Repera catalog exercises for CrossFit, Halterofilia/weightlifting, Movilidad or Calentamiento. Use with get_athlete_planning_context, get_training_calendar and format contract before writing; do not invent loads, skills or available equipment.",
    inputSchema:z.strictObject({
      discipline,includeExercises:z.boolean().default(true),
      limit:z.number().int().min(5).max(350).default(250),
    }),annotations:{readOnlyHint:true},
  },async({discipline:kind,includeExercises,limit})=>{
    const guide=disciplineGuides[kind];
    let exercises:unknown[]=[];
    if(includeExercises){
      const categories=catalogCategories[kind];
      if(categories){
        const {data,error}=await db.from("business_exercise_catalog")
          .select("catalog_key,name,category,display_name_en").in("category",categories)
          .order("category").order("name").limit(limit);
        errorIf(error,"No se pudo leer el catálogo de disciplina");
        const keys=(data??[]).map(x=>x.catalog_key);
        const {data:metadata,error:metaError}=keys.length?await db.from("training_exercise_metadata")
          .select("catalog_key,aliases,required_equipment,metadata_source,movement_pattern")
          .in("catalog_key",keys):{data:[],error:null};
        errorIf(metaError,"No se pudieron leer los metadatos de disciplina");
        const map=new Map((metadata??[]).map(x=>[x.catalog_key,x]));
        exercises=(data??[]).map(x=>({...x,name:x.display_name_en??x.name,
          legacy_name:x.name,metadata:map.get(x.catalog_key)??null}));
      }else {
        // El calentamiento es una fase, no una categoría que duplique ejercicios.
        const wanted=[...new Set(Object.values(warmupIdeas).flat())];
        const {data,error}=await db.from("business_exercise_catalog")
          .select("catalog_key,name,category").in("name",wanted).order("name").limit(limit);
        errorIf(error,"No se pudo leer el catálogo para calentamientos");
        exercises=data??[];
      }
    }
    return reply({
      discipline:kind,...guide,available_exercises:exercises,
      catalog_note:kind==="warmup"
        ?"Warmup is a phase using existing catalog keys; do not create a new exercise or claim a new kind in the iOS payload."
        :"List contains existing catalog rows; original category is retained. CrossFit combines strength, gymnastics and weightlifting without changing each exercise's native discipline.",
      catalog_categories_included:catalogCategories[kind]??[],
      how_to_use:["Read get_athlete_planning_context for observed loads, record quality, and explicit profile",
        "Check get_training_calendar for conflicts", "Read get_wod_format_contract before choosing an interval or score",
        "Use catalog_key unchanged (legacy stable identity); name is the English display label, legacy_name is the original label. Adapt difficulty only with confirmed skills/equipment",
        "Create a saved program only when explicitly requested, then date workouts without overwriting existing plans"],
    });
  });

  server.registerTool("get_warmup_prescription_reference",{
    description:"Suggest verified mobility movement options and a task-specific preparation sequence for the main workout, with declared material constraints. Not a fixed warmup or medical protocol.",
    inputSchema:z.strictObject({
      mainDiscipline:z.enum(["crossfit","weightlifting","hyrox","strength","mobility"]),
      mainMovements:z.array(z.string().trim().min(2).max(120)).max(15).default([]),
      sessionMinutes:z.number().int().min(10).max(240).optional(),
      availableEquipment:z.array(z.string().trim().min(2).max(60)).max(20).optional(),
    }),annotations:{readOnlyHint:true},
  },async({mainDiscipline,mainMovements,sessionMinutes,availableEquipment})=>{
    const patterns=warmupMovementFocus.filter(p=>
      mainMovements.some(m=>p.tokens.some(token=>folded(m).includes(token))));
    const names=[...new Set([
      ...warmupIdeas[mainDiscipline].slice(0,3),
      ...patterns.flatMap(p=>p.exercises),
      ...warmupIdeas[mainDiscipline].slice(3),
    ])];
    const {data,error}=await db.from("business_exercise_catalog")
      .select("catalog_key,name,category").in("name",names);
    errorIf(error,"No se pudieron comprobar los movimientos de calentamiento");
    const keys=(data??[]).map(x=>x.catalog_key);
    const {data:metadata,error:metaError}=keys.length?await db.from("training_exercise_metadata")
      .select("catalog_key,required_equipment").in("catalog_key",keys):{data:[],error:null};
    errorIf(metaError,"No se pudo comprobar el material necesario para calentamiento");
    const meta=new Map((metadata??[]).map(x=>[x.catalog_key,x.required_equipment as string[]]));
    const available=new Map((data??[]).map(x=>[x.name,x]));
    return reply({
      purpose:"Progressively prepare the actual movement patterns and energy system, without exhausting the athlete.",
      mainDiscipline,mainMovements,sessionMinutes:sessionMinutes??null,
      detected_movement_focus:patterns.map(p=>p.focus),
      athlete_declared_equipment:availableEquipment??null,
      steps:disciplineGuides.warmup.construction,
      candidates:names.flatMap(name=>{
        const item=available.get(name);
        if(!item)return [];
        const required=meta.get(item.catalog_key)??[];
        return [{...item,required_equipment:required,
          equipment_status:equipmentStatus(required,availableEquipment)}];
      }),
      instructions:[
        "Pick only relevant movements and confirmed accessible equipment; candidate names do NOT confirm gear availability",
        "Scale preparation time to real session duration and complexity; dynamic controlled mobility precedes technical lifting",
        "If the main lift is unknown, ask rather than prescribe an exhaustive fixed warmup",
        "Do not turn time-based holds into fake repetitions: use wodNotes to communicate per-side duration until the importer supports per-set duration",
        "Do not count a warmup as a strength record; the current MCP payload cannot mark a set phase=warmup. Warn before saving a warmup as an ordinary strength set"
      ],
    });
  });

  server.registerTool("get_athlete_planning_context",{
    description:"Owner-scoped read of expressly saved training preferences, recorded 7/28-day loads, historical exercise records by real units, data quality, program/calendar occupancy. No Apple Health, sleep/HRV, GPS or inferred injuries/recovery. Consult BEFORE prescribing by discipline.",
    inputSchema:z.strictObject({
      days:z.number().int().min(28).max(180).default(90),
      topExercises:z.number().int().min(5).max(30).default(15),
    }),annotations:{readOnlyHint:true},
  },async({days,topExercises})=>{
    const now=Date.now(),start=new Date(now-days*DATE_MS).toISOString(),today=new Date(now).toISOString().slice(0,10);
    const [profile,workouts,plans,programs,calendar]=await Promise.all([
      db.from("athlete_training_profiles").select("primary_goal,experience_level,training_days_per_week,preferred_weekdays,session_minutes,equipment,coaching_enabled,updated_at")
        .eq("owner_id",ownerId).maybeSingle(),
      db.from("athlete_workouts").select("id,title,started_at,finished_at,exercises,wod_results")
        .eq("owner_id",ownerId).gte("finished_at",start).order("finished_at",{ascending:false}).limit(1000),
      db.from("ai_training_plans").select("scheduled_date,status").eq("owner_id",ownerId)
        .gte("scheduled_date",today).order("scheduled_date").limit(120),
      db.from("athlete_training_programs").select("title,primary_goal,start_date,duration_weeks,phases,status,revision")
        .eq("owner_id",ownerId).order("created_at",{ascending:false}).limit(3),
      db.from("athlete_training_calendar_snapshots").select("updated_at,horizon_start,horizon_end,time_zone")
        .eq("owner_id",ownerId).maybeSingle(),
    ]);
    errorIf(profile.error,"No se pudieron consultar preferencias deportivas");
    errorIf(workouts.error,"No se pudo consultar historial consentido");
    errorIf(plans.error,"No se pudieron consultar propuestas de calendario");
    errorIf(programs.error,"No se pudieron consultar programas");
    errorIf(calendar.error,"No se pudo leer el estado del calendario");
    const rows=(workouts.data??[]) as Session[];
    const latest=rows[0]?.finished_at??null;
    const questions:string[]=[];
    if(!profile.data?.primary_goal || profile.data.primary_goal==="general")questions.push("Objetivo, disciplina y evento/prueba concreta");
    if(!profile.data?.training_days_per_week)questions.push("Días disponibles por semana");
    if(!profile.data?.session_minutes)questions.push("Minutos reales por sesión");
    if(!profile.data?.equipment?.length)questions.push("Equipamiento disponible confirmado");
    questions.push("Nivel técnico en los ejercicios elegidos y dolor/limitaciones actuales, si los hubiera (no inferir diagnóstico)");
    return reply({
      source:"Owner-scoped Repera workout mirror and explicit training settings; no Apple Health",
      observed_window_days:days,server_as_of:new Date(now).toISOString(),
      explicit_preferences:profile.data??null,
      recent_load:{
        last_7_days:periodTotals(rows,now-7*DATE_MS,now),
        previous_7_days:periodTotals(rows,now-14*DATE_MS,now-7*DATE_MS),
        last_28_days:periodTotals(rows,now-28*DATE_MS,now),
      },
      recorded_workouts_in_window:rows.length,last_recorded_at:latest,
      recent_exercise_records:exerciseSummaries(rows,topExercises),
      wod_result_entries:rows.reduce((n,row)=>n+(row.wod_results?.length??0),0),
      recent_wod_result_samples:rows.filter(row=>(row.wod_results?.length??0)>0)
        .slice(0,12).map(row=>({finished_at:row.finished_at,
          title:row.title,stored_results:row.wod_results?.slice(0,3)??[]})),
      upcoming_ai_proposals:plans.data??[],
      latest_training_programs:programs.data??[],
      local_calendar_snapshot:calendar.data??null,
      questions_to_confirm:questions,
      data_quality:{
        mirror_row_limit:1000,possibly_truncated:rows.length===1000,
        no_automatic_health_records:true,
        note:"Unknown exercise set quantityUnit is excluded from metres/calories and load totals. 1RM is estimated only for explicitly rep-based weighted sets (1-12 reps)."
      },
      restrictions:[
        "Historical frequency is NOT the athlete's future availability or fitness readiness",
        "Logged volume does not prove physiological recovery, DOMS, injury risk, HRV or sleep quality",
        "Do not add metres and calories, assume Rx/Scaled comparable, or compare WOD times with different movements/doses",
        "Plan with explicit limits, adequate recovery options and progressive technical difficulty",
        "Respect calendar conflicts and athlete consent; ask about missing details before committing future training"
      ],
    });
  });
}
