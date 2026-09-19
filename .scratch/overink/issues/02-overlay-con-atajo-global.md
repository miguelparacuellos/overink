# 02: El Overlay aparece y desaparece con el atajo

**What to build:** Desde cualquier aplicación, pulsar el atajo global monta un Overlay
transparente sobre la pantalla donde está el cursor; volver a pulsarlo, o pulsar Esc, lo
quita. Mientras está puesto, la aplicación de debajo no recibe nada.

Este ticket resuelve además el riesgo que el spec señala como el primero a despejar: si existe
un nivel de ventana que cubra la barra de menús y el Dock y **a la vez** deje que las alertas
del sistema aparezcan por encima. Se comprueba probándolo, no leyendo documentación.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Ctrl+Option+D alterna entre Armed y Dismissed desde cualquier aplicación
- [ ] El atajo se registra sin requerir permiso de Accesibilidad ni ningún otro permiso de TCC
- [ ] El Overlay cubre la pantalla que contenía el cursor en el instante de pasar a Armed
- [ ] El Stage no cambia aunque el cursor se mueva a la otra pantalla mientras sigue en Armed
- [ ] En Armed, la aplicación de debajo no recibe ni ratón ni teclado
- [ ] Esc pasa a Dismissed
- [ ] **Verificado a mano:** con el Overlay puesto, Cmd+Option+Esc muestra su diálogo por encima del Overlay
- [ ] Si no existe ningún nivel que cumpla ambas cosas, gana ADR-0005: se sacrifica la cobertura de la barra de menús, se deja anotado en el ADR y se explica el porqué
- [ ] No se activa `.disableForceQuit`, `.disableProcessSwitching`, `.disableHideApplication` ni `.disableSessionTermination`
