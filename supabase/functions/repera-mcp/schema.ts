import { z } from "npm:zod@4.3.6";

// Single source of truth for MCP creation AND pending-plan edits.
const plannedSet = z.strictObject({
  reps: z.number().int().min(1).max(5000),
  weightKg: z.number().finite().min(0).max(1200).optional(),
  rir: z.number().finite().min(0).max(10).optional(),
  percent1RM: z.number().finite().min(1).max(150).optional(),
  percent1RMIsMinimum: z.boolean().optional(),
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
export const wodFormat = z.enum([
  "amrap", "emom", "forTime", "tabata", "chipper", "deathBy", "strength", "afap",
  "ladder", "partner", "buyInCashOut", "roundsForQuality", "circuit", "maxEffort",
]);
// Contract shared by the MCP's format reference tool and incoming WOD plans.
// Align values with ReperaDomain.WODFormat.resultCapture. These describe actual
// persisted iOS results, not unimplemented fields or invented telemetry.
export const wodFormatContract = {
  amrap: {
    resultCapture: "totalReps", primaryResult: "rounds_completed_plus_partial_reps",
    timer: "countdown", details: "roundsCompleted = vueltas completas; totalReps = SOLO reps de la vuelta incompleta. No multiplicar ni sumar todas las reps a este campo.",
  },
  forTime: {
    resultCapture: "elapsedTime", primaryResult: "elapsed_seconds",
    timer: "countup_optional_time_cap", details: "RFT usa rounds como prescripción. elapsedSeconds es tiempo REAL; el time cap avisa, nunca reemplaza la marca.",
  },
  emom: {
    resultCapture: "perMovementSets", primaryResult: "sets_and_repetitions_per_interval",
    timer: "configured_intervals", details: "Cada Every X configura ventanas en segundos; el descanso es el tiempo sobrante dentro de la ventana. No crear un score global de rondas.",
  },
  tabata: {
    resultCapture: "perMovementSets", primaryResult: "work_interval_results",
    timer: "alternating_work_and_rest", details: "Por defecto 20s de trabajo + 10s de descanso × 8. Cada ventana de TRABAJO corresponde a registro por serie/movimiento; el descanso no es una serie.",
    limitation: "Historial iOS actual: loggedSets por movimiento, sin intervalId persistente; no atribuir un log a un intervalo exacto sin evidencia.",
  },
  chipper: {
    resultCapture: "elapsedTime", primaryResult: "elapsed_seconds",
    timer: "countup", details: "Prescripción de movimientos en una pasada y resultado de tiempo total.",
  },
  afap: {
    resultCapture: "elapsedTime", primaryResult: "elapsed_seconds",
    timer: "countup", details: "La marca es el tiempo total para completar la prescripción.",
  },
  ladder: {
    resultCapture: "elapsedTime", primaryResult: "elapsed_seconds",
    timer: "countup", details: "La escalera/repScheme es prescripción; elapsedSeconds es la marca.",
  },
  buyInCashOut: {
    resultCapture: "elapsedTime", primaryResult: "elapsed_seconds",
    timer: "countup", details: "Tiempo del bloque completo, incluidas las partes buy-in y cash-out.",
  },
  strength: {
    resultCapture: "perMovementSets", primaryResult: "sets_load_reps_rir",
    timer: "optional_stopwatch", details: "Fuerza/Skill: cada serie conserva carga, reps y RIR, sin resultado global de rondas.",
  },
  deathBy: {
    resultCapture: "totalReps", primaryResult: "rounds_completed_plus_partial_reps",
    timer: "progressive_intervals", details: "roundsCompleted indica intervalos superados y totalReps las reps del intervalo incompleto. El reloj permite parar al fallar.",
  },
  maxEffort: {
    resultCapture: "totalReps", primaryResult: "max_repetitions",
    timer: "specific_countdown", details: "El score actual de Repera solo admite reps máximas (totalReps).",
    limitation: "Una marca máxima en kg/calorías/metros aún no dispone de campo de score global en iOS. No inventarla ni convertirla en reps.",
  },
  circuit: {
    resultCapture: "perMovementSets", primaryResult: "sets_per_station",
    timer: "station_intervals_and_round_rests", details: "Registrar estación/movimiento por serie, con descansos configurables entre rondas.",
  },
  partner: {
    resultCapture: "perMovementSets", primaryResult: "per_movement_sets",
    timer: "optional_stopwatch", details: "YGIG/Partner se registra por movimientos y series según prescripción.",
  },
  roundsForQuality: {
    resultCapture: "perMovementSets", primaryResult: "per_movement_sets",
    timer: "optional_stopwatch", details: "Rounds for Quality prioriza calidad; no tratar rounds como AMRAP cronometrado.",
  },
} as const satisfies Record<z.infer<typeof wodFormat>, {
  resultCapture: "totalReps" | "elapsedTime" | "perMovementSets";
  primaryResult: string; timer: string; details: string; limitation?: string;
}>;

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
  if (b.kind === "wod" && b.wodFormat === "amrap" && b.timeCapMinutes == null) {
    ctx.addIssue({ code: "custom", path: ["timeCapMinutes"], message: "AMRAP requires a fixed countdown duration in minutes" });
  }
  if (b.kind === "wod" && b.wodFormat === "emom" && b.emomIntervalSeconds == null) {
    ctx.addIssue({ code: "custom", path: ["emomIntervalSeconds"], message: "EMOM requires its interval in seconds" });
  }
  if (b.kind === "wod" && b.wodFormat === "forTime" && (b.rounds ?? 1) < 1) {
    ctx.addIssue({ code: "custom", path: ["rounds"], message: "For Time must have positive rounds" });
  }
});
export const workout = z.strictObject({
  title: z.string().trim().min(2).max(120),
  scheduledDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  scheduledTimeMinutes: z.number().int().min(0).max(1439).optional(),
  scheduledTimeZone: z.string().trim().min(3).max(80).optional(),
  scheduledUtcOffsetMinutes: z.number().int().min(-840).max(840).optional(),
  blocks: z.array(block).min(1).max(12),
}).superRefine((w, ctx) => {
  if (w.scheduledTimeMinutes != null && (!w.scheduledTimeZone || w.scheduledUtcOffsetMinutes == null)) {
    ctx.addIssue({code:"custom",path:["scheduledTimeZone"],message:"Scheduled time needs IANA time zone and UTC offset for DST"});
  }
  if (w.scheduledTimeMinutes == null && w.scheduledUtcOffsetMinutes != null) {
    ctx.addIssue({code:"custom",path:["scheduledUtcOffsetMinutes"],message:"UTC offset only applies when scheduledTimeMinutes is set"});
  }
  if (w.scheduledTimeMinutes != null && (w.scheduledTimeMinutes < 0 || w.scheduledTimeMinutes > 1439)) {
    ctx.addIssue({code:"custom",path:["scheduledTimeMinutes"],message:"Time must be minutes since midnight, local to the athlete"});
  }
});

