# Overink

Una capa de anotación para macOS: dibujar a mano alzada directamente sobre lo que ya hay en
pantalla, sin cambiar de aplicación, mientras se imparte una clase por videollamada
compartiendo la pantalla completa.

Los términos van en inglés porque son los identificadores del código; las definiciones, en
castellano.

## Language

### La superficie

**Overlay**:
La ventana transparente a pantalla completa sobre la que se dibuja. No es la aplicación: es
su única superficie visible.
_Avoid_: ventana, capa, lienzo

**Stage**:
La pantalla sobre la que se monta el Overlay. Se decide en el instante de pasar a Armed —la
que contiene el cursor— y **no cambia mientras dure esa sesión de Armed**, aunque el cursor se
vaya a la otra pantalla. Para cambiar de Stage hay que pasar por Dismissed y volver a Armed.
_Avoid_: monitor, display activo

**Canvas**:
El conjunto ordenado de Marks que existen en un momento dado. Vive por encima del Overlay:
sobrevive intacto a que el Overlay se oculte.
_Avoid_: lienzo, documento, dibujo, pizarra

**Mark**:
Cualquier cosa que vive en el Canvas. Es el nivel al que operan Undo, Eraser y Clear: los
tres tratan por igual a todas sus formas. Hoy hay dos, Stroke y Label.
_Avoid_: objeto, elemento, anotación

**Stroke**:
La forma de Mark que produce un trazo continuo, desde que el lápiz apoya hasta que se
levanta. Es atómico: el Eraser lo elimina entero, nunca por fragmentos.
_Avoid_: línea, path, garabato

**Label**:
La forma de Mark que contiene texto escrito con el teclado, anclado a un punto de la pantalla.
_Avoid_: caja de texto, nota, anotación

### Los estados del Overlay

**Armed**:
El Overlay está visible sobre su Stage y capturando la entrada. Todo el puntero y el teclado
van al dibujo; la aplicación de debajo no recibe nada.
_Avoid_: activo, abierto, encendido

**Editing**:
Subestado de Armed en el que se está escribiendo un Label. Mientras dura, el teclado entero
es texto y los atajos de una sola tecla quedan suspendidos. Se sale confirmando o cancelando.
_Avoid_: modo texto, escribiendo

**Dismissed**:
El Overlay está oculto y el sistema se comporta con normalidad. El Canvas se conserva entero
y reaparece al volver a Armed.
_Avoid_: cerrado, apagado, desactivado — todos sugieren que se pierde el Canvas, y no se pierde

**Clear**:
La acción que vacía el Canvas de golpe. Es deliberadamente distinta de pasar a Dismissed:
Dismissed oculta, Clear destruye. Aun así es reversible, porque es una operación más del
History.
_Avoid_: borrar, limpiar, reset

**History**:
La pila de **operaciones** aplicadas al Canvas, no de Marks. Añadir un Mark, borrar uno con el
Eraser y vaciar el Canvas con Clear son todas operaciones, y por eso Undo puede revertir
cualquiera de las tres por igual.
_Avoid_: historial de trazos, lista de deshacer

**Undo**:
Revierte la última operación del History. Nunca opera sobre el último Mark dibujado, sino
sobre lo último que se hizo.

### Las herramientas

**Tool**:
Lo que el lápiz hace al moverse por el Overlay. Exactamente uno está seleccionado en todo
momento.

**Pen**:
Tool que produce Strokes opacos y finos. El trazo por defecto.

**Highlighter**:
Tool que produce Strokes translúcidos y anchos, para resaltar lo que hay debajo sin taparlo.
_Avoid_: marcador, rotulador

**Eraser**:
Tool que no produce Mark: elimina por completo cada Mark que toca.
_Avoid_: goma de píxeles — no borra por área, borra por Mark

**Text**:
Tool que entra en Editing para producir un Label.

**Laser**:
Tool efímero: lo que dibuja se desvanece solo y **nunca llega a ser un Mark**. No entra en el
Canvas, Undo no lo ve y Clear no tiene nada suyo que destruir. Es la única Tool cuyo rastro no
sobrevive.
_Avoid_: puntero — el puntero es el cursor del sistema, otra cosa

### La interfaz

**Palette**:
Los cuatro colores disponibles, elegidos para leerse tanto sobre fondo oscuro como sobre fondo
claro. Aplica a Pen, Highlighter y Label.

**HUD**:
El indicador fijo en una esquina que muestra la Tool y el color activos mientras el Overlay
está en Armed. Es visible para el alumno, porque forma parte de la pantalla compartida.
_Avoid_: barra de herramientas, toolbar — no se interactúa con él, solo informa
