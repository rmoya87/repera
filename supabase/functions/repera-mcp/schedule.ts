import { z } from "npm:zod@4.3.6";
import type { McpServer } from "npm:@modelcontextprotocol/server@2.0.0";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2.58.0";

const result = (data: unknown) => ({ content: [{ type: "text" as const, text: JSON.stringify(data) }] });

/**
 * Read-only view of center commitments the athlete already sees in the app:
 * booked classes/appointments and coach-prescribed sessions. Every query is
 * anchored on clients.user_id = ownerId; staff notes, other clients, passes
 * and payments are never selected.
 */
export function registerProfessionalScheduleTools(server: McpServer, db: SupabaseClient, ownerId: string) {
  server.registerTool("get_professional_schedule", {
    title: "Clases y sesiones de tus centros",
    description:
      "Upcoming classes/appointments the athlete has booked at linked Repera Business centers and sessions prescribed by their coach. Read before scheduling to avoid conflicts; an empty result does not prove free time.",
    inputSchema: z.strictObject({ days: z.number().int().min(1).max(90).default(28) }),
    annotations: { readOnlyHint: true },
  }, async ({ days }) => {
    const now = new Date();
    const until = new Date(now.getTime() + days * 86_400_000);
    const { data: clients, error: clientError } = await db.from("clients")
      .select("id,org_id").eq("user_id", ownerId).in("status", ["trial", "active", "paused"]).limit(50);
    if (clientError) throw new Error("No se pudieron consultar tus centros");
    const clientIds = (clients ?? []).map((c) => c.id as string);
    if (!clientIds.length) {
      return result({ booked: [], coach_sessions: [], linked_centers: 0, days });
    }
    const orgIds = [...new Set((clients ?? []).map((c) => c.org_id as string))];

    const [bookings, sessions, orgs] = await Promise.all([
      db.from("service_bookings").select("id,org_id,occurrence_id,status")
        .in("client_id", clientIds).eq("status", "booked").limit(300),
      db.from("professional_training_sessions")
        .select("id,org_id,scheduled_date,title,instructions,status,prescription")
        .in("client_id", clientIds).eq("status", "scheduled")
        .gte("scheduled_date", now.toISOString().slice(0, 10))
        .lte("scheduled_date", until.toISOString().slice(0, 10))
        .order("scheduled_date").limit(200),
      db.from("organizations").select("id,name").in("id", orgIds),
    ]);
    if (bookings.error || sessions.error || orgs.error) throw new Error("No se pudo leer la agenda de tus centros");
    const orgName = new Map((orgs.data ?? []).map((o) => [o.id as string, o.name as string]));

    const occurrenceIds = (bookings.data ?? []).map((b) => b.occurrence_id as string);
    const occurrences = occurrenceIds.length
      ? await db.from("service_occurrences").select("id,org_id,kind,title,starts_at,ends_at,status")
        .in("id", occurrenceIds).eq("status", "active")
        .gte("starts_at", now.toISOString()).lte("starts_at", until.toISOString())
        .order("starts_at").limit(300)
      : { data: [], error: null };
    if (occurrences.error) throw new Error("No se pudo leer la agenda de tus centros");

    return result({
      days,
      linked_centers: orgIds.length,
      booked: (occurrences.data ?? []).map((o) => ({
        occurrence_id: o.id,
        center: orgName.get(o.org_id as string) ?? null,
        kind: o.kind,
        title: o.title,
        starts_at: o.starts_at,
        ends_at: o.ends_at,
      })),
      coach_sessions: (sessions.data ?? []).map((s) => {
        const blocks = (s.prescription as { blocks?: unknown[] } | null)?.blocks;
        return {
          id: s.id,
          center: orgName.get(s.org_id as string) ?? null,
          scheduled_date: s.scheduled_date,
          title: s.title,
          instructions: typeof s.instructions === "string" ? s.instructions.slice(0, 600) : "",
          prescribed_blocks: Array.isArray(blocks) ? blocks.length : 0,
        };
      }),
      caveat:
        "Center-managed data is read-only here. Do not cancel, book or edit center sessions; ask the athlete to use the Repera app. Coach prescriptions take precedence over AI proposals on the same day.",
    });
  });
}
