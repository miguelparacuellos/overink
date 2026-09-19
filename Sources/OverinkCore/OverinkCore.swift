// `OverinkCore` es el módulo de Swift puro donde vivirá el dominio: el Canvas y sus
// Marks, el History, la Tool y el color activos, y la máquina de estados del Overlay.
// No importa AppKit ni ningún framework de UI, y nunca lee el reloj del sistema.
//
// La costura entre los dos módulos es deliberadamente estrecha: el core expondrá
// aplicar un comando en un instante dado y leer el estado actual, y nada más. La shell
// de AppKit traduce `NSEvent` a comandos y pinta el estado resultante, sin tomar
// ninguna decisión de dominio.
//
// El módulo está vacío a propósito. El esqueleto de la app no toma ninguna decisión
// que pueda vivir aquí, y cualquier cosa que se pusiera ahora para que el módulo
// "tenga algo" sería justamente lo que la costura prohíbe. Quien lo estrena es el
// primer ticket con lógica de verdad —las transiciones Armed ⇄ Dismissed—, y es ese
// ticket el que trae también el target de tests y fija su patrón.
