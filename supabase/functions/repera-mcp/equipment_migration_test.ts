import { PGlite } from "npm:@electric-sql/pglite@0.5.15";
Deno.test("equipment migration validates OR groups and changes only two scoped options", async () => {
  const db = new PGlite();
  try {
    await db.exec(`CREATE TABLE public.training_exercise_metadata (
 catalog_key text primary key, required_equipment text[] not null,
 equipment text[], primary_muscles text[], alternatives text[]);
 INSERT INTO public.training_exercise_metadata VALUES
 ('catalog:Curl de muñeca',ARRAY['barbell'],ARRAY['Barra o mancuernas'],ARRAY['forearms'],ARRAY['keep']),
 ('catalog:Dominadas asistidas',ARRAY['gym_machine_unspecified'],ARRAY['Máquina asistida o barra de dominadas con banda'],ARRAY['upper-back'],ARRAY['keep']),
 ('catalog:AND control',ARRAY['barbell','bench'],ARRAY['keep'],ARRAY['keep'],ARRAY['keep']);`);
    const before = (await db.query<Record<string, unknown>>(
      "SELECT * FROM public.training_exercise_metadata ORDER BY catalog_key",
    )).rows;
    await db.exec(
      Deno.readTextFileSync(
        new URL(
          "../../migrations/20261107080000_equipment_alternative_configurations.sql",
          import.meta.url,
        ),
      ),
    );
    const after = (await db.query<Record<string, unknown>>(
      "SELECT * FROM public.training_exercise_metadata ORDER BY catalog_key",
    )).rows;
    for (let i = 0; i < after.length; i++) {
      const { required_equipment_options, ...unchanged } = after[i];
      if (JSON.stringify(unchanged) !== JSON.stringify(before[i])) {
        throw Error("unrelated field change");
      }
    }
    const vals: [string, boolean][] = [
      ['[["barbell"],["dumbbells"]]', true],
      ['[["pullup_bar","resistance_band"]]', true],
      ["null", false],
      ["[]", false],
      ["[[]]", false],
      ['[["barbell"],[]]', false],
      ['["barbell"]', false],
      ["[[42]]", false],
      ["{}", false],
      ['[["Barra"]]', false],
      ['[["barbell or dumbbells"]]', false],
    ];
    for (const [value, expected] of vals) {
      const { rows } = await db.query<{ valid: boolean }>(
        "SELECT public.valid_equipment_options($1::jsonb) AS valid",
        [value],
      );
      if (rows[0]?.valid !== expected) throw Error("validation " + value);
    }
    const { rows } = await db.query<{ valid: boolean }>(
      "SELECT public.valid_equipment_options(NULL::jsonb) AS valid",
    );
    if (!rows[0]?.valid) throw Error("SQL NULL must preserve legacy");
    let rejected = false;
    try {
      await db.exec(
        `UPDATE public.training_exercise_metadata SET required_equipment_options='[[]]'::jsonb`,
      );
    } catch {
      rejected = true;
    }
    if (!rejected) throw Error("constraint did not enforce");
    if (
      JSON.stringify(
        after.find((r) => r.catalog_key === "catalog:Curl de muñeca")
          ?.required_equipment_options,
      ) !== '[["barbell"],["dumbbells"]]'
    ) throw Error("wrist seed");
    if (
      after.find((r) => r.catalog_key === "catalog:AND control")
        ?.required_equipment_options !== null
    ) throw Error("AND changed");
    if (
      JSON.stringify(
        after.find((r) => r.catalog_key === "catalog:Dominadas asistidas")
          ?.required_equipment_options,
      ) !== '[["assisted_pullup_machine"],["pullup_bar","resistance_band"]]'
    ) throw Error("assisted seed");
  } finally {
    await db.close();
  }
});
