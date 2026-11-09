# Comparativas de fuerza de Repera — fase de dominio (2026-11-09)

## Alcance aprobado
- **A**: progresión adaptativa de cargas, sin incrementos indefinidos, con RIR/RPE, historial, fatiga y recuperación cuando sean fiables. Reutilizar la UI existente.
- **B**: comparaciones de WOD con igualdad de estructura, modalidad y escalado.
- **C**: recuperación/carga **solo Pro**.
- **D**: récords personales, ampliando el sistema actual.
- **E**: informe mensual **excluido**.
- **F**: compartir resultados **aplazado**.
- **Business fuera del alcance**.

## Referencias externas: primera fase técnica
`StrengthBenchmarkEngine` añade un motor puro al dominio Swift. Solo compara **1RM reales de competición** de sentadilla, banca y peso muerto con distribuciones agregadas previamente importadas de OpenPowerlifting. No confundir con e1RM de gimnasio. La comparación exige sexo/categoría, modalidad de equipamiento, intervalo de edad, intervalo de peso corporal y fuente/versionado. Muestra el tamaño de muestra y rechaza referencias con menos de 100 registros, cohortes solapadas, cuantiles inválidos y extrapolación fuera de los datos.

**No hay dataset incluido todavía**: no presentar percentiles en UI hasta descargar el CSV oficial, depurarlo, deduplicar por atleta y ejercicio en cada cohorte, producir agregados trazables y verificar licencia/frescura. La app no debe descargar datos personales de competidores. No inventar percentiles para ejercicios sin fuente.

Fuente: https://openpowerlifting.gitlab.io/opl-csv/introduction.html (datos de competición en dominio público; atribución recomendada).

## Próximas etapas antes de publicar
1. Crear importador reproducible de CSV y tests con fixtures, filtrando marcas válidas, modalidad y resultados positivos; documentar sesgo competitivo.
2. Distribuir agregados versionados sin PII, con control de muestras pequeñas, y añadir un mapper seguro desde ejercicios canónicos.
3. Integrar «Tu nivel» en detalle de ejercicio/Progreso existentes con estado «sin referencia» y aclaración de que la cohorte son competidores, no población general.
4. Llevar cálculo equivalente a Android; comprobar paridad de percentiles con fixtures compartidos.
5. Reforzar `ProgressionEngine` sin sustituir políticas elegidas: evitar aumentos repetidos sin nuevas sesiones, considerar RIR/fatiga/recuperación y no modificar la prescripción sin confirmación.
6. Añadir comparador de WOD y ampliar PRs; recuperar métricas Pro mediante los derechos existentes.
7. Compilar iOS/Android, ejecutar tests y probar en dispositivos antes de integrar.

## Estado
Implementado **solo el motor Swift y sus tests de unidad**. No integrado en UI, no importación de datos, no comparaciones en producción, no nuevas funciones Pro desplegadas. La aprobación del alcance no sustituye validación ni pruebas.

## Implementaciones añadidas en la misma rama (2026-11-09)

- Importador reproducible `scripts/build_strength_benchmarks.py`: lee un CSV local de OpenPowerlifting, conserva únicamente la mejor marca válida por identidad normalizada y cohorte, elimina cohortes de menos de 100 registros y exporta únicamente cuantiles agregados. **No se ha importado ningún CSV real ni se ha publicado un dataset.** La identidad por nombre no resuelve homónimos ni cambios de nombre; revisar metodología antes de mostrar percentiles.
- Paridad de cálculo Android: `StrengthBenchmarkEngine.kt`, con el mismo filtrado conservador de cohortes, muestras y límites que Swift. Todavía falta probar paridad numérica con fixtures comunes.
- Comparación conservadora de WOD en dominio Swift: `WODComparisonEngine.swift`. Requiere formato, modalidad RX/escalado, prescripción, ejercicios ordenados, cargas y condiciones equivalentes. Solo calcula diferencias de repeticiones AMRAP o tiempo de WOD completados; sin UI y sin persistencia nueva.
- Test de importación con atletas sintéticos: `tests/test_strength_benchmark_import.py`. No contiene datos reales.

**Importante:** ni el motor Swift ni el Android distinguen por sí mismos una marca real de competición de un e1RM. Sus métodos aceptan únicamente valores que el llamador ya haya verificado como marcas de competición; bloquear la integración de UI hasta tener procedencia verificable. El motor de WOD tampoco debe usarse para resultados escalados sin registrar explícitamente RX/escalado.
