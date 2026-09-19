# 02: El Overlay aparece y desaparece con el atajo

**What to build:** Desde cualquier aplicación, pulsar el atajo global monta un Overlay
transparente sobre la pantalla donde está el cursor; volver a pulsarlo, o pulsar Esc, lo
quita. Mientras está puesto, la aplicación de debajo no recibe nada.

Este ticket resuelve además el riesgo que el spec señala como el primero a despejar: si existe
un nivel de ventana que cubra la barra de menús y el Dock y **a la vez** deje que las alertas
del sistema aparezcan por encima. Se comprueba probándolo, no leyendo documentación.

**Blocked by:** 01

**Status:** resolved

- [x] Ctrl+Option+D alterna entre Armed y Dismissed desde cualquier aplicación
- [x] El atajo se registra sin requerir permiso de Accesibilidad ni ningún otro permiso de TCC
- [x] El Overlay cubre la pantalla que contenía el cursor en el instante de pasar a Armed
- [x] El Stage no cambia aunque el cursor se mueva a la otra pantalla mientras sigue en Armed
- [x] En Armed, la aplicación de debajo no recibe ni ratón ni teclado
- [x] Esc pasa a Dismissed
- [x] **Verificado a mano:** con el Overlay puesto, Cmd+Option+Esc muestra su diálogo por encima del Overlay
- [x] Si no existe ningún nivel que cumpla ambas cosas, gana ADR-0005: se sacrifica la cobertura de la barra de menús, se deja anotado en el ADR y se explica el porqué — no hizo falta: el nivel 25 cumple las dos, ver más abajo
- [x] No se activa `.disableForceQuit`, `.disableProcessSwitching`, `.disableHideApplication` ni `.disableSessionTermination`

## Comments

### El riesgo del nivel de ventana: despejado (2026-09-19)

**Sí existe un nivel que cumple las dos cosas.** El Overlay se monta en
`CGWindowLevelForKey(.mainMenuWindow) + 1`, es decir **25**, que es el más bajo que aún cubre
la barra de menús (24) y el Dock (20). Comprobado con la app real y
`CGWindowListCopyWindowInfo`:

- Armado, la ventana de Overink sale en la lista con `level 25` y `1920×1080` en `Y = 0`, por
  delante de la ventana `Window Server / Menubar`, que está en `level 24`.
- Con el Overlay puesto, `Cmd+Option+Esc` abre el diálogo de Forzar salida —una ventana de
  `loginwindow`— en **`level 996`**, por delante del Overlay en el orden de la lista. La
  regla 2 de ADR-0005 se cumple sin sacrificar la cobertura de la barra de menús, así que el
  plan B del ticket no hace falta. Anotado también en ADR-0005.
- De hecho, desde ese diálogo se forzó la salida de Overink con el Overlay puesto y el control
  del Mac volvió entero: la salida garantizada funciona.

### Cómo se comprobó lo demás (2026-09-19)

Todo sobre `build/Overink.app`, simulando las teclas con `System Events` y leyendo el estado
real del sistema con `CGWindowListCopyWindowInfo`, no la interfaz.

- **El atajo alterna desde cualquier aplicación**: con TextEdit al frente, `Ctrl+Option+D`
  hace aparecer la ventana de 1920×1080; pulsado otra vez, desaparece y solo queda el ítem de
  la barra de menús.
- **Sin permisos**: `RegisterEventHotKey` devuelve `noErr` y el log unificado no registra
  ninguna petición de TCC de `dev.overink.Overink`. No hay `CGEventTap` ni monitor global de
  eventos en el código.
- **El Stage es el del cursor y no se mueve**: con el cursor en la pantalla secundaria
  (`-1470, -225, 1470×956`), el Overlay se monta exactamente sobre ella; moviendo el cursor a
  la principal mientras sigue armado, la ventana no cambia ni de sitio ni de tamaño. Pulsar el
  atajo desde la otra pantalla descarta, no rearma allí.
- **La aplicación de debajo no recibe nada**: con un documento de TextEdit al frente se
  escribió `hola` (llega al fichero), se armó el Overlay, se escribió `NOPE` y se descartó: el
  fichero sigue conteniendo solo `Hola`. Un clic en mitad de la pantalla estando armado lo
  recibe `window 1 of application process Overink`.
- **Esc**: estando armado, `Esc` deja el sistema con normalidad y el foco vuelve a una
  aplicación real.
- **Las cuatro opciones prohibidas**: no se tocan las `presentationOptions` en ningún sitio;
  un `grep` del código solo las encuentra dentro del comentario que explica por qué no se usan.
- **De propina, el presupuesto de ADR-0006**: en Dismissed el proceso está al **0,0 % de CPU**
  y en ~30 MB de RSS, sin ningún timer en marcha.

### Decisiones de diseño

- El core estrena su costura: `Overlay.apply(_:at:)` y `Overlay.state`, y nada más. El
  comando del atajo es `.toggle(stageUnderCursor:)` —la shell aporta el dato que el core no
  puede conocer, pero la decisión de armar o descartar, y la de congelar el Stage, son del
  core y están cubiertas por tests.
- El parámetro `at instant:` no lo usa todavía ningún comando. Está desde el principio porque
  es la costura que el spec fija y la que hará testeable el Auto-Dismiss sin esperar quince
  minutos; añadirlo después obligaría a tocar todas las llamadas y todos los tests.
- `Tests/OverinkCoreTests` es el primer target de tests y fija el patrón: guiones de uso
  contra la interfaz de comandos, sin tocar nada interno.
- El Overlay no pinta **nada**: es transparente, como pide el spec. Estando armado no hay
  ninguna pista visual de que lo está —lo que se nota es que la aplicación de debajo deja de
  responder—, y eso es correcto hasta que lleguen los trazos (ticket 03) y el HUD (ticket 09).
- El comando del atajo es `.toggle(stageUnderCursor:)` y no el par «armar / descartar» que
  enumera el spec al describir la costura. Es deliberado y va en la dirección que el spec
  marca como más importante: alternar es una decisión de dominio, y con el par la shell
  tendría que mirar el estado para elegir cuál mandar. El core recibe el dato que solo la
  shell conoce y decide él.
- `Esc` llega por la ventana del Overlay, así que depende de que siga siendo key. Si una
  alerta del sistema se lleva el foco —ADR-0005 exige que pueda—, `Esc` deja de llegar hasta
  que se vuelve a hacer clic en el Overlay. La salida que no depende del foco es el atajo
  global, que va por Carbon; la que no depende ni del hilo principal es el watchdog
  (ticket 12).
- El menú de la barra dice «Pulsa ⌃⌥D para anotar», o avisa si Carbon rechazó el atajo. Es
  superficie del ticket 01, pero un atajo que no se registra y no avisa en ningún sitio sería
  un fallo mudo.
