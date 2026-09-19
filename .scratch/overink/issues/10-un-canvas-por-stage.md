# 10: Un Canvas por Stage

**What to build:** Cada pantalla recuerda lo suyo. Si se dibuja en el monitor, se oculta el
Overlay, se anota en el portátil y luego se vuelve al monitor, lo del monitor sigue ahí
intacto. Una pantalla donde aún no se ha dibujado empieza limpia, sin recibir reescalado lo de
la otra.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] Cada Stage tiene su propio Canvas, independiente del de la otra pantalla
- [ ] Armar sobre un Stage donde no se ha dibujado aún muestra un Canvas vacío
- [ ] Volver a un Stage anterior recupera sus Marks intactos
- [ ] Los Marks nunca se reescalan ni se trasladan entre pantallas de distinta resolución
- [ ] Cada Stage tiene también su propio History: deshacer actúa sobre el Canvas del Stage activo y no sobre el de la otra pantalla
- [ ] Si se desconecta la pantalla de un Stage, su Canvas se descarta
- [ ] Hay tests con varios Stages inyectados que cubren el aislamiento entre Canvas y entre History
