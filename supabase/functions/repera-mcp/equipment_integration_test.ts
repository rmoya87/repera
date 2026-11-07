import { registerCoachTools } from "./coach.ts";
import { registerDisciplinePlanningTools } from "./disciplines.ts";
function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
// Read-only in-memory PostgREST fixture. Execute registered production handlers,
// not a reimplementation of the filter. No real accounts or remote DB writes.
const names = [
  { catalog_key: "origin", name: "Origin" },
  { catalog_key: "wrist", name: "Curl de muñeca" },
  { catalog_key: "assisted", name: "Dominadas asistidas" },
  { catalog_key: "bench", name: "Press banca" },
  { catalog_key: "wrong-muscle", name: "Other" },
  { catalog_key: "unknown-joints", name: "Unknown" },
  { catalog_key: "warmup", name: "Gato-vaca" },
];
const meta = [
  { catalog_key: "origin", primary_muscles: ["forearms"] },
  {
    catalog_key: "wrist",
    primary_muscles: ["forearms"],
    joint_demands: ["wrist"],
    required_equipment: ["barbell"],
    required_equipment_options: [["barbell"], ["dumbbells"]],
  },
  {
    catalog_key: "assisted",
    primary_muscles: ["forearms"],
    joint_demands: ["shoulder"],
    required_equipment: ["gym_machine_unspecified"],
    required_equipment_options: [["assisted_pullup_machine"], [
      "pullup_bar",
      "resistance_band",
    ]],
  },
  {
    catalog_key: "bench",
    primary_muscles: ["forearms"],
    joint_demands: ["shoulder"],
    required_equipment: ["barbell", "bench"],
  },
  {
    catalog_key: "wrong-muscle",
    primary_muscles: ["quads"],
    joint_demands: ["knee"],
    required_equipment: ["dumbbells"],
  },
  {
    catalog_key: "unknown-joints",
    primary_muscles: ["forearms"],
    joint_demands: [],
    required_equipment: ["dumbbells"],
  },
  // Fixture deliberately associates warmup name with OR to test the actual path.
  {
    catalog_key: "warmup",
    primary_muscles: [],
    required_equipment: ["barbell"],
    required_equipment_options: [["barbell"], ["dumbbells"]],
  },
];
function setup() {
  const handlers = new Map<string, (args: any) => Promise<any>>();
  const server = {
    registerTool(name: string, _schema: unknown, handler: any) {
      handlers.set(name, handler);
    },
  };
  const db = {
    from(table: string) {
      let rows = structuredClone(
        table === "training_exercise_metadata" ? meta : names,
      ) as any[];
      const query = {
        select(_fields: string) {
          return query;
        },
        eq(field: string, value: unknown) {
          rows = rows.filter((r) => r[field] === value);
          return query;
        },
        in(field: string, values: unknown[]) {
          rows = rows.filter((r) => values.includes(r[field]));
          return query;
        },
        limit(count: number) {
          rows = rows.slice(0, count);
          return query;
        },
        maybeSingle() {
          return Promise.resolve({ data: rows[0] ?? null, error: null });
        },
        then(resolve: any, reject: any) {
          return Promise.resolve({ data: rows, error: null }).then(
            resolve,
            reject,
          );
        },
      };
      return query;
    },
  };
  registerCoachTools(server as any, db as any, "owner", "token", false);
  registerDisciplinePlanningTools(server as any, db as any, "owner");
  return async (name: string, args: any) =>
    JSON.parse((await handlers.get(name)!(args)).content[0].text);
}
Deno.test("production equipment candidates use OR/AND and keep muscle/joint exclusions", async () => {
  const call = setup();
  const find = async (gear: string[], avoid: string[] = []) =>
    (await call("find_equipment_alternatives", {
      catalogKey: "origin",
      availableEquipment: gear,
      avoidJointDemands: avoid,
      limit: 15,
    })).candidates.map((x: any) => x.catalog_key);
  const dumbbells = await find(["dumbbells"]);
  assert(dumbbells.includes("wrist"));
  assert(!dumbbells.includes("wrong-muscle") && !dumbbells.includes("origin"));
  assert(!(await find(["dumbbells"], ["wrist"])).includes("wrist"));
  assert(!(await find(["dumbbells"], ["knee"])).includes("unknown-joints"));
  assert((await find(["pullup_bar", "resistance_band"])).includes("assisted"));
  assert(!(await find(["pullup_bar"])).includes("assisted"));
  assert(!(await find(["gym_machine_unspecified"])).includes("assisted"));
  assert((await find(["assisted_pullup_machine"])).includes("assisted"));
  assert(!(await find(["barbell"])).includes("bench"));
  assert((await find(["barbell", "bench"])).includes("bench"));
});
Deno.test("production warmup candidate uses same OR status and returns configurations", async () => {
  const call = setup();
  for (
    const [availableEquipment, expected] of [
      [["dumbbells"], "disponible_declarado"],
      [[], "no_declarado"],
      [undefined, "pendiente_confirmacion"],
    ] as const
  ) {
    const output = await call("get_warmup_prescription_reference", {
      mainDiscipline: "strength",
      mainMovements: [],
      availableEquipment,
    });
    const row = output.candidates.find((x: any) => x.catalog_key === "warmup");
    assert(row.equipment_status === expected);
    assert(
      JSON.stringify(row.required_equipment_options) ===
        '[["barbell"],["dumbbells"]]',
    );
  }
});
