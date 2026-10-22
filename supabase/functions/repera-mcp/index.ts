import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createMcpHandler, McpServer } from "npm:@modelcontextprotocol/server@2.0.0";
import { createClient } from "npm:@supabase/supabase-js@2.58.0";
import { z } from "npm:zod@4.3.6";
import { registerCoachTools } from "./coach.ts";
import { registerMutationTools } from "./mutations.ts";
import { workout } from "./schema.ts";
import { scheduledInstant } from "./time.ts";
import { registerAthleteChangeTools } from "./athlete-changes.ts";

// Personal access token (PAT) MCP. PAT is an opaque bearer credential,
// not an OAuth authorization code or a JWT. Always use TLS.
// Service-role key stays only inside the Edge Function; EVERY query is scoped
// to owner_id derived from the authenticated hashed token.
const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { autoRefreshToken: false, persistSession: false } },
);

type ExerciseEntry = {
  id?: string;
  exercise?: {
    name?: string; catalogId?: string; muscleGroup?: string; targetMuscle?: string;
    primaryRegions?: string[]; secondaryRegions?: string[]; secondaryMuscles?: string[];
  };
  loggedSets?: Array<{
    id?: string;
    reps?: number; weightKg?: number; rir?: number; phase?: string; kind?: string;
    durationSeconds?: number;
  }>;
};
type WorkoutRow = {
  id: string; title: string; started_at: string | null; finished_at: string | null;
  updated_at:string; exercises: ExerciseEntry[]; wod_results: unknown[];
};
function reply(data: unknown) {
  return { content: [{ type: "text" as const, text: JSON.stringify(data) }] };
}
function fail(status: number, message: string) {
  return new Response(JSON.stringify({ error: message }), {
    status, headers: { "content-type": "application/json", "cache-control": "no-store" },
  });
}
async function sha256(value: string): Promise<string> {
  const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return Array.from(new Uint8Array(bytes), b => b.toString(16).padStart(2, "0")).join("");
}
function projectExercise(entry: ExerciseEntry) {
  const ex = entry.exercise ?? {};
  return {
    exercise_entry_id:entry.id ?? null,
    name: ex.name ?? "", catalog_key: ex.catalogId ?? null,
    muscle_group: ex.muscleGroup ?? null,
    target_muscle: ex.targetMuscle ?? null,
    primary_regions: ex.primaryRegions ?? [],
    secondary_regions: ex.secondaryRegions ?? [],
    sets: (entry.loggedSets ?? []).map(s => ({
      logged_set_id:s.id ?? null,
      reps: s.reps ?? null, weight_kg: s.weightKg ?? null,
      rir: s.rir ?? null, duration_seconds: s.durationSeconds ?? null,
      phase: s.phase ?? null, kind: s.kind ?? null,
    })),
  };
}
function normalizeMuscle(value: string): string {
  return value.trim().toLowerCase();
}
function muscleBalance(rows: WorkoutRow[]) {
  const tally: Record<string, number> = {};
  let unmapped = 0, completedSets = 0;
  for (const row of rows) for (const item of row.exercises ?? []) {
    const working = (item.loggedSets ?? []).filter(s =>
      (s.reps ?? 0) > 0 && s.phase !== "warmup"
    ).length;
    completedSets += working;
    const ex = item.exercise ?? {};
    const regions = new Map<string, number>();
    for (const name of ex.primaryRegions ?? []) regions.set(normalizeMuscle(name), 1);
    if (ex.targetMuscle) regions.set(normalizeMuscle(ex.targetMuscle), 1);
    (ex.secondaryRegions ?? ex.secondaryMuscles ?? []).forEach((name, index) => {
      const id = normalizeMuscle(name);
      if (!regions.has(id)) regions.set(id, index === 0 ? 0.55 : 0.35);
    });
    if (regions.size === 0) { unmapped++; continue; }
    for (const [muscle, weight] of regions) tally[muscle] = (tally[muscle] ?? 0) + working * weight;
  }
  return {
    workout_count: rows.length, recorded_working_sets: completedSets,
    unmapped_entries: unmapped, weighted_muscle_sets: tally,
    methodology: "Sets per anatomical region from catalog labels: primary 1.0, secondary 0.55/0.35. Not physiological fatigue, injury diagnosis, or true recovery.",
  };
}

