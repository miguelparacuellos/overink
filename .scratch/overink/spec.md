# Overink — Spec

**Status:** ready-for-agent

## Problem Statement

Doy clases particulares online compartiendo la pantalla completa. Cuando explico algo —una
parte de una página en Chrome, una línea concreta en el editor, un comando en el terminal—
necesito señalar y dibujar encima de lo que el alumno ya está viendo.

Hoy la única opción es abrir una aplicación de pizarra aparte, y eso rompe la clase dos veces:
saca al alumno del contexto que estábamos mirando, y me obliga a reproducir en la pizarra lo
que ya estaba en pantalla. Tengo una tableta gráfica con lápiz, pero no me sirve de nada si no
puedo dibujar directamente sobre la aplicación que estoy usando.

## Solution

Overink es una capa de anotación que vive en la barra de menús. Pulso `Ctrl+Option+D` y un
Overlay transparente se monta sobre la pantalla donde tengo el cursor: a partir de ahí, el
lápiz dibuja encima de lo que hubiera, sea Chrome, el editor o el terminal. Vuelvo a pulsar y
el Overlay se oculta, dejando la aplicación de debajo exactamente como estaba y conservando lo
dibujado por si lo necesito otra vez.

Mientras el Overlay está puesto tengo Pen, Highlighter, Eraser, Text y Laser en teclas
sueltas, cuatro colores en la fila de números, y deshacer y rehacer. No hay ventanas, ni
paletas flotantes, ni ficheros que guardar: es una pizarra efímera que aparece y desaparece
con un atajo.

## User Stories

### Activar y desactivar

1. Como profesor, quiero activar el Overlay con un atajo global desde cualquier aplicación, para anotar sin salir de lo que estoy explicando.
2. Como profesor, quiero desactivarlo con el mismo atajo, para volver a manejar la aplicación de debajo inmediatamente.
3. Como profesor, quiero que al volver a Armed reaparezca lo que había dibujado, para poder apagar un momento el Overlay, hacer scroll y retomar la explicación.
4. Como profesor, quiero que el Overlay se monte en la pantalla donde está el cursor, para que aparezca donde estoy mirando y no en la otra.
5. Como profesor, quiero que el Stage no cambie mientras el Overlay está puesto aunque mueva el cursor a la otra pantalla, para que el dibujo no salte de sitio a mitad de un trazo.
6. Como profesor, quiero que el Overlay cubra también la barra de menús y el Dock, para poder señalar un menú o un icono mientras explico cómo se usa una aplicación.
7. Como profesor, quiero salir a Dismissed pulsando Esc, para tener una salida obvia sin recordar el atajo.
8. Como profesor, quiero que el Overlay se oculte solo tras quince minutos sin tocar nada, para que un olvido no me lo deje puesto el resto de la tarde.
9. Como profesor, quiero que si ese Auto-Dismiss salta mientras escribo un Label, el texto se confirme en lugar de perderse, porque ocultar nunca debería destruir trabajo.

### Dibujar

10. Como profesor, quiero dibujar a mano alzada con el Pen, para rodear, subrayar y señalar sobre lo que hay en pantalla.
11. Como profesor, quiero un Highlighter translúcido y ancho, para resaltar una zona sin tapar lo que hay debajo.
12. Como profesor, quiero que un mismo trazo de Highlighter no se oscurezca donde se cruza consigo mismo, para que el resaltado quede uniforme.
13. Como profesor, quiero que el Eraser borre entero cada Mark que toca, para quitar algo de un roce sin tener que repasarlo.
14. Como profesor, quiero un Laser cuyo rastro se desvanezca solo, para seguir un recorrido con el alumno sin ensuciar el Canvas.
15. Como profesor, quiero que lo dibujado con el Laser no entre en el Canvas ni en el History, para que Undo no me resucite algo que ya desapareció de la pantalla.
16. Como profesor, quiero cambiar entre cuatro colores con las teclas 1 a 4, para distinguir lo correcto de lo incorrecto sin parar la explicación.
17. Como profesor, quiero que los cuatro colores se lean igual de bien sobre un editor oscuro que sobre una página blanca, porque cambio de uno a otro constantemente.
18. Como profesor, quiero un grosor de trazo fijo y predecible, para que el resultado no dependa de cuánta fuerza haga con el lápiz.

### Escribir texto

