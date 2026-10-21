import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createMcpHandler, McpServer } from "npm:@modelcontextprotocol/server@2.0.0";
import { pipeline } from "npm:@supabase/middleware@1";
import { withOAuthProtectedResource, withSupabase } from "npm:@supabase/server@1.6.0";
import { z } from "npm:zod@4.3.6";

// This endpoint is an OAuth-only, read-only capability. Never use service_role.
// withSupabase verifies a caller JWT before the handler is entered; RLS still
// authorizes every query. Per-client consent is checked again on each request.
const BODY_MAP = [
  "trapezius", "deltoids", "chest", "upper-back", "serratus",
  "biceps", "triceps", "forearm", "abs", "obliques", "lower-back",
  "gluteal", "quadriceps", "hamstring", "adductors", "hip-flexors",
  "calves", "tibialis",
];

type ExerciseEntry = {
  exercise?: {
    name?: string;
    catalogId?: string;
    muscleGroup?: string;
    targetMuscle?: string;
    primaryRegions?: string[];
    secondaryRegions?: string[];
    secondaryMuscles?: string[];
  };
  loggedSets?: Array<{
    reps?: number; weightKg?: number; rir?: number;
    isWarmup?: boolean; phase?: string; kind?: string;
    durationSeconds?: number;
  }>;
};
type WorkoutRow = {
  id: string;
  title: string;
  started_at: string | null;
  finished_at: string | null;
  exercises: ExerciseEntry[];
  wod_results: unknown[];
};

function oauthClientId(authorization: string | null): string | null {
  if (!authorization?.startsWith("Bearer ")) return null;
  try {
    const part = authorization.slice(7).split(".")[1];
    if (!part) return null;
    const payload = JSON.parse(atob(part.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(part.length / 4) * 4, "=")));
    const id = payload.client_id;
    return typeof id === "string" && id.length >= 2 && id.length <= 200 ? id : null;
  } catch { return null; }
}

function textResult(value: unknown) {
  return { content: [{ type: "text" as const, text: JSON.stringify(value) }] };
}

function safeExercise(entry: ExerciseEntry) {
  return {
    name: entry.exercise?.name ?? "Ejercicio sin nombre",
    catalog_id: entry.exercise?.catalogId ?? null,
    muscle_group: entry.exercise?.muscleGroup ?? null,
    target_muscle: entry.exercise?.targetMuscle ?? null,
    primary_regions: entry.exercise?.primaryRegions ?? [],
    secondary_regions: entry.exercise?.secondaryRegions ?? [],
    sets: (entry.loggedSets ?? []).map((set) => ({
      reps: set.reps ?? null, weight_kg: set.weightKg ?? null,
      rir: set.rir ?? null, duration_seconds: set.durationSeconds ?? null,
      phase: set.phase ?? null, kind: set.kind ?? null,
    })),
  };
}

function weightsFor(entry: ExerciseEntry): Record<string, number> {
  const e = entry.exercise ?? {};
  const out: Record<string, number> = {};
  const add = (name: string | undefined, weight: number) => {
    if (!name || !BODY_MAP.includes(name)) return;
    out[name] = Math.max(out[name] ?? 0, weight);
  };
  add(e.targetMuscle, 1);
  for (const name of e.primaryRegions ?? []) add(name, 1);
  (e.secondaryRegions ?? e.secondaryMuscles ?? []).forEach((name, i) => add(name, i === 0 ? 0.55 : 0.35));
  // If movement metadata is insufficient, report unknown instead of
  // inventing anatomical load.
  return out;
}

function analyzeBalance(rows: WorkoutRow[]) {
  const counts: Record<string, number> = Object.fromEntries(BODY_MAP.map((name) => [name, 0]));
  let mappedExercises = 0;
  let unclassifiedExercises = 0;
  let loggedSets = 0;
  for (const row of rows) {
    for (const entry of row.exercises ?? []) {
      const weights = weightsFor(entry);
      const sets = (entry.loggedSets ?? []).filter((set) =>
        (set.reps ?? 0) > 0 && set.kind !== "warmup" && set.phase !== "warmup"
      ).length;
      loggedSets += sets;
      if (!Object.keys(weights).length) {
        unclassifiedExercises++;
        continue;
      }
      mappedExercises++;
      for (const [muscle, weight] of Object.entries(weights)) {
        counts[muscle] += sets * weight;
      }
    }
  }
  return {
    sessions: rows.length, logged_sets: loggedSets,
    mapped_exercises: mappedExercises, unclassified_exercises: unclassifiedExercises,
    muscle_weighted_sets: counts,
    methodology: "Weighted completed sets by catalog primary (1.0) and secondary (0.55 / 0.35) muscles. Not a medical fatigue or recovery measurement.",
    limits: "Unknown exercise mapping is not assigned to arbitrary muscle groups. Training outside Repera may be missing.",
  };
}

