# 06: Highlighter y los cuatro colores

**What to build:** Cambiar de herramienta y de color sin parar la explicación, con una tecla
cada uno. Entra el Highlighter, translúcido y ancho, para resaltar sin tapar lo que hay
debajo.

**Blocked by:** 05

**Status:** resolved

- [x] P, H y E seleccionan Pen, Highlighter y Eraser
- [x] Las teclas 1 a 4 seleccionan el color de la Palette
- [x] El Highlighter produce Strokes translúcidos y más anchos que el Pen
- [x] Un mismo Stroke de Highlighter no se oscurece donde se cruza consigo mismo
- [x] El color seleccionado aplica a Pen, Highlighter y, más adelante, a los Labels
- [ ] **Pendiente de comprobar en persona:** los cuatro colores se leen sobre un editor de código oscuro y sobre una página web blanca
- [x] Hay tests de selección de Tool y de color, y de que el color activo es el que reciben los Marks nuevos

## Comments

### Verificación (2026-09-20)

- `swift test` pasa completo (25 tests) y `swift build` termina en verde.
- Los tests del core cubren la selección de Tool, el color activo en Pen y Highlighter, y el
  grosor/opacidad del Highlighter.
- El render de AppKit usa composición `.copy` para los Strokes translúcidos: las regiones de
  un mismo path que se superponen no acumulan alpha.
- Falta la comprobación visual presencial sobre las dos superficies indicadas; no se marca
  como hecha para no fingir esa validación manual.
