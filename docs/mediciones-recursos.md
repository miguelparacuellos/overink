# Mediciones de recursos

Registro de los criterios de ADR-0006. Las cifras solo son comparables si se toman sobre el
binario de producción, con la pantalla compartida por la videollamada habitual, después de
cinco segundos de estabilización y sin otras aplicaciones nuevas durante cada pasada.

| Fecha | Build | CPU Dismissed | Memoria (dos Canvas llenos) | Latencia de trazo | Mediana de frame vacío/lleno | Resultado |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-09-20 | Debug local | Pendiente de sesión gráfica | Pendiente de dos Stages físicos | Pendiente de sesión gráfica | Pendiente de sesión gráfica | No válido como baseline |

La ejecución de CI/terminal no dispone de dos Stages, tableta ni una sesión de WindowServer
interactiva; por ello no se inventan cifras. La comprobación visual y de instrumentación queda
pendiente en el Mac donde se usará Overink.

## Procedimiento reproducible

1. Ensamblar el binario de producción y abrirlo; esperar cinco segundos en Dismissed. En
   Instruments, grabar 30 s con **Time Profiler** y comprobar 0,0 % de CPU de Overink.
2. Con dos Stages conectados, llenar cada Canvas con 100 operaciones de Strokes largos y
   Labels, alternando `Ctrl+Shift+D` para cada Stage. En **Activity Monitor**, anotar la
   memoria residente de Overink; debe quedar por debajo de 150 MB.
3. En el primer Stage, comparar dos grabaciones de **Core Animation** o **Time Profiler**:
   Canvas vacío y el Canvas lleno anterior. Arrastrar el Pen durante diez segundos en cada
   caso. Anotar la mediana de los 600 frames de cada grabación: la respuesta del trazo debe
   ser menor de 16 ms y la mediana del Canvas lleno no debe superar a la del vacío en más de
   1 ms. Esos son los dos valores que se copian en la columna de frame.
4. Copiar las cuatro cifras, el modelo de Mac, resolución/escalado de ambos Stages y la versión
   de macOS a la fila siguiente de esta tabla. Si alguna cifra falla, no actualizar el baseline:
   abrir un ticket con la traza de Instruments.

## Qué protege la implementación

`OverlayView` rasteriza los Marks terminados en una imagen por cambio de Canvas, tamaño o
escala de pantalla. Durante el gesto compone esa imagen y pinta únicamente el Stroke vivo (y,
cuando corresponde, el Laser o Label en edición). `OverlayController` invalida todos sus timers
y detiene el watchdog al entrar en Dismissed; al soltar la ventana tampoco queda una vista que
redibujar.
