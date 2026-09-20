# 05: Borrar Marks con el Eraser

**What to build:** Poder quitar algo de la pizarra pasando el lápiz por encima, sin tener que
repasarlo entero: rozar un trazo lo elimina completo. Y si uno se pasa borrando, se deshace.

**Blocked by:** 04

**Status:** resolved

- [x] El Eraser elimina por completo cada Mark que toca
- [x] No borra fragmentos ni deja trozos de un Mark: o está entero o no está
- [x] El Eraser no produce ningún Mark propio
- [x] Cada borrado es una operación del History y se deshace con Cmd+Z
- [x] Rozar varios Marks en un mismo gesto los elimina todos
- [x] Hay tests de borrado, de que no quedan fragmentos y de deshacer un borrado

## Comments

### Verificación (2026-09-20)

- `swift test --filter OverinkCoreTests.elEraserEliminaEnteroElStrokeQueRoza`,
  `...elEraserEliminaTodosLosMarksQueRozaEnUnGesto`,
  `...unGestoDelEraserNoCreaNingunMark` y
  `...undoDevuelveEnteroElMarkEliminadoPorElEraser` pasan.
- La suite completa y `swift build` se ejecutaron en verde.

### Implementación

- El core recibe un gesto semántico de Eraser y prueba cada segmento del gesto contra los
  Strokes del Canvas. Un contacto elimina el Mark entero; el gesto nunca crea uno propio.
- Cada Mark eliminado se registra como una operación `remove` del History, de modo que
  Cmd+Z restaura el Mark completo. La selección de la Tool y la traducción de eventos de la
  shell llegan en el ticket 06, que depende de este.