// Keep discoverability on the Supabase project domain until the external Auth
// issuer and OAuth consent page are configured and tested end-to-end.
Deno.serve(
  pipeline(
    [withOAuthProtectedResource(), withSupabase({ auth: "user" })],
    async (request, { supabase }) => {
      const clientId = oauthClientId(request.headers.get("authorization"));
      if (!clientId) return new Response("OAuth client authentication required", { status: 403 });
      const { data: identity, error: identityError } = await supabase.auth.getUser();
      if (identityError || !identity.user) return new Response("Unauthorized", { status: 401 });
      const { data: consent, error: consentError } = await supabase
        .from("mcp_user_consents")
        .select("client_id")
        .eq("user_id", identity.user.id)
        .eq("client_id", clientId)
        .eq("enabled", true)
        .maybeSingle();
      if (consentError || !consent) return new Response("Repera MCP access not granted", { status: 403 });

      async function workouts(days: number, limit: number): Promise<WorkoutRow[]> {
        const after = new Date(Date.now() - days * 86400000).toISOString();
        const { data, error } = await supabase
          .from("athlete_workouts")
          .select("id,title,started_at,finished_at,exercises,wod_results")
          .gte("finished_at", after)
          .order("finished_at", { ascending: false })
          .limit(limit);
        if (error) throw new Error("Unable to read authorized workout history");
        return (data ?? []) as WorkoutRow[];
      }

      const handler = createMcpHandler(() => {
        const server = new McpServer({ name: "repera-training", version: "0.1.0" });
        server.registerTool("get_workout_history", {
          description: "Completed Repera training sessions with exercise sets and WOD results; excludes HealthKit, location, routes, notes and body measurements.",
          inputSchema: z.object({
            days: z.number().int().min(1).max(365).default(90),
            limit: z.number().int().min(1).max(100).default(30),
          }),
          annotations: { readOnlyHint: true },
        }, async ({ days, limit }) => {
          const rows = await workouts(days, limit);
          return textResult(rows.map((row) => ({
            id: row.id, title: row.title, started_at: row.started_at,
            finished_at: row.finished_at,
            exercises: (row.exercises ?? []).map(safeExercise),
            wod_results: row.wod_results ?? [],
          })));
        });

        server.registerTool("analyze_muscle_balance", {
          description: "Calculate weighted recorded working-set distribution for 18 muscle regions from recorded workouts. This is not a diagnosis of muscle fatigue.",
          inputSchema: z.object({
            days: z.number().int().min(7).max(90).default(28),
          }),
          annotations: { readOnlyHint: true },
        }, async ({ days }) => textResult({ days, ...(analyzeBalance(await workouts(days, 500))) }));

        server.registerTool("get_exercise_progress", {
          description: "Find frequency, max logged weight and per-session reps for one exercise from the athlete's private training history.",
          inputSchema: z.object({
            name: z.string().trim().min(2).max(100),
            days: z.number().int().min(7).max(365).default(180),
          }),
          annotations: { readOnlyHint: true },
        }, async ({ name, days }) => {
          const needle = name.toLocaleLowerCase("es");
          const rows = await workouts(days, 500);
          const history = rows.flatMap((row) => (row.exercises ?? [])
            .filter((entry) => (entry.exercise?.name ?? "").toLocaleLowerCase("es").includes(needle))
            .map((entry) => ({
              date: row.finished_at,
              exercise: entry.exercise?.name ?? "",
              series: (entry.loggedSets ?? []).length,
              max_weight_kg: Math.max(0, ...(entry.loggedSets ?? []).map((set) => set.weightKg ?? 0)),
              reps: (entry.loggedSets ?? []).reduce((total, set) => total + (set.reps ?? 0), 0),
            })));
          return textResult({ query: name, days, sessions: history.length, history });
        });

        server.registerTool("search_training_exercises", {
          description: "Search the Repera professional exercise catalog by name. Exercise metadata is incomplete; do not invent missing muscles or difficulty.",
          inputSchema: z.object({
            query: z.string().trim().min(2).max(80),
            limit: z.number().int().min(1).max(40).default(20),
          }),
          annotations: { readOnlyHint: true },
        }, async ({ query, limit }) => {
          const search = query.replace(/[%_,]/g, " ").trim();
          const { data, error } = await supabase
            .from("training_exercise_catalog")
            .select("catalog_key,name,category")
            .ilike("name", "%" + search + "%")
            .order("name")
            .limit(limit);
          if (error) throw new Error("Unable to search exercise catalog");
          return textResult({ results: data ?? [], catalog_scope: "professional basic catalog" });
        });
        return server;
      });
      return handler.fetch(request);
    },
  ),
);
