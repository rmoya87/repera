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
  blocks: z.array(block).min(1).max(12),
}).superRefine((w, ctx) => {
  if (w.scheduledTimeMinutes != null && (w.scheduledTimeMinutes < 0 || w.scheduledTimeMinutes > 1439)) {
    ctx.addIssue({code:"custom",path:["scheduledTimeMinutes"],message:"Time must be minutes since midnight, local to the athlete"});
  }
});

