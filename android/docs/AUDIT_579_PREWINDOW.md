# Auditoría de los 579 commits anteriores a la ventana leída

Definición exacta (reconstruida y verificada 27oct 10:09 CET): la petición del usuario cubre
"últimos 3 días" = commits alcanzables desde bd4d7637 (fin de ventana, 26oct 17:28) con fecha
>= 2026-10-23T00:00:00+02:00: 892 en total. De ellos, 313 son POST-fc3ef7e1 (la ventana leída en
detalle) y **579 son anteriores a fc3ef7e1** (`git rev-list --count fc3ef7e1 --since=2026-10-23T00:00:00+02:00` = 579).

Hecho estructural: android/ NUNCA existe en la historia de main (0 commits). Los ports Android
viven en feat/android-wear-native-parity y debug/gesture-pinch como commits separados; ningún
commit Apple de la era Android contiene su port en el mismo commit.

Matriz: AUDIT_579_PREWINDOW_MATRIX.csv (commit|fecha|subject|áreas|candidatos_heurísticos|status).
- Áreas: ios-app 289, docs-tests 114, other 118, packages 103, watch 11.
- `candidate_android_ports_heuristic`: commits Android cuyo subject comparte tokens (>=3 comunes o
  >=2 con uno distintivo >=6 chars). ES SOLO UNA PISTA: no verifica cobertura. 315/579 con candidato,
  264 sin candidato.
- Toda fila nace `unverified`. Verificar = leer el diff Apple y comparar con el árbol Android real.
- Sin-candidato incluye mucho trabajo solo-iOS esperado (launch storyboard, mascot/art CI, XcodeGen,
  ActivityKit, OAuth onboarding, supabase migrations) pero también candidatos de paridad reales a
  revisar primero (dominio: alias de búsqueda con acentos, 1RM nunca desde metros/kcal, objetivos por
  serie sin calentamiento, valores prescritos siguiente serie, splits por km con pausas, GPX turn
  detection 30m...).

Prioridad de revisión: (1) packages (lógica de dominio), (2) ios-app con lógica no visual,
(3) watch, (4) docs-tests/other (la mayoría no portable).
