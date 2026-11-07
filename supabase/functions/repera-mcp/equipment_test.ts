import {
  canonicalGear,
  equipmentConfigurations,
  equipmentStatus,
  hasDeclaredEquipment,
} from "./equipment.ts";
function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
const wrist = {
  required_equipment: ["barbell"],
  required_equipment_options: [["barbell"], ["dumbbells"]],
};
const assisted = {
  required_equipment: ["gym_machine_unspecified"],
  required_equipment_options: [["assisted_pullup_machine"], [
    "pullup_bar",
    "resistance_band",
  ]],
};
Deno.test("wrist accepts either complete option, not missing gear", () => {
  for (
    const gear of [["barbell"], ["dumbbells"], ["barra"], ["mancuernas"], [
      "barbell",
      "dumbbells",
    ]]
  ) {
    assert(hasDeclaredEquipment(wrist, gear), JSON.stringify(gear));
  }
  for (const gear of [[], ["bench"], ["gym_machine_unspecified"]]) {
    assert(!hasDeclaredEquipment(wrist, gear));
  }
});
Deno.test("assisted pull-up requires a specific machine OR BOTH bar and band", () => {
  for (
    const gear of [
      ["assisted_pullup_machine"],
      ["máquina de dominadas asistidas"],
      ["pullup_bar", "resistance_band"],
      ["barra de dominadas", "banda"],
    ]
  ) {
    assert(hasDeclaredEquipment(assisted, gear), JSON.stringify(gear));
  }
  for (
    const gear of [
      [],
      ["pullup_bar"],
      ["resistance_band"],
      ["gym_machine_unspecified"],
      ["máquina"],
      ["barbell", "resistance_band"],
    ]
  ) {
    assert(!hasDeclaredEquipment(assisted, gear), JSON.stringify(gear));
  }
  assert(canonicalGear("máquina") !== "assisted_pullup_machine");
});
Deno.test("absent/null options preserve legacy AND; no silent OR", () => {
  for (
    const meta of [{ required_equipment: ["barbell", "bench"] }, {
      required_equipment: ["barbell", "bench"],
      required_equipment_options: null,
    }]
  ) {
    assert(hasDeclaredEquipment(meta, ["barbell", "bench"]));
    assert(!hasDeclaredEquipment(meta, ["barbell"]));
    assert(!hasDeclaredEquipment(meta, ["bench"]));
  }
});
Deno.test("unknown/empty/malformed constraints fail closed without legacy fallback", () => {
  for (
    const required_equipment_options of [
      [],
      "barbell",
      [["barbell"], []],
      [["barbell"], [null]],
      [["Barra"]],
      [["barbell OR dumbbells"]],
      Array(13).fill(["barbell"]),
      [Array(13).fill("barbell")],
      {},
    ]
  ) {
    const meta = {
      required_equipment: ["barbell"],
      required_equipment_options,
    };
    assert(
      equipmentConfigurations(meta) === null,
      JSON.stringify(required_equipment_options),
    );
    assert(equipmentStatus(meta, ["barbell"]) === "pendiente_confirmacion");
    assert(!hasDeclaredEquipment(meta, ["barbell"]));
  }
  for (const required_equipment of [[], undefined, null, "barbell", [42]]) {
    assert(!hasDeclaredEquipment({ required_equipment }, ["barbell"]));
  }
});
Deno.test("status and candidate gate agree; generic machines never certify availability", () => {
  for (
    const meta of [wrist, assisted, {
      required_equipment: ["gym_machine_unspecified"],
    }]
  ) {
    assert(equipmentStatus(meta) === "pendiente_confirmacion");
    for (
      const available of [
        [],
        ["dumbbells"],
        ["pullup_bar", "resistance_band"],
        ["gym_machine_unspecified"],
      ]
    ) {
      const status = equipmentStatus(meta, available);
      assert(
        hasDeclaredEquipment(meta, available) ===
          (status === "disponible_declarado" || status === "sin_material"),
      );
    }
  }
  assert(
    equipmentStatus({ required_equipment: ["gym_machine_unspecified"] }, [
      "gym_machine_unspecified",
    ]) === "pendiente_confirmacion",
  );
  assert(equipmentStatus(wrist, []) === "no_declarado");
});
Deno.test("bodyweight is explicit, not inferred from an empty list", () => {
  assert(
    equipmentStatus({ required_equipment: ["bodyweight"] }) === "sin_material",
  );
  assert(
    hasDeclaredEquipment({
      required_equipment_options: [["bodyweight"], ["dumbbells"]],
    }, []),
  );
  assert(!hasDeclaredEquipment({ required_equipment: [] }, []));
  assert(
    !hasDeclaredEquipment({
      required_equipment_options: [["bodyweight", "pullup_bar"]],
    }, []),
  );
});
