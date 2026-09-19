# Los Marks son vectoriales y el Eraser borra Marks enteros

El Canvas guarda objetos (Strokes con sus puntos, Labels con su texto), no un mapa de píxeles,
y el Eraser elimina por completo cada Mark que toca en vez de borrar por área. Elegimos el
modelo vectorial porque es el que hace baratas tres cosas a la vez: deshacer, un Highlighter
translúcido que no se oscurece al solaparse, y un rendimiento que no depende de la resolución
de la pantalla.

## Consecuencias

Una goma que borra "medio trazo" no encaja en este modelo sin partir Marks, así que si alguna
vez se quiere, no es un ajuste: es un cambio de representación que arrastra el renderizado y
el History con él.