// API contract intentionally mirrors ReperaDomain's RoutineBlock and WODMovement,
// without ever requiring the AI to mint internal UUIDs.
const inputDays = z.number().int().min(1).max(365).default(90);
const inputLimit = z.number().int().min(1).max(100).default(30);
const pagedInput = z.strictObject({
  days: inputDays, limit: inputLimit,
  cursor: z.string().max(64).optional(),
});
function readOffset(cursor?:string):number {
  if (!cursor) return 0;
  try {
    const value = atob(cursor);
    if (!/^[0-9]+$/.test(value)) throw Error("bad cursor");
    const offset = Number(value);
    if (!Number.isSafeInteger(offset) || offset < 0 || offset > 100000)
      throw Error("bad cursor");
    return offset;
  } catch { throw Error("INVALID_CURSOR: cursor no válido"); }
}
function nextCursor(offset:number):string {
  return btoa(String(offset)).replace(/=+$/,"");
}

Deno.serve(async (request) => {
  const match = /^Bearer (rep_ai_[A-Za-z0-9_-]{43})$/.exec(request.headers.get("authorization") ?? "");
  if (!match) return fail(401, "Bearer token personal de Repera requerido");
  // Tokens are never logged, sent to third-party services, or stored in plaintext.
  const hash = await sha256(match[1]);
  const { data: token, error: tokenError } = await db.from("ai_access_tokens")
    .select("id,owner_id,expires_at,scopes")
    .eq("token_hash", hash).is("revoked_at", null).maybeSingle();
  if (tokenError) return fail(503, "No se pudo verificar el token");
  if (!token || (token.expires_at && Date.parse(token.expires_at) <= Date.now())) {
    return fail(401, "Token caducado o revocado");
  }
  const ownerId: string = token.owner_id;
  const canWrite = (token.scopes ?? ["training:read","training:write"]).includes("training:write");
  // Only owner-scoped reads and inserts. Service role cannot leak other athletes.
  await db.from("ai_access_tokens").update({ last_used_at: new Date().toISOString() }).eq("id", token.id).eq("owner_id", ownerId);
  if (Number(request.headers.get("content-length") || 0) > 150_000) return fail(413, "Petición demasiado grande");

  async function workouts(days: number, limit: number): Promise<WorkoutRow[]> {
    const after = new Date(Date.now() - days * 86_400_000).toISOString();
    const { data, error } = await db.from("athlete_workouts")
      .select("id,title,started_at,finished_at,updated_at,exercises,wod_results")
      .eq("owner_id", ownerId).gte("finished_at", after)
      .order("finished_at", { ascending: false }).limit(limit);
    if (error) throw new Error("No se pudo consultar el historial de este usuario");
    return (data ?? []) as WorkoutRow[];
  }

  async function saveWorkouts(items: z.infer<typeof workout>[], programId?: string, idempotencyKey?: string) {
    const now = Date.now();
    let program: {start_date:string;duration_weeks:number}|null = null;
    if (programId) {
      const {data,error}=await db.from("athlete_training_programs")
        .select("start_date,duration_weeks").eq("id",programId).eq("owner_id",ownerId).maybeSingle();
      if(error||!data) throw new Error("El programa no pertenece al usuario");
      program=data;
    }
    // Parse as UTC at noon to avoid impossible dates and midnight TZ drift.
    const unique = new Set<string>();
    for (const item of items) {
      const d = new Date(item.scheduledDate + "T12:00:00Z");
      scheduledInstant(item.scheduledDate,item.scheduledTimeMinutes,
        item.scheduledTimeZone,item.scheduledUtcOffsetMinutes);
      if (Number.isNaN(d.valueOf()) || d.toISOString().slice(0, 10) !== item.scheduledDate)
        throw new Error("Fecha de planificación no válida");
      if (d.valueOf() < now - 2 * 86_400_000 || d.valueOf() > now + 365 * 86_400_000)
        throw new Error("El plan debe situarse entre hoy y los próximos 12 meses");
      if (program) {
        const begin=Date.parse(program.start_date+"T00:00:00Z");
        const end=begin+program.duration_weeks*7*86400000;
        if(d.getTime()<begin||d.getTime()>=end)
          throw new Error("El entrenamiento debe estar dentro de las fechas del programa");
      }
      if (unique.has(item.scheduledDate)) throw new Error("No repitas una fecha dentro del mismo plan");
      unique.add(item.scheduledDate);
    }
    // Stable deterministic UUID per owner+request: a retry cannot duplicate
    // dated proposals. Existing records are never silently overwritten.
    let batchId = crypto.randomUUID();
    if (idempotencyKey) {
      const digest = new Uint8Array(await crypto.subtle.digest("SHA-256",
        new TextEncoder().encode(ownerId+":"+idempotencyKey)));
      digest[6] = (digest[6] & 0x0f) | 0x50;
      digest[8] = (digest[8] & 0x3f) | 0x80;
      const hex = Array.from(digest.slice(0,16),b=>b.toString(16).padStart(2,"0")).join("");
      batchId = [hex.slice(0,8),hex.slice(8,12),hex.slice(12,16),hex.slice(16,20),hex.slice(20,32)].join("-");
      const {data:existing,error:readError} = await db.from("ai_training_plans")
        .select("id,title,scheduled_date,status")
        .eq("owner_id",ownerId).eq("batch_id",batchId).limit(14);
      if (readError) throw new Error("No se pudo comprobar idempotencia");
      if (existing?.length) return {batch_id:batchId,workouts:existing,
        idempotent_replay:true,notice:"Solicitud ya aplicada; se conservan los entrenamientos originales."};
    }
    const { data, error } = await db.from("ai_training_plans").insert(items.map(item => ({
      owner_id: ownerId,
      created_by_token_id: token.id,
      program_id: programId ?? null,
      batch_id: batchId,
      title: item.title,
      scheduled_date: item.scheduledDate,
      scheduled_time_minutes: item.scheduledTimeMinutes ?? null,
      scheduled_time_zone:item.scheduledTimeZone ?? null,
      scheduled_utc_offset_minutes:item.scheduledUtcOffsetMinutes ?? null,
      scheduled_at:scheduledInstant(item.scheduledDate,item.scheduledTimeMinutes,
        item.scheduledTimeZone,item.scheduledUtcOffsetMinutes),
      payload: { schemaVersion: 1, blocks: item.blocks },
      status: "pending",
    }))).select("id,title,scheduled_date,status");
    if (error?.code === "23505" && idempotencyKey) {
      const {data:already,error:readError} = await db.from("ai_training_plans")
        .select("id,title,scheduled_date,status").eq("owner_id",ownerId)
        .eq("batch_id",batchId).limit(14);
      if (!readError && already?.length) return {batch_id:batchId,workouts:already,idempotent_replay:true};
    }
    if (error) throw new Error("No se pudo guardar la planificación validada");
    return {
      batch_id: batchId, workouts: data ?? [],
      delivery: "Pendiente de incorporar en el iPhone. Se importará al abrir o sincronizar Repera, sin reemplazar un entrenamiento existente en esa fecha.",
    };
  }

  const handler = createMcpHandler(() => {
    const server = new McpServer({ name: "repera-training", version: "0.4.0" });
    registerCoachTools(server, db, ownerId, token.id, canWrite);
    registerAthleteChangeTools(server,db,ownerId,token.id,canWrite);
    if (canWrite) registerMutationTools(server, db, ownerId, workout);
    server.registerTool("get_mcp_access_info", {
      description:"Display the current personal token's permission scopes, expiry and revocation instructions. No credential contents are exposed.",
      inputSchema:z.strictObject({}),annotations:{readOnlyHint:true},
    },async()=>reply({
      token_id:token.id,
      scopes:token.scopes ?? ["training:read","training:write"],
      expires_at:token.expires_at ?? null,
      expires:token.expires_at!=null,
      revoke_in:"Repera iOS → Ajustes → Acceso IA → Revocar token",
      protocol:"Personal HTTPS Bearer token (PAT), not OAuth. Do not forward to third parties.",
      date_semantics:"scheduledDate is athlete-local date. If scheduledTimeMinutes is given, scheduledTimeZone (IANA) and scheduledUtcOffsetMinutes (UTC east-positive) are required; scheduled_at resolves an exact instant including DST.",
    }));
    server.registerTool("get_workout_history", {
      description: "History of completed Repera exercises, logged sets and WOD results; no HealthKit, routes, GPS, energy, body weight or notes.",
      inputSchema: pagedInput,
      annotations: { readOnlyHint: true },
    }, async ({ days, limit, cursor }) => {
      const offset=readOffset(cursor);
      const after=new Date(Date.now()-days*86400000).toISOString();
      const {data,error}=await db.from("athlete_workouts")
        .select("id,title,started_at,finished_at,updated_at,exercises,wod_results")
        .eq("owner_id",ownerId).gte("finished_at",after)
        .order("finished_at",{ascending:false}).order("id",{ascending:true})
        .range(offset,offset+limit);
      if(error)throw Error("No se pudo consultar historial");
      const page=(data??[]) as WorkoutRow[];
      const hasMore=page.length>limit;
      return reply({items:page.slice(0,limit).map(row=>({
        id:row.id,title:row.title,started_at:row.started_at,finished_at:row.finished_at,
        updated_at:row.updated_at,
        exercises:(row.exercises??[]).map(projectExercise),wod_results:row.wod_results??[],
      })),hasMore,nextCursor:hasMore?nextCursor(offset+limit):null,
      order:"finished_at DESC,id ASC",days});
    });
    server.registerTool("analyze_muscle_balance", {
      description: "Estimate muscle-region weighted set volume from the user's logged workouts, not measured fatigue.",
      inputSchema: z.strictObject({ days: z.number().int().min(7).max(90).default(28) }),
      annotations: { readOnlyHint: true },
    }, async ({ days }) => reply({ days, ...muscleBalance(await workouts(days, 500)) }));
    server.registerTool("get_exercise_progress", {
      description: "Exercise name search in completed sessions, reporting logged weight and reps progression.",
      inputSchema: z.strictObject({ name: z.string().trim().min(2).max(100), days: inputDays }),
      annotations: { readOnlyHint: true },
    }, async ({ name, days }) => {
      const needle = name.toLocaleLowerCase("es");
      const rows = await workouts(days, 500);
      return reply(rows.flatMap(row => (row.exercises ?? [])
        .filter(e => (e.exercise?.name ?? "").toLocaleLowerCase("es").includes(needle))
        .map(e => ({ date: row.finished_at, exercise: e.exercise?.name,
          sets: (e.loggedSets ?? []).length,
          reps: (e.loggedSets ?? []).reduce((n, s) => n + (s.reps ?? 0), 0),
          max_weight_kg: Math.max(0, ...(e.loggedSets ?? []).map(s => s.weightKg ?? 0)),
        }))));
    });
    server.registerTool("search_training_exercises", {
      description: "Search named movements in the Repera professional catalog. Do not invent unprovided anatomical metadata.",
      inputSchema: z.strictObject({ query: z.string().trim().min(2).max(100), limit: z.number().int().min(1).max(50).default(20) }),
      annotations: { readOnlyHint: true },
    }, async ({ query, limit }) => {
      const pattern = query.replace(/[%_\\]/g, " ").trim();
      const { data, error } = await db.from("training_exercise_catalog")
        .select("catalog_key,name,category").ilike("name", "%" + pattern + "%").order("name").limit(limit);
      if (error) throw new Error("Error al buscar el catálogo");
      return reply(data ?? []);
    });
    server.registerTool("get_ai_training_plans", {
      description: "List future plans submitted to this user's Repera calendar and their sync status.",
      inputSchema: z.strictObject({limit:inputLimit,cursor:z.string().max(64).optional()}),
      annotations: { readOnlyHint: true },
    }, async ({ limit, cursor }) => {
      const offset=readOffset(cursor);
      const { data, error } = await db.from("ai_training_plans")
        .select("id,batch_id,title,scheduled_date,scheduled_time_minutes,scheduled_time_zone,scheduled_utc_offset_minutes,scheduled_at,payload,status,revision,created_at")
        .eq("owner_id", ownerId).order("scheduled_date", { ascending: true }).order("id",{ascending:true})
        .range(offset,offset+limit);
      if (error) throw new Error("Error al obtener planificaciones");
      const rows=data??[],hasMore=rows.length>limit;
      return reply({items:rows.slice(0,limit),hasMore,nextCursor:hasMore?nextCursor(offset+limit):null});
    });
    if (canWrite) {
    server.registerTool("create_workout", {
      description: "Create one fully structured workout with typed strength/WOD blocks, sets, RIR, weights and schedule date. Repera imports it to Diario/Inicio, without overwriting existing day plans. Explicit user-requested write.",
      inputSchema: workout.extend({ idempotencyKey: z.string().uuid().optional() }),
      annotations: { readOnlyHint: false, destructiveHint: false },
    }, async ({idempotencyKey,...args}) => reply(await saveWorkouts([args],undefined,idempotencyKey)));
    server.registerTool("create_training_plan", {
      description: "Create 1-14 dated workouts with native Repera strength and WOD blocks. Writes actual structured plans for Diario/Inicio; do this only at user request.",
      inputSchema: z.strictObject({ workouts: z.array(workout).min(1).max(14),
        programId: z.string().uuid().optional(), idempotencyKey: z.string().uuid().optional() }),
      annotations: { readOnlyHint: false, destructiveHint: false },
    }, async ({ workouts: items, programId, idempotencyKey }) => reply(await saveWorkouts(items, programId, idempotencyKey)));
    }
    return server;
  });
  const response = await handler.fetch(request);
  response.headers.set("cache-control", "no-store");
  return response;
});