19. Como profesor, quiero colocar texto escrito con el teclado sobre la pantalla, para dejar un nombre o un valor legible que a mano alzada no se entendería.
20. Como profesor, quiero que mientras escribo un Label el teclado entero sea texto, para poder escribir "pen" sin que la p me cambie de herramienta.
21. Como profesor, quiero confirmar el Label con Enter y cancelarlo con Esc, para salir de ahí sin ambigüedad.
22. Como profesor, quiero que un Label confirmado se comporte como cualquier otro Mark, para borrarlo con el Eraser o deshacerlo igual que un trazo.

### Deshacer

23. Como profesor, quiero deshacer con Cmd+Z la última cosa que hice, sea dibujar, borrar o limpiar, para corregirme sin pensar en qué tipo de acción fue.
24. Como profesor, quiero poder deshacer un Clear entero, para recuperar la pizarra si la vacío por error delante del alumno.
25. Como profesor, quiero rehacer con Cmd+Shift+Z, para volver atrás si me paso deshaciendo.
26. Como profesor, quiero vaciar el Canvas con una sola tecla cómoda, porque limpiar entre concepto y concepto es constante en una clase.

### Varias pantallas

27. Como profesor, quiero que cada pantalla tenga su propio Canvas, para que lo que dibujé en el monitor siga ahí cuando vuelva, aunque entre medias haya anotado en el portátil.
28. Como profesor, quiero que al activar el Overlay en una pantalla donde no he dibujado aún empiece limpio, en lugar de recibir reescalado lo que dibujé en la otra.

### Saber qué tengo seleccionado

29. Como profesor, quiero un indicador fijo en una esquina con la Tool y el color activos, para no descubrir que me equivoqué de herramienta al empezar el trazo.

### La app en el sistema

30. Como profesor, quiero que Overink viva solo en la barra de menús, sin icono en el Dock ni en Cmd+Tab, para que no ocupe sitio en la pantalla que estoy compartiendo.
31. Como profesor, quiero poder salir de la app desde ese menú, para cerrarla sin buscar en el Monitor de Actividad.
32. Como profesor, quiero abrirla yo cuando doy clase en vez de que arranque sola al encender el Mac, para no tenerla residente los días que no la uso.
33. Como profesor, quiero que no me pida ningún permiso del sistema, para poder instalarla y usarla sin pasar por Ajustes.

### No quedarme encerrado

34. Como profesor, quiero tener la certeza de que ningún fallo de Overink puede dejarme sin controlar el Mac, porque ocurriría en directo delante de un alumno.
35. Como profesor, quiero que si la app se cuelga el Overlay desaparezca solo en pocos segundos, porque con el hilo principal bloqueado ni el atajo ni Esc responden.
36. Como profesor, quiero que las salidas que macOS ya ofrece sigan funcionando con el Overlay puesto, para tener siempre un último recurso ajeno a la app.
37. Como profesor, quiero que pulsar Esc haga siempre algo en cualquier estado, para que nunca parezca que la app se ha quedado muerta.

### Recursos

38. Como profesor, quiero que en Dismissed no consuma CPU, porque la app está ahí todo el día esperando un atajo.
39. Como profesor, quiero que el trazo siga siendo fluido con la pizarra llena, para que no empiece a ir a tirones justo al final de una explicación larga.
40. Como profesor, quiero que la memoria no crezca sin límite durante una clase de dos horas, para no tener que reiniciar la app a media sesión.
41. Como profesor, quiero que Overink no le robe CPU a la videollamada, para que la calidad de la pantalla compartida no se resienta.

### Que el alumno lo vea

42. Como alumno, quiero ver las anotaciones sobre la pantalla compartida en tiempo real, para seguir lo que el profesor está señalando.
43. Como profesor, quiero saber que esto exige compartir la pantalla completa y no una ventana, para no descubrir en directo que el alumno no ve nada.

## Implementation Decisions

### Módulos

El proyecto se divide en exactamente dos módulos, con una sola costura entre ellos.

**`OverinkCore`** — Swift puro, sin importar AppKit ni ningún framework de UI. Contiene todo
el modelo y toda la lógica de decisión:

- El Canvas y sus Marks (Stroke y Label), uno por Stage.
- El History como pila de operaciones, con tope de cien (ADR-0004, ADR-0006).
- La Tool y el color activos, y la Palette.
- La máquina de estados completa: Armed, Editing, Dismissed y el Auto-Dismiss.
- La semántica del Eraser: borra Marks enteros, nunca fragmentos (ADR-0003).
- La regla de que el Laser nunca produce Mark.
- La regla de que en Editing los atajos de una sola tecla quedan suspendidos.

