# 01: Esqueleto de la app en la barra de menús

**What to build:** Overink arranca y se queda viva en la barra de menús, sin icono en el Dock
ni en el conmutador de aplicaciones, y se cierra desde ese mismo menú. Es la primera vez que
el proyecto produce una aplicación ejecutable, así que este ticket fija cómo se construye todo
lo demás.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] El proyecto compila con SwiftPM usando el toolchain de las Command Line Tools (Swift 6.1, macOS 15.6, arm64)
- [x] Un script ensambla la aplicación con su Info.plist y la firma ad-hoc, sin Xcode y sin ningún proyecto de Xcode en el repositorio
- [x] Al abrirla aparece un ítem en la barra de menús que indica que está viva
- [x] No aparece en el Dock ni en Cmd+Tab
- [ ] El menú ofrece una opción de salir, y funciona
- [x] No solicita ningún permiso del sistema al arrancar
- [x] El README o el propio script explica en una línea cómo construirla y dónde queda

## Comments

### Cómo se comprobó (2026-09-19)

El spec exige que cada ticket que toque un área no testeable automáticamente —aquí, el ítem de
la barra de menús— diga cómo se comprobó.

- **Toolchain**: `swift build` y `scripts/build-app.sh` en verde con Swift 6.1.2
  (`arm64-apple-macosx15.0`) sobre macOS 15.6.1. El script exporta
  `DEVELOPER_DIR=/Library/Developer/CommandLineTools` y falla si no existe, para que el
  criterio sea cierto por construcción y no por cómo esté configurado el Mac.
- **Bundle y firma**: `scripts/build-app.sh` deja `build/Overink.app` con su `Info.plist` y lo
  firma ad-hoc (`codesign --force --sign -`). No hay `.xcodeproj` en el repositorio.
- **Ítem de la barra de menús**: con la app abierta, `CGWindowListCopyWindowInfo` muestra una
  ventana de 27×24 en `Y = 0` cuyo propietario es `Overink`, es decir el `NSStatusItem` puesto.
  El menú muestra «Overink está en marcha» y «Salir de Overink».
- **Ni Dock ni Cmd+Tab**: `lsappinfo info -only ApplicationType "Overink"` devuelve
  `"UIElement"`, la política `.accessory`. Se aplica dos veces a propósito:
  `LSUIElement` en el `Info.plist` para el bundle y `setActivationPolicy(.accessory)` en
  `main.swift`, que es lo que mantiene el comportamiento al ejecutar el binario a pelo.
- **Ningún permiso**: el código no toca captura de pantalla, Accesibilidad ni monitorización de
  entrada, y el log unificado no registra ninguna petición de TCC de `dev.overink.Overink` al
  arrancar.
- **Pendiente de comprobar en persona**: hacer clic en «Salir de Overink» y ver que la app se
  va. La acción está cableada a `NSApplication.terminate(_:)` por la cadena de responders, y el
  proceso termina limpio con una señal, pero el clic no se puede simular sin permiso de
  Accesibilidad —que este ticket exige no pedir—, así que se queda sin marcar hasta que se
  verifique a mano.

### Decisiones de estructura

- Dos módulos desde el primer commit, como manda el spec: `OverinkCore` (Swift puro) y
  `OverinkApp` (la shell de AppKit).
- `OverinkCore` se queda **vacío**: el esqueleto no toma ninguna decisión que pueda vivir ahí, y
  poner algo para que el módulo "tenga algo" violaría la costura de dos operaciones que define
  el spec. Por lo mismo, no hay target de tests todavía: lo trae el ticket 02 junto con la
  primera lógica de dominio, y es ese ticket el que fija el patrón de los tests.
