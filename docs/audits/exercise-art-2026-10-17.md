# Inventario de arte Gymbro — 2026-10-17

> Estado: **auditoría estructural completa; validación visual parcial**. WARN significa que **NO** se ha declarado válido el arte; FAIL requiere corrección confirmada. No se han regenerado ni exportado JPG desde este entorno.

## Alcance y resultado verificable

- 188 ejercicios con `nameMap`; 291 JPG full y 291 JPG thumb emparejados por nombre.
- 188 hero presentes; 0 full sin thumb; 0 thumbs sin full.
- Dimensiones y calidad visual de todos los JPG: **no certificadas**. El script `scripts/audit_exercise_art.py` las comprueba en checkout con Pillow y produce hojas de contacto.
- Fallbacks mezclados desactivados hasta contar con secuencias verificadas; los holds se muestran con hero.

## Tabla por ejercicio (188)

| Ejercicio | Stem (hero) | Veredicto | Problema | Acción |
|---|---|---|---|---|
| Press banca | `art_press_banca` | WARN | Carrusel 2 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Press banca inclinada | `art_press_inclinado` | WARN | Carrusel 2 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Press mancuernas | `art_press_mancuernas` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Press banca declinado | `art_press_declinado` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Press cerrado | `art_press_cerrado` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Aperturas | `art_aperturas` | WARN | Carrusel 2 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Cruce de poleas | `art_cruce_poleas` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Pullover | `art_pullover` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Fondos | `art_fondos` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Fondos en banco | `art_fondos_banco` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Dominadas | `art_dominadas` | WARN | Carrusel 2 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Remo invertido | `art_remo_invertido` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Jalón al pecho | `art_jalon` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Remo sentado | `art_remo_sentado` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Remo con barra | `art_remo_barra` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Remo mancuerna | `art_remo_mancuerna` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Peso muerto | `art_peso_muerto` | WARN | Carrusel 2 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Peso muerto sumo | `art_sumo` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Peso muerto rumano | `art_rdl` | WARN | Cambio de cámara entre `_1` y `_2` | Unificar cámara si se regenera |
| Buenos días | `art_buenos_dias` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Curl femoral | `art_curl_femoral` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Sentadilla | `art_sentadilla` | WARN | Carrusel 2 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Sentadilla frontal | `art_sentadilla_frontal` | WARN | Carrusel 2 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Hack squat | `art_hack_squat` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Prensa | `art_prensa` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Extensión de cuádriceps | `art_extension_cuad` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Zancadas | `art_zancadas` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Sentadilla búlgara | `art_bulgara` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Paso lateral con banda | `art_paso_banda` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Elevación de gemelos | `art_gemelos` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Press militar | `art_press_militar` | WARN | Carrusel 2 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Remo al mentón | `art_remo_menton` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Elevaciones laterales | `art_elevaciones_laterales` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Elevaciones frontales | `art_elev_frontales` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Pájaros | `art_pajaros` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Face pull | `art_face_pull` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Curl barra | `art_curl_barra` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Curl mancuernas | `art_curl_mancuernas` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Curl martillo | `art_curl_martillo` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Curl predicador | `art_curl_predicador` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Extensión tríceps polea | `art_triceps_polea` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Press francés | `art_press_frances` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Plancha | `art_plancha` | WARN | Hero presente; sin carrusel propio verificado | Conservar solo hero; comprobar estilo |
| Crunch | `art_crunch` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Elevación de piernas | `art_elev_piernas` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Hip thrust | `art_hip_thrust` | WARN | Carrusel 2 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Cinta / carrera | `art_cardio` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Bici estática | `art_bici` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Remo máquina | `art_remo_erg` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Farmer walk | `art_farmer` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Ab wheel | `art_ab_wheel` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Press Arnold | `art_arnold` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Cargada | `art_cf_cargada` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Cargada de potencia | `art_cf_power_clean` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Cargada colgante | `art_cf_hang_clean` | FAIL | Hero y pasos con camiseta; `_2` con sombra aérea | Regenerar hero y `art_cf_hang_clean_1…3` |
| Arrancada | `art_cf_arrancada` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Arrancada de potencia | `art_cf_power_snatch` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Cargada y envión | `art_cf_cj` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Push press | `art_cf_push_press` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Push jerk | `art_cf_push_jerk` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Split jerk | `art_cf_split_jerk` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Overhead squat | `art_cf_ohs` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Thruster | `art_cf_thruster` | FAIL | `_3`: termina con mancuernas en lugar de barra | Regenerar `art_cf_thruster_3` y reactivar carrusel |
| Cluster | `art_cf_cluster` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Sumo high pull | `art_cf_sumo_hp` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Burpee | `art_cf_burpee` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Burpee al cajón | `art_cf_burpee_box` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Salto al cajón | `art_cf_box_jump` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Step-up al cajón | `art_cf_step_up` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Muscle-up barra | `art_cf_mu_bar` | FAIL | `_3`: soporte sobre barra no representado | Regenerar `art_cf_mu_bar_3` sin sombra |
| Muscle-up anillas | `art_cf_mu_rings` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Toes to bar | `art_cf_ttb` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Knees to elbows | `art_cf_kte` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Chest to bar | `art_cf_ctb` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| HSPU | `art_cf_hspu` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Handstand walk | `art_cf_hsw` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Wall walk | `art_cf_wall_walk` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Fondos en anillas | `art_cf_ring_dip` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Pistol squat | `art_cf_pistol` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Rope climb | `art_cf_rope` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Hollow rock | `art_cf_hollow` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| GHD sit-up | `art_cf_ghd` | WARN | Posible camiseta en hero y pasos | Confirmar visualmente y rehacer torso |
| Sit-up | `art_cf_situp` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| V-up | `art_cf_vup` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| L-sit | `art_cf_lsit` | WARN | Hero presente; sin carrusel propio verificado | Conservar solo hero; comprobar estilo |
| Swing kettlebell | `art_cf_kb_swing` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Swing americano | `art_cf_kb_amer` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Snatch kettlebell | `art_cf_kb_snatch` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Turkish get-up | `art_cf_tgu` | WARN | Cambia vista entre tumbado y de pie | Validar perspectiva y lateralidad |
| Wall ball | `art_cf_wall_ball` | WARN | Frame `_3` muestra recepción alta | Revalidar pose y pie de foto |
| Ball slam | `art_cf_slam` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Devil press | `art_cf_devil` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Man maker | `art_cf_manmaker` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Dobles de comba | `art_cf_du` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Simples de comba | `art_cf_su` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Air bike | `art_cf_airbike` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| SkiErg | `art_cf_skierg` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Sled push | `art_cf_sled_push` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Sled pull | `art_cf_sled_pull` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Bear crawl | `art_cf_bear` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Broad jump | `art_cf_broad` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Walking lunge | `art_cf_walk_lunge` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Front rack lunge | `art_cf_fr_lunge` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Bar facing burpee | `art_cf_bfb` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Strict press | `art_cf_strict_press` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Hang power snatch | `art_cf_hps` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Hang power clean | `art_cf_hpc` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Arrancada colgante | `art_hl_hang_snatch` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Arrancada colgante completa | `art_hl_hang_sq_snatch` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Arrancada muscular | `art_hl_muscle_snatch` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Arrancada desde bloques | `art_hl_block_snatch` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Arrancada con pausa | `art_hl_pause_snatch` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Balance de arrancada | `art_hl_snatch_bal` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Drop snatch | `art_hl_drop_snatch` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Tall snatch | `art_hl_tall_snatch` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Arrancada en split | `art_hl_split_snatch` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Tirón de arrancada | `art_hl_snatch_pull` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Peso muerto agarre arrancada | `art_hl_snatch_dl` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Cargada colgante completa | `art_hl_hang_sq_clean` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Cargada muscular | `art_hl_muscle_clean` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Cargada desde bloques | `art_hl_block_clean` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Cargada con pausa | `art_hl_pause_clean` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Tall clean | `art_hl_tall_clean` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Tirón de cargada | `art_hl_clean_pull` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Cargada y press | `art_hl_clean_press` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Power jerk | `art_hl_power_jerk` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Balance de envión | `art_hl_jerk_bal` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Press detrás de nuca | `art_hl_btn_press` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Envión detrás de nuca | `art_hl_btn_jerk` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Sots press | `art_hl_sots` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Sentadilla frontal con pausa | `art_hl_pause_fs` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Dominadas estrictas | `art_gy_strict_pu` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Dominadas kipping | `art_gy_kip_pu` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Dominadas butterfly | `art_gy_bfly_pu` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Dominadas supinas | `art_gy_chinup` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Dominadas en anillas | `art_gy_ring_pu` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Remo en anillas | `art_gy_ring_row` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Archer pull-up | `art_gy_archer` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Muscle-up estricto barra | `art_gy_strict_mubar` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Muscle-up estricto anillas | `art_gy_strict_muring` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Pull-over barra | `art_gy_pullover` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Toes to bar estrictos | `art_gy_strict_ttb` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Toes to rings | `art_gy_ttr` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Hip to bar | `art_gy_htb` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Kip swing | `art_gy_kip_swing` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| HSPU deficit | `art_gy_hspu_def` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| HSPU libre | `art_gy_hspu_free` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Pike push-up | `art_gy_pike_pu` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Handstand hold | `art_gy_hs_hold` | WARN | Hero presente; sin carrusel propio verificado | Conservar solo hero; comprobar estilo |
| Press to handstand | `art_gy_press_hs` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Fondos en paralelas | `art_gy_pb_dip` | WARN | Cambio de cámara entre `_1` y `_2` | Unificar cámara si se regenera |
| Soporte en anillas | `art_gy_ring_sup` | WARN | Hero presente; sin carrusel propio verificado | Conservar solo hero; comprobar estilo |
| False grip hang | `art_gy_false_grip` | WARN | Hero presente; sin carrusel propio verificado | Conservar solo hero; comprobar estilo |
| Skin the cat | `art_gy_skin_cat` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| German hang | `art_gy_german` | WARN | Hero presente; sin carrusel propio verificado | Conservar solo hero; comprobar estilo |
| Front lever tuck | `art_gy_front_lev` | WARN | Hero presente; sin carrusel propio verificado | Conservar solo hero; comprobar estilo |
| Back lever tuck | `art_gy_back_lev` | WARN | Hero presente; sin carrusel propio verificado | Conservar solo hero; comprobar estilo |
| Planche tuck | `art_gy_planche` | WARN | Hero presente; sin carrusel propio verificado | Conservar solo hero; comprobar estilo |
| V-sit | `art_gy_vsit` | WARN | Hero presente; sin carrusel propio verificado | Conservar solo hero; comprobar estilo |
| Hollow hold | `art_gy_hollow_hold` | WARN | Hero presente; sin carrusel propio verificado | Conservar solo hero; comprobar estilo |
| Arch hold | `art_gy_arch` | WARN | Hero presente; sin carrusel propio verificado | Conservar solo hero; comprobar estilo |
| Candlestick | `art_gy_candle` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Shrimp squat | `art_gy_shrimp` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Cossack squat | `art_gy_cossack` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Air squat | `art_gy_air_squat` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Jumping squat | `art_gy_jump_squat` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Jumping lunge | `art_gy_jump_lunge` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| GHD back extension | `art_gy_ghd_back` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Rope climb legless | `art_gy_rope_ll` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Pegboard | `art_gy_pegboard` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Thruster mancuernas | `art_cf_thruster_db` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Thruster kettlebell | `art_cf_thruster_kb` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Ground to overhead | `art_cf_gto` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Plate ground to overhead | `art_cf_plate_gto` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Burpee pull-up | `art_cf_burpee_pu` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Box jump over | `art_cf_bjo` | WARN | Carrusel 3 pasos: sin QA visual completa | Inspeccionar hero, fases, sombras y cámara |
| Clean kettlebell | `art_cf_kb_clean` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Goblet squat | `art_cf_goblet` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Snatch mancuerna | `art_cf_db_snatch` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Clean mancuerna | `art_cf_db_clean` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Medball clean | `art_cf_mb_clean` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Sandbag clean | `art_cf_sb_clean` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Sandbag over shoulder | `art_cf_sb_os` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Yoke carry | `art_cf_yoke` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Triples de comba | `art_cf_tu` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Echo bike | `art_cf_echo` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Shuttle run | `art_cf_shuttle` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |
| Farmer carry | `art_cf_farmer_carry` | WARN | Hero presente; sin carrusel propio verificado | Revisar hero; crear fases propias si el movimiento las necesita |