**`OverinkApp`** — la shell de AppKit. Deliberadamente fina, sin decisiones propias:

- La ventana del Overlay, su nivel y su cobertura del Stage.
- La detección del Stage al pasar a Armed.
- El registro del atajo global con `RegisterEventHotKey` de Carbon.
- La traducción de `NSEvent` a comandos del core.
- El pintado del Canvas y del HUD.
- El ítem de la barra de menús.
- El watchdog.

### La interfaz de la costura

`OverinkCore` expone dos operaciones y nada más:

- **Aplicar un comando en un instante dado.** El instante se pasa como parámetro; el core
  nunca lee el reloj del sistema. Es lo que hace testeable el Auto-Dismiss de quince minutos
  sin esperar quince minutos, y lo que mantiene el core determinista.
- **Leer el estado actual**, que es todo lo que la shell necesita para pintar: los Marks del
  Stage activo, la Tool y el color seleccionados, y en qué estado está el Overlay.

Los comandos son intenciones semánticas, nunca eventos de macOS: lápiz abajo, lápiz movido,
lápiz arriba, elegir Tool, elegir color, deshacer, rehacer, vaciar, empezar Label, tecla
escrita, confirmar Label, cancelar Label, armar sobre un Stage, descartar, y el tic de tiempo
que puede disparar el Auto-Dismiss.

La shell no toma ninguna decisión de dominio: recibe un `NSEvent`, lo traduce a un comando, lo
aplica y repinta según el estado resultante.

### Atajos

| Contexto | Tecla | Acción |
| --- | --- | --- |
| Global | `Ctrl+Option+D` | Armed ⇄ Dismissed |
| Armed | `P` `H` `E` `T` `L` | Pen · Highlighter · Eraser · Text · Laser |
| Armed | `1` `2` `3` `4` | Color de la Palette |
| Armed | `Cmd+Z` / `Cmd+Shift+Z` | Undo / Redo |
| Armed | `Backspace` | Clear |
| Armed | `Esc` | Dismissed |
| Editing | *todo el teclado* | Texto (atajos suspendidos) |
| Editing | `Enter` / `Esc` | Confirmar / cancelar el Label |

### Ventana y entrada

- En Armed el Overlay captura toda la entrada; la aplicación de debajo no recibe nada
  (ADR-0002). No hay click-through y no se usa `CGEventTap`.
- El nivel de la ventana debe ser **el más bajo que aún cubra barra de menús y Dock**, de modo
  que las alertas del sistema y el diálogo de Forzar salida queden por encima (ADR-0005).
- Está **prohibido** activar `.disableForceQuit`, `.disableProcessSwitching`,
  `.disableHideApplication` o `.disableSessionTermination`.
- Como no hace falta `CGEventTap` y el atajo va por Carbon, la app **no requiere ningún
  permiso de TCC**.

### Watchdog

Un hilo independiente comprueba periódicamente que el hilo principal responde. Si no lo hace
en cinco segundos estando en Armed, llama a `exit()`. Matar el proceso hace desaparecer la
ventana, y como el Canvas solo vive en memoria no se pierde nada relevante (ADR-0005).

### Render

Los Marks terminados se consolidan en una capa cacheada; en cada frame solo se repinta el
Stroke en curso, de modo que el coste por frame no crece con el número de Marks (ADR-0006).
En Dismissed no corre ningún timer ni display link.

### Presupuesto de recursos

Criterios de aceptación, no aspiraciones: 0% de CPU en Dismissed, menos de 150 MB con ambos
Canvas llenos, latencia del trazo por debajo de 16 ms, y margen del watchdog de 5 s.

### Construcción

SwiftPM con el SDK de las Command Line Tools (Swift 6.1, macOS 15.6, arm64). Un script ensambla
`Overink.app` con su `Info.plist` (incluido `LSUIElement` para no aparecer en el Dock) y lo
firma ad-hoc. No se usa Xcode ni existe un `.xcodeproj`.

## Testing Decisions

### Qué hace bueno a un test aquí

Un buen test conduce `OverinkCore` **solo a través de su interfaz de comandos** y comprueba el
estado observable resultante. Nunca toca estructuras internas, nunca comprueba que se llamó a
tal método, y nunca conoce cómo está representado un Stroke por dentro. Si un test se rompe al
reorganizar el interior del core sin cambiar su comportamiento, ese test está mal escrito.

