import { isWriteTool, quotaRules, toolCalls } from "./rate-limit.ts";
import { deterministicUuid, samePayload } from "./idempotency.ts";

function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
const owner = "00000000-0000-0000-0000-000000000001";
const token = "00000000-0000-0000-0000-000000000002";

Deno.test("extracts tool names from single and batched JSON-RPC", () => {
  assert(toolCalls("not json").length === 0);
  assert(toolCalls(JSON.stringify({ method: "tools/list" })).length === 0);
  const batch = toolCalls(JSON.stringify([
    { method: "tools/call", params: { name: "create_workout" } },
    { method: "tools/call", params: { name: "get_workout_history" } },
    { method: "tools/call", params: { name: "../../evil" } },
  ]));
  assert(JSON.stringify(batch) === JSON.stringify(["create_workout", "get_workout_history", "unknown"]));
});

Deno.test("write tools are classified by verb", () => {
  for (const name of ["create_training_plan", "update_workout", "delete_custom_exercise", "archive_ai_training_plan",
    "restore_training_program", "set_training_preferences", "adjust_training_program"]) assert(isWriteTool(name), name);
  for (const name of ["get_workout_history", "search_training_exercises", "review_training_program"]) {
    assert(!isWriteTool(name), name);
  }
});

Deno.test("every request is charged per token and owner; batches cost per call", () => {
  const plain = quotaRules(owner, token, []);
  assert(plain.length === 2 && plain.every((r) => r.cost === 1));
  const rules = quotaRules(owner, token, ["create_workout", "create_workout", "get_workout_history"]);
  const byKey = new Map(rules.map((r) => [r.key, r]));
  assert(byKey.get(`token:${token}:req:60`)?.cost === 3);
  assert(byKey.get(`owner:${owner}:write:60`)?.cost === 2);
  assert(byKey.get(`token:${token}:tool:create_workout:60`)?.limit === 15);
  assert(byKey.get(`token:${token}:tool:get_workout_history:60`)?.limit === 40);
  assert(rules.every((r) => r.key.length <= 200 && r.windowSeconds <= 86_400));
});

Deno.test("idempotency ids are stable per owner/scope and payload comparison ignores key order", async () => {
  const key = "11111111-1111-4111-8111-111111111111";
  const a = await deterministicUuid(owner, key);
  assert(a === await deterministicUuid(owner, key));
  assert(a !== await deterministicUuid(token, key));
  assert(a !== await deterministicUuid(owner, key, "program"));
  assert(/^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(a));
  assert(samePayload({ a: 1, b: [{ x: 1, y: 2 }] }, { b: [{ y: 2, x: 1 }], a: 1 }));
  assert(!samePayload({ a: 1 }, { a: 2 }));
});
