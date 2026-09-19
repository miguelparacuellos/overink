# 11: Auto-Dismiss a los quince minutos

**What to build:** Que un olvido no deje el Overlay puesto el resto de la tarde: tras quince
minutos en Armed sin un solo evento de entrada, se oculta solo. Como ocultar nunca destruye
trabajo, si salta mientras se está escribiendo un Label, el Label se confirma en vez de
perderse.

Es una red de seguridad secundaria y deliberadamente floja: cubre el olvido, no el cuelgue. Lo
que protege de un cuelgue es el ticket 12.

**Blocked by:** 08

**Status:** ready-for-agent

- [ ] Quince minutos en Armed sin ningún evento de entrada pasan el Overlay a Dismissed
- [ ] Cualquier evento de entrada reinicia la cuenta desde cero
- [ ] Si salta durante Editing, el Label en curso se confirma antes de ocultar
- [ ] El Canvas se conserva entero, igual que en cualquier otro paso a Dismissed
- [ ] En Dismissed no se cuenta nada
- [ ] Los tests avanzan el instante inyectado y comprueban los quince minutos sin esperas reales
