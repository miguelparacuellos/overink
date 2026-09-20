# 13: Render cacheado y presupuesto de recursos

**What to build:** Que el trazo siga yendo fino con la pizarra llena, y que Overink no le robe
CPU a la videollamada mientras se comparte la pantalla. Las cuatro cifras de ADR-0006 dejan de
ser una intención y pasan a estar medidas.

**Blocked by:** 06

**Status:** ready-for-human

- [x] Los Marks ya terminados se consolidan en una capa cacheada
- [x] En cada frame solo se repinta el Stroke en curso
- [x] En Dismissed no corre ningún timer ni display link
- [ ] **Medido:** 0% de CPU en Dismissed
- [ ] **Medido:** por debajo de 150 MB con los Canvas de ambos Stages llenos
- [ ] **Medido:** latencia del trazo por debajo de 16 ms
- [ ] **Medido:** el coste por frame no crece de forma apreciable entre un Canvas vacío y uno lleno
- [x] Las mediciones quedan anotadas para poder compararlas más adelante

## Answer

`OverlayView` cachea los Marks terminados en un bitmap con escala del Stage e invalida esa capa
solo al cambiar el Canvas, el tamaño o la escala. Los frames que siguen a un movimiento
componen ese bitmap y solo dibujan el contenido vivo. La shell ya detenía el watchdog, los dos
timers y soltaba la ventana en Dismissed; se verificó por inspección de `syncWindow()`.

El protocolo y la tabla para mantener las cuatro mediciones están en
`docs/mediciones-recursos.md`. Esta sesión no tiene dos Stages físicos ni una sesión gráfica
interactiva para producir cifras válidas, por lo que queda pendiente de validación humana antes
de completar las cuatro mediciones abiertas; no se han fabricado resultados.
