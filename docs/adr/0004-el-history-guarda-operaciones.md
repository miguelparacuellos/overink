# El History es una pila de operaciones, no de Marks

Undo revierte la última **operación** aplicada al Canvas —añadir un Mark, borrar uno con el
Eraser, vaciarlo con Clear— y no simplemente el último Mark dibujado. La razón es Clear: se
decidió que fuese un atajo cómodo precisamente porque `Cmd+Z` puede devolver el Canvas entero,
y eso es imposible si el historial solo sabe de Marks.

## Consecuencias

Un historial de Marks parece la simplificación obvia al leer el código y rompería Clear en
silencio. Redo sale prácticamente gratis de esta misma estructura.
