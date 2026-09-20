# 12: El watchdog

**What to build:** La garantía de que ningún cuelgue de Overink puede dejar el Mac inservible
en mitad de una clase. Con el hilo principal bloqueado no responden ni el atajo global ni Esc,
porque ambos se procesan ahí: un hilo independiente lo detecta y mata el proceso, lo que hace
desaparecer el Overlay.

ADR-0005 pone esto por encima de cualquier funcionalidad, así que puede y conviene hacerse
pronto: solo depende de que exista el estado Armed.

**Blocked by:** 02

**Status:** resolved

- [x] Un hilo independiente del principal comprueba periódicamente que este sigue respondiendo
- [x] Si no responde en cinco segundos estando en Armed, el proceso termina
- [x] Como el Canvas solo vive en memoria, terminar no pierde nada que deba conservarse
- [ ] **Verificado a mano:** bloqueando deliberadamente el hilo principal en Armed, el Overlay desaparece en unos cinco segundos y se recupera el control del Mac
- [ ] **Verificado a mano:** una sesión larga de uso normal no dispara ningún falso positivo
- [x] El código lleva un comentario que explica por qué existe y remite a ADR-0005, para que nadie lo borre por limpieza

## Comments

- Implementado `MainThreadWatchdog`: mientras el Overlay está Armed, una cola independiente
  publica un acuse en el main queue cada segundo y termina el proceso si no recibe respuesta
  en cinco segundos. Se cancela al pasar a Dismissed; el comentario de tipo remite a ADR-0005.
- Verificación automática: `swift build --target OverinkApp` completó correctamente.
  `swift test --filter OverlayStateTests` no llega a compilar por comandos de Eraser aún no
  disponibles en un cambio paralelo (`eraserDown`, `eraserMoved`, `eraserUp`), ajeno al
  watchdog. Quedan pendientes las dos verificaciones manuales del ticket.
- Verificación final: tras integrarse el cambio paralelo de Eraser, `swift test` completó
  correctamente los 18 tests. La revisión del cambio detectó y se corrigió una carrera entre
  un tick del watchdog y su cancelación al pasar a Dismissed.
