# 09: El HUD con Tool y color activos

**What to build:** Un indicador fijo en una esquina que diga qué herramienta y qué color están
seleccionados, para no descubrir el error al empezar el trazo. Lo ve también el alumno, porque
forma parte de la pantalla compartida, así que debe ser discreto.

**Blocked by:** 06

**Status:** resolved

- [x] Mientras el Overlay está en Armed, el HUD es visible en una esquina
- [x] Muestra la Tool activa y el color activo
- [x] Se actualiza en el momento en que se pulsa el atajo correspondiente
- [x] En Dismissed no se ve nada
- [x] No es interactivo: solo informa, no se clica
- [x] Es lo bastante discreto para convivir con una clase compartida a pantalla completa

## Answer

El HUD se pinta como una cápsula semitransparente en la esquina superior derecha del
`OverlayView`. Muestra el nombre de la Tool y un indicador visual y numérico del color.
`OverlayController` actualiza ambos valores al sincronizar cada comando, por lo que los
atajos se reflejan en el mismo ciclo de UI. Al pasar a Dismissed se libera toda la ventana,
incluido el HUD. No se instaló ningún control ni manejador específico del HUD: es solo pintura.

## Manual verification

- `swift build` y `scripts/build-app.sh` completaron correctamente.
- `swift test` completó correctamente: 34 tests.
- La shell AppKit no tiene pruebas automáticas por decisión explícita del repositorio
  (`README.md`). Se intentó abrir el bundle para inspección visual, pero la sesión de UI fue
  interrumpida antes de recibir la captura; queda por comprobar visualmente en macOS que la
  cápsula resulta suficientemente discreta sobre una pantalla compartida.

## Review

Revisión local de spec y estándares: el HUD consume únicamente `Tool` y `PaletteColor` ya
expuestos por el core, se actualiza en ambos estados Armed/Editing y no introduce decisiones
de dominio en la shell. No se detectaron incumplimientos ni scope creep. Las dos revisiones
independientes prescritas por `code-review` no pudieron iniciarse porque todos los slots de
subagentes estaban ocupados por los tickets concurrentes.
