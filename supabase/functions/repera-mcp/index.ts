import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createMcpHandler, McpServer } from "npm:@modelcontextprotocol/server@2.0.0";
import { createClient } from "npm:@supabase/supabase-js@2.58.0";
import { z } from "npm:zod@4.3.6";

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
  exercise?: {
    name?: string; catalogId?: string; muscleGroup?: string; targetMuscle?: string;
    primaryRegions?: string[]; secondaryRegions?: string[]; secondaryMuscles?: string[];
  };
  loggedSets?: Array<{
    reps?: number; weightKg?: number; rir?: number; phase?: string; kind?: string;
    durationSeconds?: number;
  }>;
};
type WorkoutRow = {
  id: string; title: string; started_at: string | null; finished_at: string | null;
  exercises: ExerciseEntry[]; wod_results: unknown[];
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
    name: ex.name ?? "", catalog_key: ex.catalogId ?? null,
    muscle_group: ex.muscleGroup ?? null,
    target_muscle: ex.targetMuscle ?? null,
    primary_regions: ex.primaryRegions ?? [],
    secondary_regions: ex.secondaryRegions ?? [],
    sets: (entry.loggedSets ?? []).map(s => ({
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
const plannedSet = z.strictObject({
  reps: z.number().int().min(1).max(5000),
  weightKg: z.number().finite().min(0).max(1200).optional(),
  rir: z.number().finite().min(0).max(10).optional(),
});
const strengthEntry = z.strictObject({
  name: z.string().trim().min(2).max(120),
  catalogKey: z.string().trim().max(160).optional(),
  plannedSets: z.array(plannedSet).min(1).max(20),
  restSeconds: z.number().int().min(0).max(1800).optional(),
});
const movement = z.strictObject({
  name: z.string().trim().min(2).max(120),
  catalogKey: z.string().trim().max(160).optional(),
  reps: z.number().int().min(1).max(5000).optional(),
  repScheme: z.array(z.number().int().min(1).max(5000)).min(2).max(30).optional(),
  distanceMeters: z.number().int().min(1).max(50000).optional(),
  calories: z.number().int().min(1).max(1000).optional(),
  weightMaleKg: z.number().finite().min(0).max(1200).optional(),
  weightFemaleKg: z.number().finite().min(0).max(1200).optional(),
  isRest: z.boolean().optional(),
  restSeconds: z.number().int().min(1).max(1800).optional(),
  scaleAlternative: z.string().max(180).optional(),
  explicitPlannedSets: z.array(plannedSet).max(30).optional(),
});
const wodFormat = z.enum([
  "amrap", "emom", "forTime", "tabata", "chipper", "deathBy", "strength", "afap",
  "ladder", "partner", "buyInCashOut", "roundsForQuality", "circuit", "maxEffort",
]);
const block = z.strictObject({
  title: z.string().trim().min(1).max(100),
  kind: z.enum(["strength", "wod"]),
  exercises: z.array(strengthEntry).max(25).default([]),
  movements: z.array(movement).max(40).default([]),
  wodFormat: wodFormat.optional(),
  timeCapMinutes: z.number().int().min(1).max(240).optional(),
  emomIntervalSeconds: z.number().int().min(10).max(3600).optional(),
  rounds: z.number().int().min(1).max(200).optional(),
  workSeconds: z.number().int().min(5).max(3600).optional(),
  restSeconds: z.number().int().min(0).max(3600).optional(),
  restBetweenRoundsSeconds: z.number().int().min(0).max(3600).optional(),
  wodNotes: z.string().max(1000).optional(),
}).superRefine((b, ctx) => {
  if (b.kind === "strength" && (b.exercises.length === 0 || b.movements.length > 0 || b.wodFormat)) {
    ctx.addIssue({ code: "custom", message: "Strength blocks need exercises, not WOD movements" });
  }
  if (b.kind === "wod" && (!b.wodFormat || b.movements.length === 0 || b.exercises.length > 0)) {
    ctx.addIssue({ code: "custom", message: "WOD blocks need format and movements" });
  }
});
const workout = z.strictObject({
  title: z.string().trim().min(2).max(120),
  scheduledDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  scheduledTimeMinutes: z.number().int().min(0).max(1439).optional(),
  blocks: z.array(block).min(1).max(12),
});
const inputDays = z.number().int().min(1).max(365).default(90);
const inputLimit = z.number().int().min(1).max(100).default(30);

Deno.serve(async (request) => {
  const match = /^Bearer (rep_ai_[A-Za-z0-9_-]{43})$/.exec(request.headers.get("authorization") ?? "");
  if (!match) return fail(401, "Bearer token personal de Repera requerido");
  // Tokens are never logged, sent to third-party services, or stored in plaintext.
  const hash = await sha256(match[1]);
  const { data: token, error: tokenError } = await db.from("ai_access_tokens")
    .select("id,owner_id,expires_at")
    .eq("token_hash", hash).is("revoked_at", null).maybeSingle();
  if (tokenError) return fail(503, "No se pudo verificar el token");
  if (!token || (token.expires_at && Date.parse(token.expires_at) <= Date.now())) {
    return fail(401, "Token caducado o revocado");
  }
  const ownerId: string = token.owner_id;
  // Only owner-scoped reads and inserts. Service role cannot leak other athletes.
  await db.from("ai_access_tokens").update({ last_used_at: new Date().toISOString() }).eq("id", token.id).eq("owner_id", ownerId);
  if (Number(request.headers.get("content-length") || 0) > 150_000) return fail(413, "Petición demasiado grande");

  async function workouts(days: number, limit: number): Promise<WorkoutRow[]> {
    const after = new Date(Date.now() - days * 86_400_000).toISOString();
    const { data, error } = await db.from("athlete_workouts")
      .select("id,title,started_at,finished_at,exercises,wod_results")
      .eq("owner_id", ownerId).gte("finished_at", after)
      .order("finished_at", { ascending: false }).limit(limit);
    if (error) throw new Error("No se pudo consultar el historial de este usuario");
    return (data ?? []) as WorkoutRow[];
  }

  async function saveWorkouts(items: z.infer<typeof workout>[]) {
    const now = Date.now();
    // Parse as UTC at noon to avoid impossible dates and midnight TZ drift.
    const unique = new Set<string>();
    for (const item of items) {
      const d = new Date(item.scheduledDate + "T12:00:00Z");
      if (Number.isNaN(d.valueOf()) || d.toISOString().slice(0, 10) !== item.scheduledDate)
        throw new Error("Fecha de planificación no válida");
      if (d.valueOf() < now - 2 * 86_400_000 || d.valueOf() > now + 365 * 86_400_000)
        throw new Error("El plan debe situarse entre hoy y los próximos 12 meses");
      if (unique.has(item.scheduledDate)) throw new Error("No repitas una fecha dentro del mismo plan");
      unique.add(item.scheduledDate);
    }
    const batchId = crypto.randomUUID();
    const { data, error } = await db.from("ai_training_plans").insert(items.map(item => ({
      owner_id: ownerId,
      created_by_token_id: token.id,
      batch_id: batchId,
      title: item.title,
      scheduled_date: item.scheduledDate,
      scheduled_time_minutes: item.scheduledTimeMinutes ?? null,
      payload: { schemaVersion: 1, blocks: item.blocks },
      status: "pending",
    }))).select("id,title,scheduled_date,status");
    if (error) throw new Error("No se pudo guardar la planificación validada");
    return {
      batch_id: batchId, workouts: data ?? [],
      delivery: "Pendiente de incorporar en el iPhone. Se importará al abrir o sincronizar Repera, sin reemplazar un entrenamiento existente en esa fecha.",
    };
  }

  const handler = createMcpHandler(() => {
    const server = new McpServer({ name: "repera-training", version: "0.2.0" });
    server.registerTool("get_workout_history", {
      description: "History of completed Repera exercises, logged sets and WOD results; no HealthKit, routes, GPS, energy, body weight or notes.",
      inputSchema: z.object({ days: inputDays, limit: inputLimit }),
      annotations: { readOnlyHint: true },
    }, async ({ days, limit }) => reply((await workouts(days, limit)).map(row => ({
      id: row.id, title: row.title, started_at: row.started_at, finished_at: row.finished_at,
      exercises: (row.exercises ?? []).map(projectExercise), wod_results: row.wod_results ?? [],
    }))));
    server.registerTool("analyze_muscle_balance", {
      description: "Estimate muscle-region weighted set volume from the user's logged workouts, not measured fatigue.",
      inputSchema: z.object({ days: z.number().int().min(7).max(90).default(28) }),
      annotations: { readOnlyHint: true },
    }, async ({ days }) => reply({ days, ...muscleBalance(await workouts(days, 500)) }));
    server.registerTool("get_exercise_progress", {
      description: "Exercise name search in completed sessions, reporting logged weight and reps progression.",
      inputSchema: z.object({ name: z.string().trim().min(2).max(100), days: inputDays }),
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
      inputSchema: z.object({ query: z.string().trim().min(2).max(80), limit: inputLimit }),
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
      inputSchema: z.object({ limit: inputLimit }),
      annotations: { readOnlyHint: true },
    }, async ({ limit }) => {
      const { data, error } = await db.from("ai_training_plans")
        .select("id,batch_id,title,scheduled_date,scheduled_time_minutes,payload,status,created_at")
        .eq("owner_id", ownerId).order("scheduled_date", { ascending: true }).limit(limit);
      if (error) throw new Error("Error al obtener planificaciones");
      return reply(data ?? []);
    });
    server.registerTool("create_workout", {
      description: "Create one fully structured workout with typed strength/WOD blocks, sets, RIR, weights and schedule date. Repera imports it to Diario/Inicio, without overwriting existing day plans. Explicit user-requested write.",
      inputSchema: workout,
      annotations: { readOnlyHint: false, destructiveHint: false },
    }, async (args) => reply(await saveWorkouts([args])));
    server.registerTool("create_training_plan", {
      description: "Create 1-14 dated workouts with native Repera strength and WOD blocks. Writes actual structured plans for Diario/Inicio; do this only at user request.",
      inputSchema: z.object({ workouts: z.array(workout).min(1).max(14) }),
      annotations: { readOnlyHint: false, destructiveHint: false },
    }, async ({ workouts: items }) => reply(await saveWorkouts(items)));
    return server;
  });
  const response = await handler.fetch(request);
  response.headers.set("cache-control", "no-store");
  return response;
});
