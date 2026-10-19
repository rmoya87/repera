# Repera — puesta en marcha y pruebas locales (19-10-2026)

## Estado de esta rama

**Instalable hoy (si se dispone de Xcode compatible):** app iOS actual + Apple Watch existente. No se ha alterado el código de la app ni su sincronización iCloud.

**Preparado como código, NO validado ni desplegado:** migración supabase/migrations/20261019193000_secure_relationship_foundation.sql y pruebas pgTAP supabase/tests/rls_foundation_smoke.sql.

**Aún no existe en esta rama:** panel profesional, Android, sistema remoto de publicación de programas/clases/push y sincronización multi-OS. No confundir lo previsto en el plan con producto listo.

## 1. Obtener la rama

    git clone -b feature/multiplatform-foundation-20261019 https://github.com/rmoya87/repera.git
    cd repera

El repositorio es privado: se necesita sesión/autorización GitHub con permiso de lectura (SSH o Git Credential Manager si git solicita credenciales).

## 2. Test del dominio Swift existente

Requisito: Mac, Xcode + Swift Toolchain compatible con la versión del proyecto.

    cd Packages/ReperaDomain
    swift test
    cd ../..

Se espera que ejecuten las pruebas del dominio local actual. Aquí no se han ejecutado: el entorno del asistente no tiene Xcode y no ha compilado la app.

## 3. Ejecutar la app iOS en un dispositivo

Requisitos: macOS, Xcode compatible iOS 27, XcodeGen y firma Apple configurada para com.app.repera.

    xcodegen generate
    open Repera.xcodeproj

Elegir el esquema Repera y un iPhone de prueba/simulador compatible. Comprobar onboarding, login Apple, crear entrenamiento offline, series y progreso, Ajustes > cerrar sesión y volver a entrar, y funcionamiento de compra **solo** en sandbox/TestFlight.

**Importante:** la app iOS seguirá usando JSON local + iCloud. No se conectará automáticamente al backend de esta rama; la migración de identidad/sync forma parte de las siguientes fases. No borrar los datos de la app existente durante los ensayos.

## 4. Levantar una instancia local aislada de Supabase

Requisitos: Docker Desktop en marcha y versión actual de Supabase CLI. No enlazar la CLI al proyecto Cafesito. Nunca ejecutar db reset ni push sobre Supabase remoto.

    supabase --version
    supabase --help
    supabase init
    supabase start
    supabase db reset
    supabase test db

- Si ya existe configuración local, omitir `supabase init`; conservar migraciones existentes.
- Consultar el `--help` de los comandos antes de usarlos por diferencias entre versiones de CLI.
- `supabase db reset` afecta la **base local** cuando no se pasan opciones de conexión remota. Confirmar el destino antes de ejecutar.
- `supabase test db` ejecuta nueve aserciones pgTAP para permisos de perfiles, entrenamientos y relaciones. Debe devolver **9 casos correctos**; cualquier error bloquea la siguiente fase.
- El archivo de pruebas es transaccional: inserta identificadores de test y hace ROLLBACK. Ejecutar solo contra base local desechable.
- Si la creación inicial de usuarios de prueba o permisos cambia con la versión de Supabase, adaptar el fixture y documentar el cambio; nunca desactivar RLS para 'hacer pasar' una prueba.

**No validado aún:** se ha revisado la sintaxis y el texto de forma estática, pero no se dispone aquí de Docker ni de servidor PostgreSQL/Supabase para confirmar el resultado.

## 5. Criterios de aceptación de la primera fase

- La migración base inicial y la de seguridad aplican sin errores en una base limpia.
- Atleta A no puede consultar ni alterar entrenos del atleta B.
- Un coach no ve historial de su cliente si no ha consentido, aunque exista contrato.
- Un coach con consentimiento y relación activa sí puede consultar ese historial.
- Un manager de gimnasio no puede ver entrenos personales de socios.
- Un usuario no vinculado no puede consultar las relaciones de otros.
- Suspender a un coach revoca inmediatamente su lectura.
- Un usuario no puede asignarse un rol de empresa, modificar consentimientos o crear relaciones sin pasar por un servicio autorizado.
- El equipo confirma permisos SQL además de RLS y pasa Supabase Advisors.
- La app iOS existente sigue arrancando, registrando entrenamientos y ofreciendo exportación sin cambios de datos.

Las comprobaciones negativas de escritura y Advisors se ampliarán en el siguiente lote; los nueve tests actuales validan **lectura** y revocación.

## 6. Próximos incrementos con pruebas reales

1. Identidad Supabase verificada y migración no destructiva del estado iCloud (prueba real iPhone).
2. Publicar programa entrenador web > recibir programa en móvil > notificación tras publicación, sin filtrar datos.
3. Calendario gimnasio > reserva atómica > cancelación, aforo y push.
4. Android Compose interoperable con el mismo backend, tests en ambos SO y migración desde iOS.
5. Facturación, analíticas, QA y despliegues; tarifa profesional queda por decidir.

Para cada incremento: commit separado, criterio de aceptación verificable, ejecutable localmente y sin marcarlo «hecho» antes de ejecutar tests.
