# Matriz de licencia — fuentes de catálogo

Última actualización: 2026-11-04. Verificar de nuevo antes de un lote grande; no sustituye asesoría legal.

| Fuente | Texto / metadatos | Imágenes / GIF | Uso comercial Repera | Atribución | Decisión |
|--------|-------------------|----------------|----------------------|------------|----------|
| **Free Exercise DB** (`yuhonas/free-exercise-db`) | Unlicense / dominio público del dataset JSON | **Dudosas** (autor indica origen desconocido; issues apuntan a posibles derechos de terceros / ExRx) | Texto: sí. Media: **no** | No requerida por Unlicense | **Usar solo JSON.** Arte propio Repera |
| **Open WOD Database** (`WodWiz/open-wod-db`) | CC BY 4.0 | No usamos sus assets gráficos | Sí, con crédito | «Open WOD Database», https://www.wodwiz.com/benchmarks (CC BY 4.0) | **Usar movimientos** (+ WODs en track aparte) |
| **OpenExerciseDB** (`rfivesix/OpenExerciseDB`) | CC BY-SA 4.0 (derivado en parte de wger) | No importar | Sí, con atribución y share-alike sobre **obras derivadas** del dataset | Según `ATTRIBUTION.md` del proyecto | **Enriquecer traducciones/taxonomía**; evaluar SA sobre paquetes derivados |
| **RepDB** (`RepDB/exercise-dataset`) | Free tier: uso in-app OK; **no** redistribuir como dataset/API; **prohibido** usar imágenes para gen-AI / restyle | Flat WebP en free; stills/animaciones = pago | Free: comercial **con** crédito visible «Exercise data by RepDB (repdb.co)». Paid Standard (~$499): sin atribución obligatoria, sin white-label (Enterprise aparte). **B2B Repera Business / white-label de centros** → Enterprise | Free: obligatoria. Paid: opcional | **Texto/metadatos free OK** con atribución documentada aquí (el pie in-app de Ajustes se retiró 10/11/2026). **No** importar su arte (política ExerciseArt + cláusula anti–gen-AI). No publicar mirror/feed bulk del JSON RepDB. Fase G (+6) aplicada 2026-11-04 |
| **Kinetic Exercises** (`kinetic-place/exercises-json`, CLI/API MIT) | **MIT** en código/dataset JSON (~899, EN/ES) | Marketplace también vende **vídeo premium** aparte; no asumir que todo el media del site es MIT | Texto JSON: sí (MIT). Media premium: no sin compra | Conservar aviso MIT en distribuciones del Software | **Texto/taxonomía OK** (mismo pipeline que FED: dedupe + palabras propias + arte Repera). **No** embebidos de animaciones/vídeo de terceros. Candidato a Fase F selectiva |

## Regla Repera

- Procedencia y licencia se registran por ejercicio/campo editorial (`source_refs`).
- Media = siempre pipeline ExerciseArt Repera (`ART_STYLE.md`).
- Customs de usuario/entrenador no entran al catálogo global.
- RepDB free: si se usa texto, crédito visible en About/créditos de la app.
- Kinetic: preferir JSON MIT; nunca gen-AI a partir de stills/vídeo de terceros.