La consecuencia práctica: los tests se leen como guiones de uso. "Dibujo dos trazos, borro uno
con el Eraser, deshago dos veces: deben estar los dos trazos."

### Qué se testea

Todo `OverinkCore`, que es donde vive el riesgo real:

- Añadir Strokes y que aparezcan en el Canvas del Stage activo.
- El Eraser eliminando Marks enteros, incluidos Labels, y no fragmentos.
- Undo y Redo sobre las tres operaciones: añadir, borrar y Clear.
- Que Undo tras un Clear devuelva el Canvas completo.
- El tope de cien operaciones y que la más antigua deje de ser reversible.
- Que el Laser no deje Mark ni entre en el History.
- Que en Editing las teclas de herramienta y color se traten como texto.
- Confirmar y cancelar un Label.
- Que un Label confirmado sea inmutable.
- Las transiciones Armed ⇄ Dismissed y la conservación del Canvas entre ellas.
- El Auto-Dismiss a los quince minutos, avanzando el instante inyectado.
- Que el Auto-Dismiss durante Editing confirme el Label en vez de descartarlo.
- Que cada Stage tenga su propio Canvas y que uno nuevo empiece vacío.

### Qué no se testea automáticamente

Se verifica a mano, sobre la app real, y cada ticket que toque estas áreas debe decir cómo se
comprobó: nivel y cobertura de la ventana, detección del Stage, registro del atajo global,
watchdog, fidelidad del pintado, HUD, ítem de la barra de menús y las cuatro cifras del
presupuesto de recursos.

### Prior art

Ninguno: el repositorio está vacío de código. El primer ticket que escriba tests fija el
patrón para los demás, así que conviene que sea deliberadamente legible.

## Out of Scope

- **Presión del lápiz.** El grosor es fijo. Queda pendiente de verificar qué expone el driver
  de la tableta Gaomon, con la tableta conectada.
- **Formas geométricas**: línea recta, flecha, rectángulo y elipse. Descartadas
  conscientemente; las flechas se dibujan a pulso.
- **Mover o editar un Mark** una vez creado. Son inmutables: se borran y se rehacen.
- **Goma de píxeles.** El Eraser borra Marks enteros (ADR-0003).
- **Persistencia en disco.** El Canvas vive en memoria y se pierde al cerrar la app.
- **Capturas de pantalla y exportación.**
- **Compartir una ventana concreta** en lugar de la pantalla completa (ADR-0001).
- **Un Canvas compartido entre pantallas**, o el Overlay en varias pantallas a la vez.
- **Arranque automático al iniciar sesión.**
- **Notarización y distribución a terceros.** Firma ad-hoc, solo para este Mac.
- **Personalizar los atajos** desde una interfaz de preferencias.

## Further Notes

### El riesgo que hay que despejar primero

Hay una tensión real entre dos decisiones ya tomadas: el Overlay debe **cubrir la barra de
menús y el Dock**, lo que exige un nivel de ventana alto; y debe quedar **por debajo de las
alertas del sistema y del diálogo de Forzar salida** (ADR-0005). Que exista un nivel que
cumpla las dos cosas es una suposición, no un hecho verificado.

Conviene resolverlo en el primer ticket, empíricamente y no por documentación: montar una
ventana al nivel candidato y comprobar que `Cmd+Option+Esc` muestra su diálogo por encima. Si
ningún nivel cumple ambas, gana ADR-0005 y se sacrifica la cobertura de la barra de menús.

### Otros riesgos

- El `RegisterEventHotKey` de Carbon es API antigua pero sigue siendo la vía sin permisos para
  un atajo global. Conviene confirmarlo pronto: si fallara, la alternativa necesita
  Accesibilidad y cambiaría la historia 33.
- La tableta Gaomon no estaba conectada al escribir este spec. Todo lo especificado funciona
  con trackpad y ratón; nada depende de la tableta.
- El Auto-Dismiss a quince minutos es una red de seguridad floja por elección deliberada. El
  watchdog es la defensa real contra un cuelgue.

### Decisiones registradas fuera de los ADR

Dos decisiones estructurales se recogen solo aquí: **un Canvas por Stage** y **construir con
SwiftPM sin Xcode**. Ambas cumplirían el listón de un ADR si en algún momento se quiere
elevarlas.
