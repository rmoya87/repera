# Inicio de sesión Google · Repera iOS

Repera mantiene Sign in with Apple e incorpora Google mediante `supabase-swift`, con el diálogo seguro **ASWebAuthenticationSession** del sistema iOS. No se añade un secreto OAuth al binario. Los dos accesos deben resolver el mismo `auth.users.id` para poder leer el mismo historial personal de Supabase.

## Configuración necesaria en Supabase

1. En [Supabase Auth · Google](https://supabase.com/dashboard/project/uvzgujlrqohreoucirms/auth/providers) confirmar que Google está habilitado (según la configuración indicada por el usuario).
2. En **Authentication → URL Configuration → Redirect URLs** permitir exactamente `repera://auth/callback`. Esta URI está declarada en `Apps/Repera/Resources/Info.plist` y `project.yml` (XcodeGen).
3. Para vinculación explícita iniciada desde Apple, habilitar **Authentication → Settings → Enable Manual Linking**; no es necesaria para el enlace automático por el mismo correo verificado.
4. El proveedor Google debe usar el callback **Supabase** `https://uvzgujlrqohreoucirms.supabase.co/auth/v1/callback` en Google Cloud, no la URI de la app.

## Comportamiento de la app

- En login están Apple y **Continuar con Google**. `BusinessAuthStore.signInWithGoogle()` obtiene una sesión Supabase con Google y contrasta `session.user.id` con el propietario de datos locales guardado tras el anterior acceso.
- Si Apple/Google representan el mismo correo **verificado** y Supabase los enlaza, se conserva el **mismo UUID**, perfil Supabase, suscripciones y datos remotos sometidos a RLS.
- Si no coinciden, **no** se reutiliza el historial local ni se copian resultados, y se rechaza el acceso con indicación de utilizar Apple para la vinculación. No existe SQL de fusión de cuentas.
- En **Ajustes → Cuenta → Vincular cuenta de Google**, con Apple autenticado, la app abre el OAuth en una ventana de autenticación del sistema, confirma su retorno e inspecciona que el UUID sigue siendo el mismo antes de dar éxito. Útil cuando Apple oculta el correo real.
- En logout se revoca el token remoto y se conserva solo la referencia no secreta del UUID propietario del historial, para evitar mezcla entre usuarios en el mismo dispositivo.
- **iCloud Documents es un almacenamiento distinto de Supabase:** utilizar Google no permite por sí solo abrir un contenedor iCloud perteneciente a otro Apple ID. La misma cuenta Supabase da acceso al historial remoto sincronizado que exista en Repera; para migrar historial exclusivamente local/iCloud entre Apple IDs hace falta otro flujo explícito, no implementado por este cambio.

## Validación E2E pendiente

Probar en un iPhone real con: (a) Apple con correo visible + Google con el mismo correo verificado → mismo UUID; (b) Apple con correo privado → vincular Google desde Cuenta; (c) Google diferente → acceso rechazado sin revelar entrenamientos; (d) salir y entrar, recuperar Supabase sin repetir el onboarding. Verificar además que al cerrar el diálogo OAuth no se cambie el usuario.

Este documento no acredita que la configuración del Dashboard ni estos flujos interactivos hayan podido verificarse desde el repositorio; son comprobaciones necesarias antes de publicar en TestFlight.
