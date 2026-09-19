# 04: Deshacer, rehacer y vaciar

**What to build:** Poder corregirse en directo: deshacer lo último hecho, rehacerlo si uno se
pasa, y vaciar la pizarra de golpe entre un concepto y el siguiente. Vaciar también se
deshace, que es lo que permite que su atajo sea cómodo sin miedo.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] Cmd+Z deshace la última operación aplicada al Canvas
- [ ] Cmd+Shift+Z la rehace
- [ ] Backspace vacía el Canvas entero
- [ ] Cmd+Z después de vaciar devuelve el Canvas completo, con todos sus Marks
- [ ] El History almacena operaciones, no Marks: añadir, borrar y vaciar se revierten por igual
- [ ] El History guarda como mucho las cien últimas operaciones, y al superarlas la más antigua deja de ser reversible
- [ ] Hay tests para deshacer un vaciado, para el tope de cien y para la secuencia deshacer-rehacer
