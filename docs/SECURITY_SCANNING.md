# Análisis de seguridad automatizado

Última actualización: 2026-11-11

## Alcance y ejecución

- **Web y backend TypeScript/JavaScript:** `.github/workflows/codeql-web.yml`, CodeQL `javascript-typescript`; incluye la web y las funciones Supabase. El job `actions` analiza los GitHub Actions del repositorio.
- **Android y Wear OS:** `.github/workflows/codeql-android.yml`, CodeQL `java-kotlin` en modo **manual**. Compila `:domain`, `:mobile` y `:wear` con Gradle 9.6/JDK 17 y el SDK Android canary que ya usa la CI nativa. No realiza despliegues ni utiliza credenciales de Play.
- **Swift (solo contratos compatibles):** `.github/workflows/codeql-swift-contracts.yml` compila y analiza `mobile-contracts/swift` (Swift tools 6.2) con macOS/Xcode 26. **No cubre el código principal de iOS, iPadOS ni watchOS.**
- Escaneos: push y PR hacia `main`/`beta` para las rutas indicadas en cada workflow, ejecución programada los miércoles en la rama por defecto, y ejecución manual. Las tareas son independientes de los pipelines de build, TestFlight y Google Play.
- Las alertas aparecen en [Security → Code scanning](https://github.com/rmoya87/repera/security/code-scanning). El análisis utiliza `security-extended` y un token limitado a lectura de contenido, lectura de acciones y publicación de resultados de seguridad.

## Limitación crítica de Swift 6.4 / Xcode 27

A **11/11/2026**, GitHub no admite extracción trazada con **Xcode 27** ni análisis de **Swift 6.4** con CodeQL. Tanto `Apps/Repera`, `Apps/ReperaWatch` como `Packages/ReperaDomain` dependen de la toolchain actual; analizarlos con CodeQL/Xcode 27 podría dar una base de datos vacía o un resultado incompleto. **No se habilita un análisis engañoso**. El subset de contratos Swift 6.2 no sustituye una auditoría del código iOS/watchOS.

Antes de ampliar la cobertura, verificar en la [comunicación oficial de GitHub](https://github.blog/changelog/2026-10-19-codeql-changes-for-macos-27-xcode-27-and-swift-6-4/) y en la [matriz de lenguajes CodeQL](https://codeql.github.com/docs/codeql-overview/supported-languages-and-frameworks/) que Xcode/Swift usados son compatibles. Mantener mientras tanto la CI de Xcode 27 y las revisiones de seguridad manuales.

## Dependencias y otras superficies

`.github/dependabot.yml` solicita PR semanales de actualizaciones para GitHub Actions, Gradle y npm de `web/console`. No fusiona ni despliega automáticamente. La consola actualmente no declara dependencias npm, por lo que puede no generar propuestas. Las dependencias Swift configuradas en `project.yml`, Deno/Supabase y las migraciones SQL no quedan cubiertas por estas tres entradas; revisar sus avisos y versiones por separado.

CodeQL **no sustituye** las pruebas RLS multi-tenant, la revisión de SQL, los permisos Health/GPS, la protección de secretos, la comprobación de Play ni los tests funcionales. Mantener los contratos actuales.

## Activación y bloqueo de PR (administración GitHub)

1. Revisar `Security → Code scanning → Tool status` después de la primera ejecución y comprobar que cada lenguaje finaliza con resultados válidos; si existía la configuración predeterminada de CodeQL, evitar duplicarla al adoptar la avanzada.
2. En `Settings → Advanced Security`, verificar **Dependency graph**, **Dependabot alerts** y **Dependabot security updates**. El archivo de version updates **no** habilita por sí solo esas opciones.
3. En `Settings → Rules → Rulesets`, añadir una regla de **Code scanning** para los PR hacia `main` y `beta`, herramienta **CodeQL**, bloqueando alertas nuevas **High/Critical** una vez verificados los primeros análisis. Mantener la protección contra borrados y force push. Configurar esto requiere permisos de administración: añadir workflows no cambia por sí mismo las reglas del repositorio.
4. La protección de Code scanning solo actúa sobre PR, no convierte pushes directos en PR ni evita automáticamente todos los problemas de seguridad. Para exigir revisión en todos los cambios, añadir también la política de PR requerida de manera deliberada.

Para errores de análisis, ver la pestaña [Actions](https://github.com/rmoya87/repera/actions) y la página de estado de herramientas de Code scanning. No dar por verificadas plataformas que aún no han ejecutado un escaneo válido.