## Stems por regenerar (confirmados)

- `art_cf_thruster_3`: barra olímpica en overhead; mismo personaje que `_1/_2`.
- `art_cf_mu_bar_3`: soporte sobre la misma barra, pies suspendidos, sin sombra.
- `art_cf_hang_clean`, `art_cf_hang_clean_1`, `_2`, `_3`: eliminar camiseta y shadow de `_2`.

## WARN visuales relevantes

- `art_cf_wall_ball_3`: recepción con manos altas frente a diana; captions actualizadas; revalidar perspectiva.
- `art_gy_pb_dip_2`: cámara cambia respecto al primer paso.
- `art_rdl_2`: cámara pasa de frontal a lateral.
- `art_cf_tgu_3`: cámara varía al llegar a posición erguida.
- `art_cf_ghd`: posible camiseta en hero y pasos.

## Instrucciones actualizadas

Se revisaron 19 frases de 7 ejercicios: Peso muerto rumano, Fondos en paralelas, Thruster, Muscle-up barra, Wall ball, Turkish get-up y GHD sit-up.
En el código se corrigieron las dos diferencias confirmadas entre el número de pasos y el número de frases. Consultar el diff del PR para cada texto.

## Ejecución local recomendada

```bash
.venv-art/bin/python scripts/audit_exercise_art.py --contact-sheets --strict
```

Genera `art-audit/exercise-art-audit.csv` y `art-audit/sheets/` para la inspección de todos los recursos. Los WARN requieren confirmación humana de las poses; un CSV sin errores de formato no equivale a un OK visual.
