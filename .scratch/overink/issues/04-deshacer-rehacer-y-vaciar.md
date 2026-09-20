# 04: Deshacer, rehacer y vaciar

**What to build:** Poder corregirse en directo: deshacer lo último hecho, rehacerlo si uno se
pasa, y vaciar la pizarra de golpe entre un concepto y el siguiente. Vaciar también se
deshace, que es lo que permite que su atajo sea cómodo sin miedo.

**Blocked by:** 03

**Status:** resolved

- [x] Cmd+Z deshace la última operación aplicada al Canvas
- [x] Cmd+Shift+Z la rehace
- [x] Backspace vacía el Canvas entero
- [x] Cmd+Z después de vaciar devuelve el Canvas completo, con todos sus Marks
- [x] El History almacena operaciones, no Marks: añadir, borrar y vaciar se revierten por igual
- [x] El History guarda como mucho las cien últimas operaciones, y al superarlas la más antigua deja de ser reversible
- [x] Hay tests para deshacer un vaciado, para el tope de cien y para la secuencia deshacer-rehacer

## Comments

### Implementación (2026-09-20)

- `History` representa añadir, borrar y Clear como operaciones reversibles, con una capacidad
  de cien; registrar una operación nueva descarta el Redo.
- La shell traduce Cmd+Z, Cmd+Shift+Z y Backspace a las intenciones semánticas del core.
- La suite del core cubre la restauración tras Clear, el límite de cien y la secuencia
  Undo–Redo, incluido un borrado reversible que el Eraser del siguiente ticket podrá emitir.
