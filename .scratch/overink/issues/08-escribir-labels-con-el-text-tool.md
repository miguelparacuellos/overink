# 08: Escribir Labels con el Text tool

**What to build:** Poder dejar un nombre o un valor escrito con el teclado, legible, donde a
mano alzada no se entendería. Mientras se escribe, el teclado entero es texto: las teclas de
herramienta y de color dejan de actuar como atajos, que es justo el conflicto que este ticket
resuelve.

**Blocked by:** 06

**Status:** resolved

- [x] La tecla T selecciona el Text tool
- [x] Hacer clic fija el punto donde se anclará el Label y entra en Editing
- [x] En Editing, todas las teclas son texto: escribir "pen" escribe la palabra y no cambia de herramienta
- [x] Enter confirma y crea el Label
- [x] Esc cancela y no crea nada
- [x] Al salir de Editing vuelven a funcionar los atajos de una sola tecla
- [x] Un Label confirmado es inmutable: no se edita ni se mueve
- [x] El Eraser lo borra entero y Cmd+Z lo deshace, igual que a un Stroke
- [x] Hay tests de que en Editing las teclas de atajo se tratan como texto, y de confirmar y cancelar

## Answer

Implementado el Text tool con el subestado Editing. Al hacer clic se ancla un Label; Enter lo
confirma, Esc lo cancela y, mientras se edita, todos los eventos de teclado se traducen a
texto antes de considerar atajos. Los Labels confirmados se renderizan, no se pueden editar ni
mover, y el Eraser los elimina como Marks enteros; Undo los restaura.

Verificado con `swift test`: 30 tests pasan, incluidos los de texto durante Editing,
confirmación, cancelación y borrado/Undo del Label.
