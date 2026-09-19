# Overink

Una capa de anotación para macOS: dibujar a mano alzada sobre lo que ya hay en pantalla,
sin cambiar de aplicación. Ver `CONTEXT.md` para el vocabulario y `docs/adr/` para las
decisiones.

## Construir y ejecutar

```sh
scripts/build-app.sh && open build/Overink.app
```

El script compila con SwiftPM forzando el toolchain de las Command Line Tools, ensambla
`build/Overink.app` con su `Info.plist` y la firma ad-hoc. No hace falta Xcode y no hay
proyecto de Xcode en el repositorio.

Overink vive solo en la barra de menús: no aparece en el Dock ni en Cmd+Tab, y se sale
desde su propio menú.

## Desarrollo

`swift build` compila los dos módulos sin ensamblar el bundle, que es lo cómodo mientras
se escribe código. `swift test` llegará con los primeros tests de `OverinkCore`.

El proyecto son dos módulos: `OverinkCore`, Swift puro con el modelo y la lógica, y
`OverinkApp`, la shell de AppKit que traduce eventos a comandos del core y pinta el
resultado.
