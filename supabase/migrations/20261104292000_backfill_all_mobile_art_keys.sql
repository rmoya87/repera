-- Full OTA art_keys backfill from packaged stems (nameMap). 2026-11-04.

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_9090_lift_1','art_mv_9090_lift_2']::text[]
WHERE catalog_key = 'catalog:90/90 con elevación de rodilla' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_9090_lift_1','art_mv_9090_lift_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_9090_fold']::text[]
WHERE catalog_key = 'catalog:90/90 con inclinación frontal' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_9090_fold']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_9090_1','art_mv_9090_2']::text[]
WHERE catalog_key = 'catalog:90/90 de cadera' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_9090_1','art_mv_9090_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_situp']::text[]
WHERE catalog_key = 'catalog:Ab Mat Sit-Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_situp']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_ab_wheel']::text[]
WHERE catalog_key = 'catalog:Ab wheel' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_ab_wheel']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_prensa']::text[]
WHERE catalog_key = 'catalog:Abducción de cadera en máquina' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_prensa']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_femoral']::text[]
WHERE catalog_key = 'catalog:Aducción de cadera en máquina' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_femoral']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_airbike']::text[]
WHERE catalog_key = 'catalog:Air bike' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_airbike']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Air squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_prensa']::text[]
WHERE catalog_key = 'catalog:Almeja con banda' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_prensa']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Alternating Dumbbell Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_kb_swing_1','art_cf_kb_swing_2','art_cf_kb_swing_3']::text[]
WHERE catalog_key = 'catalog:American Kettlebell Swing' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_kb_swing_1','art_cf_kb_swing_2','art_cf_kb_swing_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_aperturas_1','art_aperturas_2']::text[]
WHERE catalog_key = 'catalog:Aperturas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_aperturas_1','art_aperturas_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_pajaros']::text[]
WHERE catalog_key = 'catalog:Aperturas con banda' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_pajaros']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_arch']::text[]
WHERE catalog_key = 'catalog:Arch hold' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_arch']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_archer']::text[]
WHERE catalog_key = 'catalog:Archer pull-up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_archer']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_arrancada_1','art_cf_arrancada_2','art_cf_arrancada_3']::text[]
WHERE catalog_key = 'catalog:Arrancada' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_arrancada_1','art_cf_arrancada_2','art_cf_arrancada_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_hang_snatch_1','art_hl_hang_snatch_2','art_hl_hang_snatch_3']::text[]
WHERE catalog_key = 'catalog:Arrancada colgante' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_hang_snatch_1','art_hl_hang_snatch_2','art_hl_hang_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_hang_sq_snatch_1','art_hl_hang_sq_snatch_2','art_hl_hang_sq_snatch_3']::text[]
WHERE catalog_key = 'catalog:Arrancada colgante completa' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_hang_sq_snatch_1','art_hl_hang_sq_snatch_2','art_hl_hang_sq_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_pause_snatch_1','art_hl_pause_snatch_2','art_hl_pause_snatch_3']::text[]
WHERE catalog_key = 'catalog:Arrancada con pausa' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_pause_snatch_1','art_hl_pause_snatch_2','art_hl_pause_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Arrancada de potencia' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_block_power_snatch']::text[]
WHERE catalog_key = 'catalog:Arrancada de potencia desde bloques' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_block_power_snatch']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_block_snatch_1','art_hl_block_snatch_2','art_hl_block_snatch_3']::text[]
WHERE catalog_key = 'catalog:Arrancada desde bloques' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_block_snatch_1','art_hl_block_snatch_2','art_hl_block_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_split_snatch_1','art_hl_split_snatch_2','art_hl_split_snatch_3']::text[]
WHERE catalog_key = 'catalog:Arrancada en split' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_split_snatch_1','art_hl_split_snatch_2','art_hl_split_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_muscle_snatch_1','art_hl_muscle_snatch_2','art_hl_muscle_snatch_3']::text[]
WHERE catalog_key = 'catalog:Arrancada muscular' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_muscle_snatch_1','art_hl_muscle_snatch_2','art_hl_muscle_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]
WHERE catalog_key = 'catalog:Atlas Stone Over Shoulder' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]
WHERE catalog_key = 'catalog:Axle Deadlift' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_press']::text[]
WHERE catalog_key = 'catalog:Axle Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_burpee_box_1','art_cf_burpee_box_2','art_cf_burpee_box_3']::text[]
WHERE catalog_key = 'catalog:BBJO' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_burpee_box_1','art_cf_burpee_box_2','art_cf_burpee_box_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_burpee_1','art_cf_burpee_2','art_cf_burpee_3']::text[]
WHERE catalog_key = 'catalog:BTT' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_burpee_1','art_cf_burpee_2','art_cf_burpee_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]
WHERE catalog_key = 'catalog:Back Rack Lunge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_back_lev']::text[]
WHERE catalog_key = 'catalog:Back lever tuck' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_back_lev']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]
WHERE catalog_key = 'catalog:Back rack reverse lunge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_snatch_bal_1','art_hl_snatch_bal_2','art_hl_snatch_bal_3']::text[]
WHERE catalog_key = 'catalog:Balance de arrancada' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_snatch_bal_1','art_hl_snatch_bal_2','art_hl_snatch_bal_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_jerk_bal']::text[]
WHERE catalog_key = 'catalog:Balance de envión' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_jerk_bal']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_slam_1','art_cf_slam_2','art_cf_slam_3']::text[]
WHERE catalog_key = 'catalog:Ball slam' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_slam_1','art_cf_slam_2','art_cf_slam_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_bfb_1','art_cf_bfb_2']::text[]
WHERE catalog_key = 'catalog:Bar facing burpee' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_bfb_1','art_cf_bfb_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Barbell Squat Jump' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_step_up_db_1','art_cf_step_up_db_2']::text[]
WHERE catalog_key = 'catalog:Barbell Step Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_step_up_db_1','art_cf_step_up_db_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_battle_rope']::text[]
WHERE catalog_key = 'catalog:Battle Rope' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_battle_rope']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_sandbag_carry']::text[]
WHERE catalog_key = 'catalog:Bear Hug Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_sandbag_carry']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_bear']::text[]
WHERE catalog_key = 'catalog:Bear crawl' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_bear']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_bear_sit_1','art_mv_bear_sit_2']::text[]
WHERE catalog_key = 'catalog:Bear sit con rotación' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_bear_sit_1','art_mv_bear_sit_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_jerk']::text[]
WHERE catalog_key = 'catalog:Behind-the-Neck Jerk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_jerk']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Behind-the-Neck Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_bici']::text[]
WHERE catalog_key = 'catalog:Bici estática' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_bici']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_airbike']::text[]
WHERE catalog_key = 'catalog:Bike Erg' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_airbike']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Bird Dog' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_hinge_1','art_mv_hinge_2']::text[]
WHERE catalog_key = 'catalog:Bisagra de cadera sin carga' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_hinge_1','art_mv_hinge_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Block Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Block Power Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Block Power Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Block Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Bodyweight Clean And Jerk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]
WHERE catalog_key = 'catalog:Box Jump' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_sentadilla_1','art_sentadilla_2']::text[]
WHERE catalog_key = 'catalog:Box Squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_sentadilla_1','art_sentadilla_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]
WHERE catalog_key = 'catalog:Box Step-Over' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]
WHERE catalog_key = 'catalog:Box Step-Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_bjo_1','art_cf_bjo_2','art_cf_bjo_3']::text[]
WHERE catalog_key = 'catalog:Box jump over' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_bjo_1','art_cf_bjo_2','art_cf_bjo_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_press']::text[]
WHERE catalog_key = 'catalog:Bradford Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_broad_1','art_cf_broad_2','art_cf_broad_3']::text[]
WHERE catalog_key = 'catalog:Broad jump' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_broad_1','art_cf_broad_2','art_cf_broad_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_buenos_dias']::text[]
WHERE catalog_key = 'catalog:Buenos días' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_buenos_dias']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_pvc_gm_1','art_mv_pvc_gm_2']::text[]
WHERE catalog_key = 'catalog:Buenos días con pica' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_pvc_gm_1','art_mv_pvc_gm_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_burpee_1','art_cf_burpee_2','art_cf_burpee_3']::text[]
WHERE catalog_key = 'catalog:Burpee' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_burpee_1','art_cf_burpee_2','art_cf_burpee_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_mu_bar_1','art_cf_mu_bar_2','art_cf_mu_bar_3']::text[]
WHERE catalog_key = 'catalog:Burpee Bar Muscle Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_mu_bar_1','art_cf_mu_bar_2','art_cf_mu_bar_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_burpee_box_1','art_cf_burpee_box_2','art_cf_burpee_box_3']::text[]
WHERE catalog_key = 'catalog:Burpee Box Jump' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_burpee_box_1','art_cf_burpee_box_2','art_cf_burpee_box_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hx_bbj_1','art_hx_bbj_2','art_hx_bbj_3']::text[]
WHERE catalog_key = 'catalog:Burpee Broad Jump' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hx_bbj_1','art_hx_bbj_2','art_hx_bbj_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_mu_bar_1','art_cf_mu_bar_2','art_cf_mu_bar_3']::text[]
WHERE catalog_key = 'catalog:Burpee Muscle-Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_mu_bar_1','art_cf_mu_bar_2','art_cf_mu_bar_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_burpee_1','art_cf_burpee_2','art_cf_burpee_3']::text[]
WHERE catalog_key = 'catalog:Burpee Over Dumbbell' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_burpee_1','art_cf_burpee_2','art_cf_burpee_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_burpee_1','art_cf_burpee_2','art_cf_burpee_3']::text[]
WHERE catalog_key = 'catalog:Burpee Over The Bar' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_burpee_1','art_cf_burpee_2','art_cf_burpee_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_burpee_box_1','art_cf_burpee_box_2','art_cf_burpee_box_3']::text[]
WHERE catalog_key = 'catalog:Burpee al cajón' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_burpee_box_1','art_cf_burpee_box_2','art_cf_burpee_box_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_burpee_box_1','art_cf_burpee_box_2','art_cf_burpee_box_3']::text[]
WHERE catalog_key = 'catalog:Burpee box jump over' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_burpee_box_1','art_cf_burpee_box_2','art_cf_burpee_box_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_burpee_box_1','art_cf_burpee_box_2','art_cf_burpee_box_3']::text[]
WHERE catalog_key = 'catalog:Burpee box jump overs' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_burpee_box_1','art_cf_burpee_box_2','art_cf_burpee_box_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hx_bbj_1','art_hx_bbj_2','art_hx_bbj_3']::text[]
WHERE catalog_key = 'catalog:Burpee con salto de longitud' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hx_bbj_1','art_hx_bbj_2','art_hx_bbj_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_burpee_box_1','art_cf_burpee_box_2','art_cf_burpee_box_3']::text[]
WHERE catalog_key = 'catalog:Burpee over box' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_burpee_box_1','art_cf_burpee_box_2','art_cf_burpee_box_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_burpee_pu_1','art_cf_burpee_pu_2','art_cf_burpee_pu_3']::text[]
WHERE catalog_key = 'catalog:Burpee pull-up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_burpee_pu_1','art_cf_burpee_pu_2','art_cf_burpee_pu_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_btt_1','art_cf_btt_2']::text[]
WHERE catalog_key = 'catalog:Burpee to target' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_btt_1','art_cf_btt_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hx_bbj_1','art_hx_bbj_2','art_hx_bbj_3']::text[]
WHERE catalog_key = 'catalog:Burpees con salto de longitud' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hx_bbj_1','art_hx_bbj_2','art_hx_bbj_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_hip_cars_1','art_mv_hip_cars_2']::text[]
WHERE catalog_key = 'catalog:CARs de cadera' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_hip_cars_1','art_mv_hip_cars_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_neck_cars']::text[]
WHERE catalog_key = 'catalog:CARs de cuello' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_neck_cars']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_shoulder_cars_1','art_mv_shoulder_cars_2']::text[]
WHERE catalog_key = 'catalog:CARs de hombro' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_shoulder_cars_1','art_mv_shoulder_cars_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_ankle_cars_1','art_mv_ankle_cars_2']::text[]
WHERE catalog_key = 'catalog:CARs de tobillo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_ankle_cars_1','art_mv_ankle_cars_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_candle']::text[]
WHERE catalog_key = 'catalog:Candlestick' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_candle']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_cargada_1','art_cf_cargada_2','art_cf_cargada_3']::text[]
WHERE catalog_key = 'catalog:Cargada' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_cargada_1','art_cf_cargada_2','art_cf_cargada_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_hang_clean_1','art_cf_hang_clean_2','art_cf_hang_clean_3']::text[]
WHERE catalog_key = 'catalog:Cargada colgante' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_hang_clean_1','art_cf_hang_clean_2','art_cf_hang_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_hang_sq_clean_1','art_hl_hang_sq_clean_2','art_hl_hang_sq_clean_3']::text[]
WHERE catalog_key = 'catalog:Cargada colgante completa' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_hang_sq_clean_1','art_hl_hang_sq_clean_2','art_hl_hang_sq_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_pause_clean_1','art_hl_pause_clean_2','art_hl_pause_clean_3']::text[]
WHERE catalog_key = 'catalog:Cargada con pausa' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_pause_clean_1','art_hl_pause_clean_2','art_hl_pause_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Cargada de potencia' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_block_power_clean']::text[]
WHERE catalog_key = 'catalog:Cargada de potencia desde bloques' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_block_power_clean']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_block_clean']::text[]
WHERE catalog_key = 'catalog:Cargada desde bloques' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_block_clean']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_muscle_clean_1','art_hl_muscle_clean_2','art_hl_muscle_clean_3']::text[]
WHERE catalog_key = 'catalog:Cargada muscular' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_muscle_clean_1','art_hl_muscle_clean_2','art_hl_muscle_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_cj_1','art_cf_cj_2','art_cf_cj_3']::text[]
WHERE catalog_key = 'catalog:Cargada y envión' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_cj_1','art_cf_cj_2','art_cf_cj_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_db_clean']::text[]
WHERE catalog_key = 'catalog:Cargada y envión con mancuerna' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_db_clean']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_clean_press_1','art_hl_clean_press_2','art_hl_clean_press_3']::text[]
WHERE catalog_key = 'catalog:Cargada y press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_clean_press_1','art_hl_clean_press_2','art_hl_clean_press_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cardio']::text[]
WHERE catalog_key = 'catalog:Carrera' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cardio']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_ctb_1','art_cf_ctb_2','art_cf_ctb_3']::text[]
WHERE catalog_key = 'catalog:Chest to bar' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_ctb_1','art_cf_ctb_2','art_cf_ctb_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cardio']::text[]
WHERE catalog_key = 'catalog:Cinta / carrera' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cardio']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]
WHERE catalog_key = 'catalog:Clean Deadlift' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Clean High Pull' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Clean Pull' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Clean and Jerk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Clean and Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_kb_clean_1','art_cf_kb_clean_2','art_cf_kb_clean_3']::text[]
WHERE catalog_key = 'catalog:Clean kettlebell' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_kb_clean_1','art_cf_kb_clean_2','art_cf_kb_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_db_clean']::text[]
WHERE catalog_key = 'catalog:Clean mancuerna' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_db_clean']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_cluster_1','art_cf_cluster_2','art_cf_cluster_3']::text[]
WHERE catalog_key = 'catalog:Cluster' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_cluster_1','art_cf_cluster_2','art_cf_cluster_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_active_hang']::text[]
WHERE catalog_key = 'catalog:Colgado activo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_active_hang']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_dead_hang']::text[]
WHERE catalog_key = 'catalog:Colgado pasivo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_dead_hang']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_plancha']::text[]
WHERE catalog_key = 'catalog:Copenhagen Plank' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_plancha']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_cossack']::text[]
WHERE catalog_key = 'catalog:Cossack squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_cossack']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_couch']::text[]
WHERE catalog_key = 'catalog:Couch stretch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_couch']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Crab Walk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_du']::text[]
WHERE catalog_key = 'catalog:Crossover Single Under' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_du']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cruce_poleas']::text[]
WHERE catalog_key = 'catalog:Cruce de poleas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cruce_poleas']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_crunch']::text[]
WHERE catalog_key = 'catalog:Crunch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_crunch']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_crunch']::text[]
WHERE catalog_key = 'catalog:Crunch en polea' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_crunch']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_barra_1','art_curl_barra_2']::text[]
WHERE catalog_key = 'catalog:Curl barra' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_barra_1','art_curl_barra_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_mancuernas']::text[]
WHERE catalog_key = 'catalog:Curl concentrado' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_mancuernas']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_barra_1','art_curl_barra_2']::text[]
WHERE catalog_key = 'catalog:Curl de muñeca' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_barra_1','art_curl_barra_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_femoral']::text[]
WHERE catalog_key = 'catalog:Curl femoral' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_femoral']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_femoral']::text[]
WHERE catalog_key = 'catalog:Curl femoral sentado' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_femoral']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_femoral']::text[]
WHERE catalog_key = 'catalog:Curl femoral tumbado' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_femoral']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_mancuernas']::text[]
WHERE catalog_key = 'catalog:Curl inclinado con mancuernas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_mancuernas']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_mancuernas']::text[]
WHERE catalog_key = 'catalog:Curl mancuernas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_mancuernas']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_martillo']::text[]
WHERE catalog_key = 'catalog:Curl martillo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_martillo']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_predicador']::text[]
WHERE catalog_key = 'catalog:Curl predicador' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_predicador']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_shoulder_circles_1','art_mv_shoulder_circles_2']::text[]
WHERE catalog_key = 'catalog:Círculos de hombros' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_shoulder_circles_1','art_mv_shoulder_circles_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_wrist_circles_1','art_mv_wrist_circles_2']::text[]
WHERE catalog_key = 'catalog:Círculos de muñecas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_wrist_circles_1','art_mv_wrist_circles_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_ankle_circles_1','art_mv_ankle_circles_2']::text[]
WHERE catalog_key = 'catalog:Círculos de tobillo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_ankle_circles_1','art_mv_ankle_circles_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:D-Ball Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]
WHERE catalog_key = 'catalog:D-Ball Over Shoulder' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Dead Bug' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_dead_hang']::text[]
WHERE catalog_key = 'catalog:Dead Hang' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_dead_hang']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]
WHERE catalog_key = 'catalog:Deficit Deadlift' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_nerve_glide_1','art_mv_nerve_glide_2']::text[]
WHERE catalog_key = 'catalog:Deslizamiento neural suave' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_nerve_glide_1','art_mv_nerve_glide_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_wall_slide_1','art_mv_wall_slide_2']::text[]
WHERE catalog_key = 'catalog:Deslizamientos en pared' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_wall_slide_1','art_mv_wall_slide_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_devil_1','art_cf_devil_2','art_cf_devil_3']::text[]
WHERE catalog_key = 'catalog:Devil press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_devil_1','art_cf_devil_2','art_cf_devil_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_jerk_dip_1','art_hl_jerk_dip_2']::text[]
WHERE catalog_key = 'catalog:Dip y drive de envión' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_jerk_dip_1','art_hl_jerk_dip_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_du']::text[]
WHERE catalog_key = 'catalog:Dobles de comba' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_du']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_dominadas_1','art_dominadas_2']::text[]
WHERE catalog_key = 'catalog:Dominadas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_dominadas_1','art_dominadas_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_dominadas_1','art_dominadas_2']::text[]
WHERE catalog_key = 'catalog:Dominadas asistidas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_dominadas_1','art_dominadas_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_bfly_pu']::text[]
WHERE catalog_key = 'catalog:Dominadas butterfly' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_bfly_pu']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_ring_pu']::text[]
WHERE catalog_key = 'catalog:Dominadas en anillas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_ring_pu']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_strict_pu']::text[]
WHERE catalog_key = 'catalog:Dominadas estrictas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_strict_pu']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_kip_pu']::text[]
WHERE catalog_key = 'catalog:Dominadas kipping' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_kip_pu']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_dominadas_lastrada_1','art_dominadas_lastrada_2']::text[]
WHERE catalog_key = 'catalog:Dominadas lastradas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_dominadas_lastrada_1','art_dominadas_lastrada_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_chinup']::text[]
WHERE catalog_key = 'catalog:Dominadas supinas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_chinup']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_band_dorsi_1','art_mv_band_dorsi_2']::text[]
WHERE catalog_key = 'catalog:Dorsiflexión de tobillo con banda' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_band_dorsi_1','art_mv_band_dorsi_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_step_up_db_1','art_cf_step_up_db_2']::text[]
WHERE catalog_key = 'catalog:Double Dumbbell Step Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_step_up_db_1','art_cf_step_up_db_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Double Kettlebell Farmers Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Double Kettlebell Front Rack Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]
WHERE catalog_key = 'catalog:Double Kettlebell Front Rack Lunge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Double Kettlebell Overhead Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_du']::text[]
WHERE catalog_key = 'catalog:Double-Under' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_du']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_hollow_hold']::text[]
WHERE catalog_key = 'catalog:Dragon flag' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_hollow_hold']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_drop_snatch']::text[]
WHERE catalog_key = 'catalog:Drop snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_drop_snatch']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_press_banca_1','art_press_banca_2']::text[]
WHERE catalog_key = 'catalog:Dumbbell Bench Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_press_banca_1','art_press_banca_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Box Step Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_burpee_1','art_cf_burpee_2','art_cf_burpee_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Burpee Deadlift' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_burpee_1','art_cf_burpee_2','art_cf_burpee_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Dumbbell Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Clean and Jerk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]
WHERE catalog_key = 'catalog:Dumbbell Deadlift' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_floor_press']::text[]
WHERE catalog_key = 'catalog:Dumbbell Floor Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_floor_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Front Rack Lunge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_goblet_1','art_cf_goblet_2','art_cf_goblet_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Front Squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_goblet_1','art_cf_goblet_2','art_cf_goblet_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Hang Clean To Overhead' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Hang Clean and Jerk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Hang Power Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Hang Split Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Hang Squat Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Dumbbell Overhead Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Overhead Lunge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_ohs_1','art_cf_ohs_2','art_cf_ohs_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Overhead Squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_ohs_1','art_cf_ohs_2','art_cf_ohs_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Power Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Power Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_press']::text[]
WHERE catalog_key = 'catalog:Dumbbell Push Jerk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_press']::text[]
WHERE catalog_key = 'catalog:Dumbbell Push Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_rdl_1','art_rdl_2']::text[]
WHERE catalog_key = 'catalog:Dumbbell Romanian Deadlift' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_rdl_1','art_rdl_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_press']::text[]
WHERE catalog_key = 'catalog:Dumbbell Shoulder Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_press']::text[]
WHERE catalog_key = 'catalog:Dumbbell Shoulder To Overhead' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Split Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Squat Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_thruster_1','art_cf_thruster_2','art_cf_thruster_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Squat Clean Thruster' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_thruster_1','art_cf_thruster_2','art_cf_thruster_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_press']::text[]
WHERE catalog_key = 'catalog:Dumbbell Strict Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_thruster_1','art_cf_thruster_2','art_cf_thruster_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Thruster' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_thruster_1','art_cf_thruster_2','art_cf_thruster_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Dumbbell Waiters Walk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]
WHERE catalog_key = 'catalog:Dumbbell Walking Lunge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_echo']::text[]
WHERE catalog_key = 'catalog:Echo bike' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_echo']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_scap_elev_1','art_mv_scap_elev_2']::text[]
WHERE catalog_key = 'catalog:Elevaciones escapulares' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_scap_elev_1','art_mv_scap_elev_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_elev_frontales']::text[]
WHERE catalog_key = 'catalog:Elevaciones frontales' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_elev_frontales']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_elevaciones_laterales']::text[]
WHERE catalog_key = 'catalog:Elevaciones laterales' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_elevaciones_laterales']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_elevaciones_laterales']::text[]
WHERE catalog_key = 'catalog:Elevaciones laterales en polea' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_elevaciones_laterales']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gemelos_1','art_gemelos_2']::text[]
WHERE catalog_key = 'catalog:Elevación de gemelos' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gemelos_1','art_gemelos_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_elev_piernas']::text[]
WHERE catalog_key = 'catalog:Elevación de piernas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_elev_piernas']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_tib_raise_1','art_mv_tib_raise_2']::text[]
WHERE catalog_key = 'catalog:Elevación de tibial anterior' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_tib_raise_1','art_mv_tib_raise_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_remo_barra_1','art_remo_barra_2']::text[]
WHERE catalog_key = 'catalog:Encogimientos' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_remo_barra_1','art_remo_barra_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_thread_needle_1','art_mv_thread_needle_2']::text[]
WHERE catalog_key = 'catalog:Enhebrar la aguja' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_thread_needle_1','art_mv_thread_needle_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_btn_jerk']::text[]
WHERE catalog_key = 'catalog:Envión detrás de nuca' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_btn_jerk']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_squat_jerk_1','art_hl_squat_jerk_2']::text[]
WHERE catalog_key = 'catalog:Envión en sentadilla' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_squat_jerk_1','art_hl_squat_jerk_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_quad_stretch']::text[]
WHERE catalog_key = 'catalog:Estiramiento de cuádriceps de pie' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_quad_stretch']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_bench_lat']::text[]
WHERE catalog_key = 'catalog:Estiramiento de dorsal en banco' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_bench_lat']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_calf_wall']::text[]
WHERE catalog_key = 'catalog:Estiramiento de gemelo en pared' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_calf_wall']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_cross_shoulder']::text[]
WHERE catalog_key = 'catalog:Estiramiento de hombro cruzado' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_cross_shoulder']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_band_ham']::text[]
WHERE catalog_key = 'catalog:Estiramiento de isquios con banda' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_band_ham']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_soleus_wall']::text[]
WHERE catalog_key = 'catalog:Estiramiento de sóleo en pared' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_soleus_wall']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_hip_flexor']::text[]
WHERE catalog_key = 'catalog:Estiramiento del flexor de cadera' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_hip_flexor']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_ham_dynamic_1','art_mv_ham_dynamic_2']::text[]
WHERE catalog_key = 'catalog:Estiramiento dinámico de isquios' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_ham_dynamic_1','art_mv_ham_dynamic_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_door_pec']::text[]
WHERE catalog_key = 'catalog:Estiramiento pectoral en puerta' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_door_pec']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_hip_ext_stand_1','art_mv_hip_ext_stand_2']::text[]
WHERE catalog_key = 'catalog:Extensión activa de cadera de pie' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_hip_ext_stand_1','art_mv_hip_ext_stand_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_neck_ext']::text[]
WHERE catalog_key = 'catalog:Extensión cervical suave' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_neck_ext']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_elbow_ext_1','art_mv_elbow_ext_2']::text[]
WHERE catalog_key = 'catalog:Extensión controlada de codo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_elbow_ext_1','art_mv_elbow_ext_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_extension_cuad']::text[]
WHERE catalog_key = 'catalog:Extensión de cuádriceps' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_extension_cuad']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_foam_text_1','art_mv_foam_text_2']::text[]
WHERE catalog_key = 'catalog:Extensión torácica con rodillo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_foam_text_1','art_mv_foam_text_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_triceps_polea']::text[]
WHERE catalog_key = 'catalog:Extensión tríceps overhead' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_triceps_polea']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_triceps_polea']::text[]
WHERE catalog_key = 'catalog:Extensión tríceps polea' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_triceps_polea']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_face_pull']::text[]
WHERE catalog_key = 'catalog:Face pull' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_face_pull']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_false_grip']::text[]
WHERE catalog_key = 'catalog:False grip hang' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_false_grip']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Farmer carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_farmer']::text[]
WHERE catalog_key = 'catalog:Farmer walk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_farmer']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_figure4']::text[]
WHERE catalog_key = 'catalog:Figura cuatro tumbado' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_figure4']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_scap_pu_1','art_mv_scap_pu_2']::text[]
WHERE catalog_key = 'catalog:Flexiones escapulares' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_scap_pu_1','art_mv_scap_pu_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_hip_flex_stand_1','art_mv_hip_flex_stand_2']::text[]
WHERE catalog_key = 'catalog:Flexión activa de cadera de pie' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_hip_flex_stand_1','art_mv_hip_flex_stand_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_neck_flex']::text[]
WHERE catalog_key = 'catalog:Flexión cervical suave' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_neck_flex']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_elbow_flex_1','art_mv_elbow_flex_2']::text[]
WHERE catalog_key = 'catalog:Flexión controlada de codo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_elbow_flex_1','art_mv_elbow_flex_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_knee_flex_sup_1','art_mv_knee_flex_sup_2']::text[]
WHERE catalog_key = 'catalog:Flexión de rodilla en apoyo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_knee_flex_sup_1','art_mv_knee_flex_sup_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_plantar_1','art_mv_plantar_2']::text[]
WHERE catalog_key = 'catalog:Flexión plantar de tobillo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_plantar_1','art_mv_plantar_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_seg_flex_1','art_mv_seg_flex_2']::text[]
WHERE catalog_key = 'catalog:Flexión segmentaria de columna' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_seg_flex_1','art_mv_seg_flex_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_floor_press']::text[]
WHERE catalog_key = 'catalog:Floor Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_floor_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Flutter Kick' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_fondos']::text[]
WHERE catalog_key = 'catalog:Fondos' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_fondos']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_fondos']::text[]
WHERE catalog_key = 'catalog:Fondos asistidos' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_fondos']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_ring_dip_1','art_cf_ring_dip_2','art_cf_ring_dip_3']::text[]
WHERE catalog_key = 'catalog:Fondos en anillas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_ring_dip_1','art_cf_ring_dip_2','art_cf_ring_dip_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_ring_dip_kip_1','art_gy_ring_dip_kip_2']::text[]
WHERE catalog_key = 'catalog:Fondos en anillas kipping' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_ring_dip_kip_1','art_gy_ring_dip_kip_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_fondos_banco']::text[]
WHERE catalog_key = 'catalog:Fondos en banco' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_fondos_banco']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_pb_dip_1','art_gy_pb_dip_2']::text[]
WHERE catalog_key = 'catalog:Fondos en paralelas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_pb_dip_1','art_gy_pb_dip_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_frog']::text[]
WHERE catalog_key = 'catalog:Frog stretch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_frog']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_front_lev']::text[]
WHERE catalog_key = 'catalog:Front lever tuck' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_front_lev']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_fr_lunge_1','art_cf_fr_lunge_2']::text[]
WHERE catalog_key = 'catalog:Front rack lunge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_fr_lunge_1','art_cf_fr_lunge_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_ghd_back']::text[]
WHERE catalog_key = 'catalog:GHD back extension' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_ghd_back']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_ghd_1','art_cf_ghd_2','art_cf_ghd_3']::text[]
WHERE catalog_key = 'catalog:GHD sit-up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_ghd_1','art_cf_ghd_2','art_cf_ghd_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_cat_cow_1','art_mv_cat_cow_2']::text[]
WHERE catalog_key = 'catalog:Gato-vaca' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_cat_cow_1','art_mv_cat_cow_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gemelos_1','art_gemelos_2']::text[]
WHERE catalog_key = 'catalog:Gemelos de burro' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gemelos_1','art_gemelos_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gemelos_1','art_gemelos_2']::text[]
WHERE catalog_key = 'catalog:Gemelos sentado' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gemelos_1','art_gemelos_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_german']::text[]
WHERE catalog_key = 'catalog:German hang' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_german']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hip_thrust_1','art_hip_thrust_2']::text[]
WHERE catalog_key = 'catalog:Glute Bridge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hip_thrust_1','art_hip_thrust_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hip_thrust_1','art_hip_thrust_2']::text[]
WHERE catalog_key = 'catalog:Glute Ham Raise' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hip_thrust_1','art_hip_thrust_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_goblet_1','art_cf_goblet_2','art_cf_goblet_3']::text[]
WHERE catalog_key = 'catalog:Goblet squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_goblet_1','art_cf_goblet_2','art_cf_goblet_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_gto']::text[]
WHERE catalog_key = 'catalog:Ground to overhead' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_gto']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_hspu_1','art_cf_hspu_2','art_cf_hspu_3']::text[]
WHERE catalog_key = 'catalog:HSPU' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_hspu_1','art_cf_hspu_2','art_cf_hspu_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_hspu_def_1','art_gy_hspu_def_2']::text[]
WHERE catalog_key = 'catalog:HSPU deficit' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_hspu_def_1','art_gy_hspu_def_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_hspu_free']::text[]
WHERE catalog_key = 'catalog:HSPU libre' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_hspu_free']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hack_squat']::text[]
WHERE catalog_key = 'catalog:Hack squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hack_squat']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_up']::text[]
WHERE catalog_key = 'catalog:Hand Release Push Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_up']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_hs_hold']::text[]
WHERE catalog_key = 'catalog:Handstand hold' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_hs_hold']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_hsw']::text[]
WHERE catalog_key = 'catalog:Handstand walk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_hsw']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Hang Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Hang High Pull' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Hang Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Hang Squat Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_hang_sq_snatch_1','art_hl_hang_sq_snatch_2','art_hl_hang_sq_snatch_3']::text[]
WHERE catalog_key = 'catalog:Hang Squat Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_hang_sq_snatch_1','art_hl_hang_sq_snatch_2','art_hl_hang_sq_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_hpc_1','art_cf_hpc_2','art_cf_hpc_3']::text[]
WHERE catalog_key = 'catalog:Hang power clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_hpc_1','art_cf_hpc_2','art_cf_hpc_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_hps']::text[]
WHERE catalog_key = 'catalog:Hang power snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_hps']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_hang_sq_snatch_1','art_hl_hang_sq_snatch_2','art_hl_hang_sq_snatch_3']::text[]
WHERE catalog_key = 'catalog:Hang squat snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_hang_sq_snatch_1','art_hl_hang_sq_snatch_2','art_hl_hang_sq_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Hanging Hip Touch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Hanging Knee Raise' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_femoral']::text[]
WHERE catalog_key = 'catalog:Hidrante con banda' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_femoral']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_ghd_back']::text[]
WHERE catalog_key = 'catalog:Hip extension' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_ghd_back']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hip_thrust_1','art_hip_thrust_2']::text[]
WHERE catalog_key = 'catalog:Hip thrust' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hip_thrust_1','art_hip_thrust_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_htb']::text[]
WHERE catalog_key = 'catalog:Hip to bar' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_htb']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_hollow_hold']::text[]
WHERE catalog_key = 'catalog:Hollow hold' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_hollow_hold']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_hollow']::text[]
WHERE catalog_key = 'catalog:Hollow rock' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_hollow']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Husafell Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_inchworm_1','art_mv_inchworm_2','art_mv_inchworm_3']::text[]
WHERE catalog_key = 'catalog:Inchworm' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_inchworm_1','art_mv_inchworm_2','art_mv_inchworm_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_neck_lat']::text[]
WHERE catalog_key = 'catalog:Inclinación lateral cervical' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_neck_lat']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_side_bend_1','art_mv_side_bend_2']::text[]
WHERE catalog_key = 'catalog:Inclinación lateral de tronco' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_side_bend_1','art_mv_side_bend_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_inv_ev_1','art_mv_inv_ev_2']::text[]
WHERE catalog_key = 'catalog:Inversión y eversión de tobillo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_inv_ev_1','art_mv_inv_ev_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_jalon_1','art_jalon_2']::text[]
WHERE catalog_key = 'catalog:Jalón a brazos rectos' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_jalon_1','art_jalon_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_jalon_1','art_jalon_2']::text[]
WHERE catalog_key = 'catalog:Jalón al pecho' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_jalon_1','art_jalon_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_mancuernas']::text[]
WHERE catalog_key = 'catalog:Jefferson Curl' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_mancuernas']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_jerk']::text[]
WHERE catalog_key = 'catalog:Jerk Balance' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_jerk']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_jerk']::text[]
WHERE catalog_key = 'catalog:Jerk Dip and Drive' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_jerk']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Jerry Bag Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Jumping Jack' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_dominadas_1','art_dominadas_2']::text[]
WHERE catalog_key = 'catalog:Jumping Pull-Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_dominadas_1','art_dominadas_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_jump_lunge_1','art_gy_jump_lunge_2','art_gy_jump_lunge_3']::text[]
WHERE catalog_key = 'catalog:Jumping lunge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_jump_lunge_1','art_gy_jump_lunge_2','art_gy_jump_lunge_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_jump_squat_1','art_gy_jump_squat_2','art_gy_jump_squat_3']::text[]
WHERE catalog_key = 'catalog:Jumping squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_jump_squat_1','art_gy_jump_squat_2','art_gy_jump_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Keg Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Kettlebell Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Kettlebell Clean and Jerk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]
WHERE catalog_key = 'catalog:Kettlebell Deadlift' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]
WHERE catalog_key = 'catalog:Kettlebell Front Rack Lunge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]
WHERE catalog_key = 'catalog:Kettlebell Goblet Box Step-Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_kb_clean_1','art_cf_kb_clean_2','art_cf_kb_clean_3']::text[]
WHERE catalog_key = 'catalog:Kettlebell Halo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_kb_clean_1','art_cf_kb_clean_2','art_cf_kb_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]
WHERE catalog_key = 'catalog:Kettlebell Overhead Lunge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_kb_clean_1','art_cf_kb_clean_2','art_cf_kb_clean_3']::text[]
WHERE catalog_key = 'catalog:Kettlebell Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_kb_clean_1','art_cf_kb_clean_2','art_cf_kb_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_press']::text[]
WHERE catalog_key = 'catalog:Kettlebell Push Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Kettlebell Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]
WHERE catalog_key = 'catalog:Kettlebell Sumo Deadlift High Pull' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_kb_swing_1','art_cf_kb_swing_2','art_cf_kb_swing_3']::text[]
WHERE catalog_key = 'catalog:Kettlebell Swing' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_kb_swing_1','art_cf_kb_swing_2','art_cf_kb_swing_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_thruster_1','art_cf_thruster_2','art_cf_thruster_3']::text[]
WHERE catalog_key = 'catalog:Kettlebell Thruster' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_thruster_1','art_cf_thruster_2','art_cf_thruster_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_kb_clean_1','art_cf_kb_clean_2','art_cf_kb_clean_3']::text[]
WHERE catalog_key = 'catalog:Kettlebell Windmill' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_kb_clean_1','art_cf_kb_clean_2','art_cf_kb_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_triceps_polea']::text[]
WHERE catalog_key = 'catalog:Kickback de tríceps' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_triceps_polea']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_kip_swing']::text[]
WHERE catalog_key = 'catalog:Kip swing' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_kip_swing']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_hspu_kipping']::text[]
WHERE catalog_key = 'catalog:Kipping Handstand Push Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_hspu_kipping']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_kte']::text[]
WHERE catalog_key = 'catalog:Knees to elbows' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_kte']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_dominadas_1','art_dominadas_2']::text[]
WHERE catalog_key = 'catalog:L Pull Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_dominadas_1','art_dominadas_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_lsit']::text[]
WHERE catalog_key = 'catalog:L-sit' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_lsit']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_press']::text[]
WHERE catalog_key = 'catalog:Landmine Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_burpee_1','art_cf_burpee_2','art_cf_burpee_3']::text[]
WHERE catalog_key = 'catalog:Lateral Burpee' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_burpee_1','art_cf_burpee_2','art_cf_burpee_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]
WHERE catalog_key = 'catalog:Lateral Lunge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_open_book_1','art_mv_open_book_2']::text[]
WHERE catalog_key = 'catalog:Libro abierto' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_open_book_1','art_mv_open_book_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Log Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Log Clean And Jerk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]
WHERE catalog_key = 'catalog:Log Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_manmaker_1','art_cf_manmaker_2','art_cf_manmaker_3','art_cf_manmaker_4','art_cf_manmaker_5','art_cf_manmaker_6']::text[]
WHERE catalog_key = 'catalog:Man maker' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_manmaker_1','art_cf_manmaker_2','art_cf_manmaker_3','art_cf_manmaker_4','art_cf_manmaker_5','art_cf_manmaker_6']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_butterfly']::text[]
WHERE catalog_key = 'catalog:Mariposa sentada' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_butterfly']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_remo_barra_1','art_remo_barra_2']::text[]
WHERE catalog_key = 'catalog:Meadows row' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_remo_barra_1','art_remo_barra_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_mb_clean']::text[]
WHERE catalog_key = 'catalog:Medball clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_mb_clean']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]
WHERE catalog_key = 'catalog:Medicine Ball Box Step Over' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_situp']::text[]
WHERE catalog_key = 'catalog:Medicine Ball Sit Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_situp']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_remo_mancuerna_1','art_remo_mancuerna_2']::text[]
WHERE catalog_key = 'catalog:Medicine Ball Throw' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_remo_mancuerna_1','art_remo_mancuerna_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Mountain Climber' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_wrist_ext_1','art_mv_wrist_ext_2']::text[]
WHERE catalog_key = 'catalog:Movilidad de muñeca en extensión' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_wrist_ext_1','art_mv_wrist_ext_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_wrist_flex']::text[]
WHERE catalog_key = 'catalog:Movilidad de muñeca en flexión' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_wrist_flex']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Muscle Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Muscle Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_mu_rings_1','art_cf_mu_rings_2','art_cf_mu_rings_3']::text[]
WHERE catalog_key = 'catalog:Muscle-up anillas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_mu_rings_1','art_cf_mu_rings_2','art_cf_mu_rings_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_mu_bar_1','art_cf_mu_bar_2','art_cf_mu_bar_3']::text[]
WHERE catalog_key = 'catalog:Muscle-up barra' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_mu_bar_1','art_cf_mu_bar_2','art_cf_mu_bar_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_strict_muring']::text[]
WHERE catalog_key = 'catalog:Muscle-up estricto anillas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_strict_muring']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_strict_mubar']::text[]
WHERE catalog_key = 'catalog:Muscle-up estricto barra' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_strict_mubar']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_dominadas_1','art_dominadas_2']::text[]
WHERE catalog_key = 'catalog:Negative Pull Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_dominadas_1','art_dominadas_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_mancuernas']::text[]
WHERE catalog_key = 'catalog:Nordic Curl' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_mancuernas']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]
WHERE catalog_key = 'catalog:Overhead Lunge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Overhead Walk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_ohs_1','art_cf_ohs_2','art_cf_ohs_3']::text[]
WHERE catalog_key = 'catalog:Overhead squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_ohs_1','art_cf_ohs_2','art_cf_ohs_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Pallof Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Parallel Bar Traverse' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_hspu_1','art_cf_hspu_2','art_cf_hspu_3']::text[]
WHERE catalog_key = 'catalog:Parallette Handstand Push Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_hspu_1','art_cf_hspu_2','art_cf_hspu_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_pvc_pass_1','art_mv_pvc_pass_2']::text[]
WHERE catalog_key = 'catalog:Pasadas de hombros con pica' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_pvc_pass_1','art_mv_pvc_pass_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_paso_banda']::text[]
WHERE catalog_key = 'catalog:Paso lateral con banda' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_paso_banda']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Pause Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_goblet_1','art_cf_goblet_2','art_cf_goblet_3']::text[]
WHERE catalog_key = 'catalog:Pause Front Squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_goblet_1','art_cf_goblet_2','art_cf_goblet_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Pause Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_aperturas_1','art_aperturas_2']::text[]
WHERE catalog_key = 'catalog:Pec deck' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_aperturas_1','art_aperturas_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_pegboard']::text[]
WHERE catalog_key = 'catalog:Pegboard' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_pegboard']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_remo_mancuerna_1','art_remo_mancuerna_2']::text[]
WHERE catalog_key = 'catalog:Pendlay Row' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_remo_mancuerna_1','art_remo_mancuerna_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_down_dog_1','art_mv_down_dog_2']::text[]
WHERE catalog_key = 'catalog:Perro boca abajo dinámico' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_down_dog_1','art_mv_down_dog_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]
WHERE catalog_key = 'catalog:Peso muerto' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_snatch_dl']::text[]
WHERE catalog_key = 'catalog:Peso muerto agarre arrancada' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_snatch_dl']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_clean_dl']::text[]
WHERE catalog_key = 'catalog:Peso muerto de cargada' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_clean_dl']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_rdl_1','art_rdl_2']::text[]
WHERE catalog_key = 'catalog:Peso muerto rumano' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_rdl_1','art_rdl_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_sumo']::text[]
WHERE catalog_key = 'catalog:Peso muerto sumo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_sumo']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_pike_pu_1','art_gy_pike_pu_2']::text[]
WHERE catalog_key = 'catalog:Pike push-up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_pike_pu_1','art_gy_pike_pu_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_pistol_1','art_cf_pistol_2','art_cf_pistol_3']::text[]
WHERE catalog_key = 'catalog:Pistol squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_pistol_1','art_cf_pistol_2','art_cf_pistol_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_plancha']::text[]
WHERE catalog_key = 'catalog:Plancha' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_plancha']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_planche']::text[]
WHERE catalog_key = 'catalog:Planche lean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_planche']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_planche']::text[]
WHERE catalog_key = 'catalog:Planche tuck' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_planche']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Plate Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_plate_gto']::text[]
WHERE catalog_key = 'catalog:Plate ground to overhead' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_plate_gto']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_sphinx']::text[]
WHERE catalog_key = 'catalog:Postura de la esfinge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_sphinx']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_pigeon']::text[]
WHERE catalog_key = 'catalog:Postura de la paloma' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_pigeon']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_child']::text[]
WHERE catalog_key = 'catalog:Postura del niño' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_child']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_child_side']::text[]
WHERE catalog_key = 'catalog:Postura del niño lateral' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_child_side']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]
WHERE catalog_key = 'catalog:Power Clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_clean_1','art_cf_power_clean_2','art_cf_power_clean_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Power Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_power_jerk']::text[]
WHERE catalog_key = 'catalog:Power jerk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_power_jerk']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_prensa']::text[]
WHERE catalog_key = 'catalog:Prensa' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_prensa']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_arnold']::text[]
WHERE catalog_key = 'catalog:Press Arnold' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_arnold']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_press_banca_1','art_press_banca_2']::text[]
WHERE catalog_key = 'catalog:Press banca' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_press_banca_1','art_press_banca_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_press_declinado']::text[]
WHERE catalog_key = 'catalog:Press banca declinado' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_press_declinado']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_press_inclinado_1','art_press_inclinado_2']::text[]
WHERE catalog_key = 'catalog:Press banca inclinada' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_press_inclinado_1','art_press_inclinado_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_press_cerrado_1','art_press_cerrado_2']::text[]
WHERE catalog_key = 'catalog:Press cerrado' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_press_cerrado_1','art_press_cerrado_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_btn_press']::text[]
WHERE catalog_key = 'catalog:Press detrás de nuca' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_btn_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_press_frances_1','art_press_frances_2']::text[]
WHERE catalog_key = 'catalog:Press francés' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_press_frances_1','art_press_frances_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_press_militar_1','art_press_militar_2']::text[]
WHERE catalog_key = 'catalog:Press hombro en máquina' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_press_militar_1','art_press_militar_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_press_mancuernas_1','art_press_mancuernas_2']::text[]
WHERE catalog_key = 'catalog:Press mancuernas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_press_mancuernas_1','art_press_mancuernas_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_press_militar_1','art_press_militar_2']::text[]
WHERE catalog_key = 'catalog:Press militar' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_press_militar_1','art_press_militar_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_press_banca_1','art_press_banca_2']::text[]
WHERE catalog_key = 'catalog:Press pecho en máquina' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_press_banca_1','art_press_banca_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_press_hs']::text[]
WHERE catalog_key = 'catalog:Press to handstand' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_press_hs']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_pron_sup_1','art_mv_pron_sup_2']::text[]
WHERE catalog_key = 'catalog:Pronación y supinación de antebrazo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_pron_sup_1','art_mv_pron_sup_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_scap_proret_1','art_mv_scap_proret_2']::text[]
WHERE catalog_key = 'catalog:Protracción y retracción escapular' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_scap_proret_1','art_mv_scap_proret_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_glute_bridge_1','art_mv_glute_bridge_2']::text[]
WHERE catalog_key = 'catalog:Puente de glúteo articulado' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_glute_bridge_1','art_mv_glute_bridge_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_pullover']::text[]
WHERE catalog_key = 'catalog:Pull-over barra' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_pullover']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_pullover_1','art_pullover_2']::text[]
WHERE catalog_key = 'catalog:Pullover' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_pullover_1','art_pullover_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_up']::text[]
WHERE catalog_key = 'catalog:Push Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_up']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_jerk']::text[]
WHERE catalog_key = 'catalog:Push jerk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_jerk']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_press']::text[]
WHERE catalog_key = 'catalog:Push press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_snatch_grip_pp']::text[]
WHERE catalog_key = 'catalog:Push press con agarre de arrancada' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_snatch_grip_pp']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_pajaros']::text[]
WHERE catalog_key = 'catalog:Pájaros' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_pajaros']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_remo_menton']::text[]
WHERE catalog_key = 'catalog:Remo al mentón' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_remo_menton']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_remo_sentado']::text[]
WHERE catalog_key = 'catalog:Remo con apoyo de pecho' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_remo_sentado']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_remo_barra_1','art_remo_barra_2']::text[]
WHERE catalog_key = 'catalog:Remo con barra' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_remo_barra_1','art_remo_barra_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_remo_barra_1','art_remo_barra_2']::text[]
WHERE catalog_key = 'catalog:Remo en T' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_remo_barra_1','art_remo_barra_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_ring_row']::text[]
WHERE catalog_key = 'catalog:Remo en anillas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_ring_row']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_remo_invertido']::text[]
WHERE catalog_key = 'catalog:Remo invertido' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_remo_invertido']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_remo_mancuerna_1','art_remo_mancuerna_2']::text[]
WHERE catalog_key = 'catalog:Remo mancuerna' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_remo_mancuerna_1','art_remo_mancuerna_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_remo_erg']::text[]
WHERE catalog_key = 'catalog:Remo máquina' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_remo_erg']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_ring_row_plyo_1','art_gy_ring_row_plyo_2']::text[]
WHERE catalog_key = 'catalog:Remo pliométrico en anillas pies elevados' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_ring_row_plyo_1','art_gy_ring_row_plyo_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_remo_sentado']::text[]
WHERE catalog_key = 'catalog:Remo sentado' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_remo_sentado']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_press_mancuernas_1','art_press_mancuernas_2']::text[]
WHERE catalog_key = 'catalog:Renegade Row' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_press_mancuernas_1','art_press_mancuernas_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_breath_9090']::text[]
WHERE catalog_key = 'catalog:Respiración diafragmática 90/90' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_breath_9090']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_chin_tuck']::text[]
WHERE catalog_key = 'catalog:Retracción cervical' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_chin_tuck']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Reverse Hyper' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_mu_rings_1','art_cf_mu_rings_2','art_cf_mu_rings_3']::text[]
WHERE catalog_key = 'catalog:Ring Hamstring Curl' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_mu_rings_1','art_cf_mu_rings_2','art_cf_mu_rings_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_hspu_1','art_cf_hspu_2','art_cf_hspu_3']::text[]
WHERE catalog_key = 'catalog:Ring Handstand Push Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_hspu_1','art_cf_hspu_2','art_cf_hspu_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_mu_rings_1','art_cf_mu_rings_2','art_cf_mu_rings_3']::text[]
WHERE catalog_key = 'catalog:Ring Lower' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_mu_rings_1','art_cf_mu_rings_2','art_cf_mu_rings_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_up']::text[]
WHERE catalog_key = 'catalog:Ring Push Up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_up']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_add_rockback_1','art_mv_add_rockback_2']::text[]
WHERE catalog_key = 'catalog:Rockback de aductores' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_add_rockback_1','art_mv_add_rockback_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_rockback_1','art_mv_rockback_2']::text[]
WHERE catalog_key = 'catalog:Rockback global en cuadrupedia' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_rockback_1','art_mv_rockback_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_knee_wall_1','art_mv_knee_wall_2']::text[]
WHERE catalog_key = 'catalog:Rodilla a pared para tobillo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_knee_wall_1','art_mv_knee_wall_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_knee_over_toes_1','art_mv_knee_over_toes_2']::text[]
WHERE catalog_key = 'catalog:Rodilla sobre dedos controlada' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_knee_over_toes_1','art_mv_knee_over_toes_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_rope_1','art_cf_rope_2','art_cf_rope_3']::text[]
WHERE catalog_key = 'catalog:Rope climb' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_rope_1','art_cf_rope_2','art_cf_rope_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_rope_ll']::text[]
WHERE catalog_key = 'catalog:Rope climb legless' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_rope_ll']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_neck_rot']::text[]
WHERE catalog_key = 'catalog:Rotación cervical' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_neck_rot']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_supine_twist_1','art_mv_supine_twist_2']::text[]
WHERE catalog_key = 'catalog:Rotación de tronco tumbado' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_supine_twist_1','art_mv_supine_twist_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_band_er_1','art_mv_band_er_2']::text[]
WHERE catalog_key = 'catalog:Rotación externa de hombro con banda' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_band_er_1','art_mv_band_er_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_hip_ir_seated_1','art_mv_hip_ir_seated_2']::text[]
WHERE catalog_key = 'catalog:Rotación interna de cadera sentado' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_hip_ir_seated_1','art_mv_hip_ir_seated_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_shoulder_ir']::text[]
WHERE catalog_key = 'catalog:Rotación interna de hombro' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_shoulder_ir']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_quad_trot_1','art_mv_quad_trot_2']::text[]
WHERE catalog_key = 'catalog:Rotación torácica en cuadrupedia' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_quad_trot_1','art_mv_quad_trot_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_wall_trot_1','art_mv_wall_trot_2']::text[]
WHERE catalog_key = 'catalog:Rotación torácica en pared' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_wall_trot_1','art_mv_wall_trot_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_seated_trot_1','art_mv_seated_trot_2']::text[]
WHERE catalog_key = 'catalog:Rotación torácica sentado' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_seated_trot_1','art_mv_seated_trot_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Run' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Russian Twist' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]
WHERE catalog_key = 'catalog:Salto al cajón' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_sandbag_carry']::text[]
WHERE catalog_key = 'catalog:Sandbag Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_sandbag_carry']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_sandbag_carry']::text[]
WHERE catalog_key = 'catalog:Sandbag Ground To Shoulder' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_sandbag_carry']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]
WHERE catalog_key = 'catalog:Sandbag Load To Box' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]
WHERE catalog_key = 'catalog:Sandbag Lunges' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]
WHERE catalog_key = 'catalog:Sandbag Over Log' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]
WHERE catalog_key = 'catalog:Sandbag Squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_sb_clean']::text[]
WHERE catalog_key = 'catalog:Sandbag clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_sb_clean']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_sb_os']::text[]
WHERE catalog_key = 'catalog:Sandbag over shoulder' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_sb_os']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_remo_invertido']::text[]
WHERE catalog_key = 'catalog:Seal row' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_remo_invertido']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]
WHERE catalog_key = 'catalog:Seated Box Jump' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_box_jump_1','art_cf_box_jump_2','art_cf_box_jump_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_sentadilla_1','art_sentadilla_2']::text[]
WHERE catalog_key = 'catalog:Sentadilla' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_sentadilla_1','art_sentadilla_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_cossack_1','art_mv_cossack_2']::text[]
WHERE catalog_key = 'catalog:Sentadilla Cossack de movilidad' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_cossack_1','art_mv_cossack_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_prensa']::text[]
WHERE catalog_key = 'catalog:Sentadilla a cajón con mancuernas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_prensa']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_bulgara_1','art_bulgara_2','art_bulgara_3']::text[]
WHERE catalog_key = 'catalog:Sentadilla búlgara' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_bulgara_1','art_bulgara_2','art_bulgara_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_bulgara_1','art_bulgara_2','art_bulgara_3']::text[]
WHERE catalog_key = 'catalog:Sentadilla búlgara con mancuernas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_bulgara_1','art_bulgara_2','art_bulgara_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_sentadilla_1','art_sentadilla_2']::text[]
WHERE catalog_key = 'catalog:Sentadilla con safety bar' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_sentadilla_1','art_sentadilla_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_sentadilla_1','art_sentadilla_2']::text[]
WHERE catalog_key = 'catalog:Sentadilla en Smith' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_sentadilla_1','art_sentadilla_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_sentadilla_frontal_1','art_sentadilla_frontal_2']::text[]
WHERE catalog_key = 'catalog:Sentadilla frontal' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_sentadilla_frontal_1','art_sentadilla_frontal_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_pause_fs_1','art_hl_pause_fs_2']::text[]
WHERE catalog_key = 'catalog:Sentadilla frontal con pausa' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_pause_fs_1','art_hl_pause_fs_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_squat_pry_1','art_mv_squat_pry_2']::text[]
WHERE catalog_key = 'catalog:Sentadilla profunda con balanceo' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_squat_pry_1','art_mv_squat_pry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_deep_squat']::text[]
WHERE catalog_key = 'catalog:Sentadilla profunda sostenida' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_deep_squat']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_shrimp']::text[]
WHERE catalog_key = 'catalog:Shrimp squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_shrimp']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_shuttle']::text[]
WHERE catalog_key = 'catalog:Shuttle run' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_shuttle']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_plancha']::text[]
WHERE catalog_key = 'catalog:Side Plank' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_plancha']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_su']::text[]
WHERE catalog_key = 'catalog:Simples de comba' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_su']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_thruster_1','art_cf_thruster_2','art_cf_thruster_3']::text[]
WHERE catalog_key = 'catalog:Single Arm Dumbbell Thruster' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_thruster_1','art_cf_thruster_2','art_cf_thruster_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_kb_swing_1','art_cf_kb_swing_2','art_cf_kb_swing_3']::text[]
WHERE catalog_key = 'catalog:Single Arm Kettlebell Swing' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_kb_swing_1','art_cf_kb_swing_2','art_cf_kb_swing_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_thruster_1','art_cf_thruster_2','art_cf_thruster_3']::text[]
WHERE catalog_key = 'catalog:Single Arm Kettlebell Thruster' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_thruster_1','art_cf_thruster_2','art_cf_thruster_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hip_thrust_1','art_hip_thrust_2']::text[]
WHERE catalog_key = 'catalog:Single Leg Glute Bridge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hip_thrust_1','art_hip_thrust_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_rdl_1','art_rdl_2']::text[]
WHERE catalog_key = 'catalog:Single Leg Romanian Deadlift' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_rdl_1','art_rdl_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_du']::text[]
WHERE catalog_key = 'catalog:Single-Under' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_du']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_sentadilla_1','art_sentadilla_2']::text[]
WHERE catalog_key = 'catalog:Sissy squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_sentadilla_1','art_sentadilla_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_situp']::text[]
WHERE catalog_key = 'catalog:Sit-up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_situp']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Skater Jump' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_skierg']::text[]
WHERE catalog_key = 'catalog:SkiErg' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_skierg']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_skin_cat_1','art_gy_skin_cat_2']::text[]
WHERE catalog_key = 'catalog:Skin the cat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_skin_cat_1','art_gy_skin_cat_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_sled_push']::text[]
WHERE catalog_key = 'catalog:Sled Drag' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_sled_push']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_sled_pull']::text[]
WHERE catalog_key = 'catalog:Sled pull' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_sled_pull']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_sled_push']::text[]
WHERE catalog_key = 'catalog:Sled push' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_sled_push']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_sled_push']::text[]
WHERE catalog_key = 'catalog:Sledgehammer Strike' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_sled_push']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Snatch Balance' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Snatch High Pull' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Snatch Pull' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_kb_snatch_1','art_cf_kb_snatch_2','art_cf_kb_snatch_3']::text[]
WHERE catalog_key = 'catalog:Snatch kettlebell' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_kb_snatch_1','art_cf_kb_snatch_2','art_cf_kb_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_db_snatch_1','art_cf_db_snatch_2','art_cf_db_snatch_3']::text[]
WHERE catalog_key = 'catalog:Snatch mancuerna' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_db_snatch_1','art_cf_db_snatch_2','art_cf_db_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]
WHERE catalog_key = 'catalog:Snatch-Grip Deadlift' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_press']::text[]
WHERE catalog_key = 'catalog:Snatch-Grip Push Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_ring_sup']::text[]
WHERE catalog_key = 'catalog:Soporte en anillas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_ring_sup']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_sots']::text[]
WHERE catalog_key = 'catalog:Sots press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_sots']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_curl_mancuernas']::text[]
WHERE catalog_key = 'catalog:Spider curl' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_curl_mancuernas']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]
WHERE catalog_key = 'catalog:Split Snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_power_snatch_1','art_cf_power_snatch_2','art_cf_power_snatch_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_split_jerk_1','art_cf_split_jerk_2','art_cf_split_jerk_3']::text[]
WHERE catalog_key = 'catalog:Split jerk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_split_jerk_1','art_cf_split_jerk_2','art_cf_split_jerk_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_jerk']::text[]
WHERE catalog_key = 'catalog:Squat Jerk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_jerk']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_step_up']::text[]
WHERE catalog_key = 'catalog:Step-down' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_step_up']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_step_up']::text[]
WHERE catalog_key = 'catalog:Step-up al cajón' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_step_up']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_step_up_db_1','art_cf_step_up_db_2']::text[]
WHERE catalog_key = 'catalog:Step-up al cajón con doble mancuerna' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_step_up_db_1','art_cf_step_up_db_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_step_up_kb_1','art_cf_step_up_kb_2']::text[]
WHERE catalog_key = 'catalog:Step-up al cajón con kettlebell goblet' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_step_up_kb_1','art_cf_step_up_kb_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]
WHERE catalog_key = 'catalog:Stiff Legged Deadlift' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Strict Knee Raise' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Strict Knees To Chest' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_strict_press_1','art_cf_strict_press_2']::text[]
WHERE catalog_key = 'catalog:Strict press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_strict_press_1','art_cf_strict_press_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Suitcase Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_sumo_hp']::text[]
WHERE catalog_key = 'catalog:Sumo high pull' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_sumo_hp']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Superman' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_kb_amer_1','art_cf_kb_amer_2']::text[]
WHERE catalog_key = 'catalog:Swing americano' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_kb_amer_1','art_cf_kb_amer_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_kb_swing_1','art_cf_kb_swing_2','art_cf_kb_swing_3']::text[]
WHERE catalog_key = 'catalog:Swing kettlebell' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_kb_swing_1','art_cf_kb_swing_2','art_cf_kb_swing_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_ttb_1','art_cf_ttb_2','art_cf_ttb_3']::text[]
WHERE catalog_key = 'catalog:T2B' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_ttb_1','art_cf_ttb_2','art_cf_ttb_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_extension_cuad']::text[]
WHERE catalog_key = 'catalog:TKE con banda' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_extension_cuad']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_ttb_1','art_cf_ttb_2','art_cf_ttb_3']::text[]
WHERE catalog_key = 'catalog:TTB' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_ttb_1','art_cf_ttb_2','art_cf_ttb_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_tall_clean']::text[]
WHERE catalog_key = 'catalog:Tall clean' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_tall_clean']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_tall_snatch']::text[]
WHERE catalog_key = 'catalog:Tall snatch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_tall_snatch']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_thruster_1','art_cf_thruster_2','art_cf_thruster_3']::text[]
WHERE catalog_key = 'catalog:Thruster' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_thruster_1','art_cf_thruster_2','art_cf_thruster_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_thruster_kb_1','art_cf_thruster_kb_2','art_cf_thruster_kb_3']::text[]
WHERE catalog_key = 'catalog:Thruster kettlebell' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_thruster_kb_1','art_cf_thruster_kb_2','art_cf_thruster_kb_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_thruster_db_1','art_cf_thruster_db_2','art_cf_thruster_db_3']::text[]
WHERE catalog_key = 'catalog:Thruster mancuernas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_thruster_db_1','art_cf_thruster_db_2','art_cf_thruster_db_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]
WHERE catalog_key = 'catalog:Tire Flip' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_snatch_high_pull_1','art_hl_snatch_high_pull_2']::text[]
WHERE catalog_key = 'catalog:Tirón alto de arrancada' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_snatch_high_pull_1','art_hl_snatch_high_pull_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_clean_high_pull_1','art_hl_clean_high_pull_2']::text[]
WHERE catalog_key = 'catalog:Tirón alto de cargada' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_clean_high_pull_1','art_hl_clean_high_pull_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_snatch_pull_1','art_hl_snatch_pull_2']::text[]
WHERE catalog_key = 'catalog:Tirón de arrancada' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_snatch_pull_1','art_hl_snatch_pull_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hl_clean_pull']::text[]
WHERE catalog_key = 'catalog:Tirón de cargada' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hl_clean_pull']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]
WHERE catalog_key = 'catalog:Tirón de rack' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_ttb_1','art_cf_ttb_2','art_cf_ttb_3']::text[]
WHERE catalog_key = 'catalog:Toes to bar' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_ttb_1','art_cf_ttb_2','art_cf_ttb_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_strict_ttb']::text[]
WHERE catalog_key = 'catalog:Toes to bar estrictos' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_strict_ttb']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_ttr']::text[]
WHERE catalog_key = 'catalog:Toes to rings' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_ttr']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_trap_deadlift']::text[]
WHERE catalog_key = 'catalog:Trap Bar Deadlift' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_trap_deadlift']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_du']::text[]
WHERE catalog_key = 'catalog:Triple-Under' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_du']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_tu']::text[]
WHERE catalog_key = 'catalog:Triples de comba' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_tu']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Tuck Jump' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_tgu_1','art_cf_tgu_2','art_cf_tgu_3']::text[]
WHERE catalog_key = 'catalog:Turkish get-up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_tgu_1','art_cf_tgu_2','art_cf_tgu_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_vsit']::text[]
WHERE catalog_key = 'catalog:V-sit' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_vsit']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_vup_1','art_cf_vup_2']::text[]
WHERE catalog_key = 'catalog:V-up' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_vup_1','art_cf_vup_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_walk_lunge']::text[]
WHERE catalog_key = 'catalog:Walking lunge' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_walk_lunge']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_wall_walk_1','art_cf_wall_walk_2','art_cf_wall_walk_3']::text[]
WHERE catalog_key = 'catalog:Wall Climb' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_wall_walk_1','art_cf_wall_walk_2','art_cf_wall_walk_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_wall_walk_1','art_cf_wall_walk_2','art_cf_wall_walk_3']::text[]
WHERE catalog_key = 'catalog:Wall Climb Over' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_wall_walk_1','art_cf_wall_walk_2','art_cf_wall_walk_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Wall Sit' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_wall_ball_1','art_cf_wall_ball_2','art_cf_wall_ball_3']::text[]
WHERE catalog_key = 'catalog:Wall ball' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_wall_ball_1','art_cf_wall_ball_2','art_cf_wall_ball_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_wall_walk_1','art_cf_wall_walk_2','art_cf_wall_walk_3']::text[]
WHERE catalog_key = 'catalog:Wall walk' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_wall_walk_1','art_cf_wall_walk_2','art_cf_wall_walk_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_vup_1','art_cf_vup_2']::text[]
WHERE catalog_key = 'catalog:Windshield wipers' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_vup_1','art_cf_vup_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_pajaros']::text[]
WHERE catalog_key = 'catalog:Woodchop en polea' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_pajaros']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_wgs_1','art_mv_wgs_2','art_mv_wgs_3']::text[]
WHERE catalog_key = 'catalog:World''s Greatest Stretch' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_wgs_1','art_mv_wgs_2','art_mv_wgs_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_yoke']::text[]
WHERE catalog_key = 'catalog:Yoke carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_yoke']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_push_press']::text[]
WHERE catalog_key = 'catalog:Z Press' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_push_press']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_spiderman_1','art_mv_spiderman_2']::text[]
WHERE catalog_key = 'catalog:Zancada Spiderman con rotación' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_spiderman_1','art_mv_spiderman_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]
WHERE catalog_key = 'catalog:Zancada en cortesía' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]
WHERE catalog_key = 'catalog:Zancada inversa' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]
WHERE catalog_key = 'catalog:Zancadas' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]
WHERE catalog_key = 'catalog:Zancadas caminando con saco' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]
WHERE catalog_key = 'catalog:Zancadas con saco' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_hx_sb_lunge_1','art_hx_sb_lunge_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_zancada_barra_1','art_zancada_barra_2']::text[]
WHERE catalog_key = 'catalog:Zancadas inversas con barra' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_zancada_barra_1','art_zancada_barra_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]
WHERE catalog_key = 'catalog:Zercher Carry' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_cf_farmer_carry_1','art_cf_farmer_carry_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]
WHERE catalog_key = 'catalog:Zercher Deadlift' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]
WHERE catalog_key = 'catalog:Zercher Squat' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_gy_air_squat_1','art_gy_air_squat_2','art_gy_air_squat_3']::text[]);

UPDATE public.business_exercise_catalog
SET mobile_art_keys = ARRAY['art_mv_wall_angel_1','art_mv_wall_angel_2']::text[]
WHERE catalog_key = 'catalog:Ángeles en pared' AND is_active
  AND (mobile_art_keys IS NULL OR mobile_art_keys = '{}'::text[] OR mobile_art_keys <> ARRAY['art_mv_wall_angel_1','art_mv_wall_angel_2']::text[]);

