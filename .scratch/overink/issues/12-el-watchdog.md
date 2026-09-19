# 12: El watchdog

**What to build:** La garantía de que ningún cuelgue de Overink puede dejar el Mac inservible
en mitad de una clase. Con el hilo principal bloqueado no responden ni el atajo global ni Esc,
porque ambos se procesan ahí: un hilo independiente lo detecta y mata el proceso, lo que hace
desaparecer el Overlay.

ADR-0005 pone esto por encima de cualquier funcionalidad, así que puede y conviene hacerse
pronto: solo depende de que exista el estado Armed.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Un hilo independiente del principal comprueba periódicamente que este sigue respondiendo
- [ ] Si no responde en cinco segundos estando en Armed, el proceso termina
- [ ] Como el Canvas solo vive en memoria, terminar no pierde nada que deba conservarse
- [ ] **Verificado a mano:** bloqueando deliberadamente el hilo principal en Armed, el Overlay desaparece en unos cinco segundos y se recupera el control del Mac
- [ ] **Verificado a mano:** una sesión larga de uso normal no dispara ningún falso positivo
- [ ] El código lleva un comentario que explica por qué existe y remite a ADR-0005, para que nadie lo borre por limpieza
