# 11: Auto-Dismiss a los quince minutos

**What to build:** Que un olvido no deje el Overlay puesto el resto de la tarde: tras quince
minutos en Armed sin un solo evento de entrada, se oculta solo. Como ocultar nunca destruye
trabajo, si salta mientras se está escribiendo un Label, el Label se confirma en vez de
perderse.

Es una red de seguridad secundaria y deliberadamente floja: cubre el olvido, no el cuelgue. Lo
que protege de un cuelgue es el ticket 12.

**Blocked by:** 08

**Status:** resolved

- [x] Quince minutos en Armed sin ningún evento de entrada pasan el Overlay a Dismissed
- [x] Cualquier evento de entrada reinicia la cuenta desde cero
- [x] Si salta durante Editing, el Label en curso se confirma antes de ocultar
- [x] El Canvas se conserva entero, igual que en cualquier otro paso a Dismissed
- [x] En Dismissed no se cuenta nada
- [x] Los tests avanzan el instante inyectado y comprueban los quince minutos sin esperas reales

## Answer

Implementado en el core determinista mediante `timeTick` e `Instant` inyectado: tras quince
minutos sin entrada pasa a Dismissed, confirma el Label en Editing y conserva el Canvas. La
shell mantiene un único timer de quince minutos solo mientras el Overlay está visible y lo
reinicia ante cualquier entrada recibida.

Verificado con `swift test` (35 tests) y `swift build`. La duración real del timer de AppKit no
se espera manualmente; la semántica de los quince minutos se cubre en los tests del core.
