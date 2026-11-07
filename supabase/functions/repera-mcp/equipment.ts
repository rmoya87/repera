/** Material constraints: OR between configurations, AND within each configuration.
 * Missing/null options preserve legacy AND semantics; explicit invalid/empty options
 * are unknown, never interpreted as no equipment. Generic machines cannot certify
 * a specific apparatus. This is availability, not exercise equivalence or safety.
 */
export type EquipmentMetadata = {
  required_equipment?: unknown;
  required_equipment_options?: unknown;
};
export type EquipmentStatus =
  | "pendiente_confirmacion"
  | "sin_material"
  | "disponible_declarado"
  | "no_declarado";
function normalized(v: string) {
  return v.trim().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
}
const gearAliases: Record<string, string> = {
  "barra": "barbell",
  "barra olimpica": "barbell",
  "barbell": "barbell",
  "mancuernas": "dumbbells",
  "mancuerna": "dumbbells",
  "dumbbells": "dumbbells",
  "gomas": "resistance_band",
  "bandas": "resistance_band",
  "bandas elasticas": "resistance_band",
  "resistance bands": "resistance_band",
  "resistance_band": "resistance_band",
  "anillas": "gymnastic_rings",
  "rings": "gymnastic_rings",
  "cajon": "plyometric_box",
  "cajon pliometrico": "plyometric_box",
  "box": "plyometric_box",
  "kettlebell": "kettlebell",
  "pesa rusa": "kettlebell",
  "comba": "jump_rope",
  "cuerda de saltar": "jump_rope",
  "jump_rope": "jump_rope",
  "peso corporal": "bodyweight",
  "sin material": "bodyweight",
  "bodyweight": "bodyweight",
  "disco": "weight_plate",
  "weight_plate": "weight_plate",
  "polea": "cable_machine",
  "cable_machine": "cable_machine",
  "balon medicinal": "medicine_ball",
  "medicine_ball": "medicine_ball",
  "pared": "wall",
  "wall": "wall",
  "banco": "bench",
  "bench": "bench",
  "barra de dominadas": "pullup_bar",
  "pullup_bar": "pullup_bar",
  "rack": "rack",
  "jaula": "rack",
  "power rack": "rack",
  "trineo": "sled",
  "sled": "sled",
  "saco": "sandbag",
  "sandbag": "sandbag",
  "air bike": "air_bike",
  "air_bike": "air_bike",
  "echo bike": "echo_bike",
  "echo_bike": "echo_bike",
  "banda": "resistance_band",
  "banda elastica": "resistance_band",
  "pica": "pvc_pipe",
  "pvc": "pvc_pipe",
  "pvc_pipe": "pvc_pipe",
  "rodillo": "foam_roller",
  "foam roller": "foam_roller",
  "foam_roller": "foam_roller",
  "marco de puerta": "door_frame",
  "door_frame": "door_frame",
  "maquina de dominadas asistidas": "assisted_pullup_machine",
  "maquina asistida de dominadas": "assisted_pullup_machine",
  "assisted pull-up machine": "assisted_pullup_machine",
  "assisted_pullup_machine": "assisted_pullup_machine",
  "bicicleta estatica": "stationary_bike",
  "stationary_bike": "stationary_bike",
};
export function canonicalGear(v: string): string {
  return gearAliases[normalized(v)] ?? normalized(v);
}
const token = /^[a-z][a-z0-9_]{1,79}$/;
function validGroup(value: unknown): value is string[] {
  return Array.isArray(value) && value.length > 0 && value.length <= 12 &&
    value.every((g) => typeof g === "string" && token.test(g));
}
export function equipmentConfigurations(
  meta: EquipmentMetadata,
): string[][] | null {
  const options = meta.required_equipment_options;
  if (options !== undefined && options !== null) {
    if (
      !Array.isArray(options) || options.length === 0 || options.length > 12 ||
      !options.every(validGroup)
    ) return null;
    return options;
  }
  return validGroup(meta.required_equipment) ? [meta.required_equipment] : null;
}
export function equipmentStatus(
  meta: EquipmentMetadata,
  available?: string[],
): EquipmentStatus {
  const groups = equipmentConfigurations(meta);
  if (!groups) return "pendiente_confirmacion";
  // A known bodyweight branch can be done without declaring any equipment.
  if (groups.some((group) => group.every((g) => g === "bodyweight"))) {
    return "sin_material";
  }
  const concrete = groups.filter((group) =>
    !group.includes("gym_machine_unspecified")
  );
  if (concrete.length === 0 || available == null) {
    return "pendiente_confirmacion";
  }
  const declared = new Set(available.map(canonicalGear));
  return concrete.some((group) =>
      group.every((g) => g === "bodyweight" || declared.has(g))
    )
    ? "disponible_declarado"
    : "no_declarado";
}
export function hasDeclaredEquipment(
  meta: EquipmentMetadata,
  available: string[],
): boolean {
  const status = equipmentStatus(meta, available);
  return status === "disponible_declarado" || status === "sin_material";
}
