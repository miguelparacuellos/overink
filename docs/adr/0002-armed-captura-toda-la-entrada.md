# En Armed, el Overlay captura toda la entrada

Mientras el Overlay está en Armed se queda con el puntero y el teclado enteros: la aplicación
de debajo no recibe nada, y para volver a usarla hay que pasar por Dismissed. Esto convierte
al Overlay en una `NSWindow` transparente normal que es la ventana activa, sin más magia.

## Considerado y descartado

Dibujar y manejar la app de debajo a la vez (el lápiz pinta mientras el ratón sigue clicando)
exige un `CGEventTap` que discrimine por dispositivo de entrada, lo que arrastra permiso de
Accesibilidad, un punto de fallo delicado y un modo en el que es fácil perderse. Para dar
clase, alternar con un atajo es suficiente.

## Consecuencias

Como no hace falta `CGEventTap` y el atajo global se registra con `RegisterEventHotKey` de
Carbon, **Overink no necesita ningún permiso de TCC**. Eso evita además tener que volver a
conceder Accesibilidad tras cada recompilación por la firma ad-hoc.
