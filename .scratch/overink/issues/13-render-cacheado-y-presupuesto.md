# 13: Render cacheado y presupuesto de recursos

**What to build:** Que el trazo siga yendo fino con la pizarra llena, y que Overink no le robe
CPU a la videollamada mientras se comparte la pantalla. Las cuatro cifras de ADR-0006 dejan de
ser una intención y pasan a estar medidas.

**Blocked by:** 06

**Status:** ready-for-agent

- [ ] Los Marks ya terminados se consolidan en una capa cacheada
- [ ] En cada frame solo se repinta el Stroke en curso
- [ ] En Dismissed no corre ningún timer ni display link
- [ ] **Medido:** 0% de CPU en Dismissed
- [ ] **Medido:** por debajo de 150 MB con los Canvas de ambos Stages llenos
- [ ] **Medido:** latencia del trazo por debajo de 16 ms
- [ ] **Medido:** el coste por frame no crece de forma apreciable entre un Canvas vacío y uno lleno
- [ ] Las mediciones quedan anotadas para poder compararlas más adelante
