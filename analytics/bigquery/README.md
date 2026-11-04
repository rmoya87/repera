# BigQuery — consultas Analytics Repera

**Última actualización:** 2026-11-04

Estas consultas asumen exportación GA4 → BigQuery ya vinculada. Sustituir ``PROJECT.DATASET`` por el dataset real.

| Archivo | Uso |
| --- | --- |
| `01_workouts_completed.sql` | Sesiones guardadas |
| `02_top_sports.sql` | Ranking `activity_type` |
| `03_class_funnel.sql` | Reservas vs asistencia |
| `04_platforms_and_watch.sql` | Plataformas + ACK reloj |

Hasta que existan eventos reales en producción, los resultados estarán vacíos; no inventar métricas.
