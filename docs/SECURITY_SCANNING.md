# Seguridad y escaneo automático de Repera

Última actualización: 2026-11-11

## Estado confirmado

**CodeQL Default setup ya está activado en GitHub.** Se confirmó el 11/11/2026 cuando los escaneos avanzados de la PR [#246](https://github.com/rmoya87/repera/pull/246) intentaron publicar resultados y GitHub los rechazó con `CodeQL analyses from advanced configurations cannot be processed when the default setup is enabled`. No se debe subir a `main` un workflow CodeQL avanzado sin desactivar antes el modo predeterminado.

Ver el estado actual y los lenguajes realmente analizados en [Security → Code scanning](https://github.com/rmoya87/repera/security/code-scanning), sección **Tool status**. La presencia del modo automático **no acredita** cobertura completa de iOS, Android o backend.

## Dependencias (activado en código)

`.github/dependabot.yml` solicita PR semanales para:
- GitHub Actions (lunes a las 06:30).
- Gradle bajo `android/` (lunes a las 07:00).
- npm bajo `web/console/` (lunes a las 07:30).

No existe fusión ni despliegue automático. La consola no declara dependencias npm actualmente. Para obtener alertas de vulnerabilidades en dependencias, comprobar en `Settings → Advanced Security` que **Dependency graph**, **Dependabot alerts** y **Dependabot security updates** están habilitados: el YAML de actualizaciones de versión no basta para activarlos.

## Mejora avanzada preparada, pendiente de cambio administrativo

La PR [#246](https://github.com/rmoya87/repera/pull/246) prepara jobs independientes para:
- CodeQL **JavaScript/TypeScript y GitHub Actions**.
- CodeQL **Kotlin/Java** compilando Android/Wear con Gradle y SDK Android 17.
- CodeQL **Swift 6.2** limitado al paquete `mobile-contracts/swift`.

**No fusionar la PR mientras Default setup esté activo**; causaría fallos en las tareas CodeQL. Para cambiar:
1. Entrar en [Settings → Advanced Security](https://github.com/rmoya87/repera/settings/security_analysis).
2. En **CodeQL analysis** abrir el menú de tres puntos, elegir **Switch to advanced**, confirmar **Disable CodeQL**.
3. Una vez desactivado el modo predeterminado, validar y fusionar la PR de configuración avanzada; comprobar que los escaneos publiquen resultados válidos en Tool status.

La interfaz requiere permisos de administración; **no se ha cambiado esta opción de seguridad del repositorio** desde el conector.

## Limitación actual de Swift

Desde el [aviso oficial de GitHub de 19/10/2026](https://github.blog/changelog/2026-10-19-codeql-changes-for-macos-27-xcode-27-and-swift-6-4/), CodeQL **no soporta Swift 6.4 ni el trazado en Xcode 27**. Repera utiliza esa toolchain para iOS/watchOS y `Packages/ReperaDomain`. No configurar un análisis que parezca completo: el job Swift 6.2 de la PR solo cubre contratos compatibles, no las apps ni el dominio.

## Política de bloqueo

El ruleset [Proteger main y beta](https://github.com/rmoya87/repera/rules/26992371) evita borrados y reescritura del historial, pero **no bloquea nuevas alertas graves**. Cuando CodeQL ofrezca resultados estables, añadir una regla **Code scanning** para bloquear alertas nuevas de severidad **High/Critical** en PR hacia `main` y `beta`, y evaluar exigir PR/revisiones. Esto requiere configuración administrativa separada.

CodeQL tampoco sustituye la revisión de RLS, secretos, permisos Health/GPS, migraciones SQL y pruebas de aplicación existentes.
