# 10: Un Canvas por Stage

**What to build:** Cada pantalla recuerda lo suyo. Si se dibuja en el monitor, se oculta el
Overlay, se anota en el portátil y luego se vuelve al monitor, lo del monitor sigue ahí
intacto. Una pantalla donde aún no se ha dibujado empieza limpia, sin recibir reescalado lo de
la otra.

**Blocked by:** 03

**Status:** resolved

- [x] Cada Stage tiene su propio Canvas, independiente del de la otra pantalla
- [x] Armar sobre un Stage donde no se ha dibujado aún muestra un Canvas vacío
- [x] Volver a un Stage anterior recupera sus Marks intactos
- [x] Los Marks nunca se reescalan ni se trasladan entre pantallas de distinta resolución
- [x] Cada Stage tiene también su propio History: deshacer actúa sobre el Canvas del Stage activo y no sobre el de la otra pantalla
- [x] Si se desconecta la pantalla de un Stage, su Canvas se descarta
- [x] Hay tests con varios Stages inyectados que cubren el aislamiento entre Canvas y entre History

## Comments

### Implementación (2026-09-20)

- `OverinkCore` conserva un `StageContent` (Canvas + History) por `StageID`; el estado
  visible solo expone el Canvas del Stage Armed. Por ello los Marks conservan sus coordenadas
  originales y nunca se trasladan ni reescalan al cambiar de pantalla.
- La shell observa `NSApplication.didChangeScreenParametersNotification` y comunica los
  Stages disponibles al core, que descarta el contenido de los desconectados y pasa a
  Dismissed si el Stage Armed desaparece.
- Verificado con los tres tests multi-Stage focalizados, `swift build` y `swift test`
  (21 tests correctos). La revisión de estándares y de especificación no encontró
  incumplimientos.
