# 08: Escribir Labels con el Text tool

**What to build:** Poder dejar un nombre o un valor escrito con el teclado, legible, donde a
mano alzada no se entendería. Mientras se escribe, el teclado entero es texto: las teclas de
herramienta y de color dejan de actuar como atajos, que es justo el conflicto que este ticket
resuelve.

**Blocked by:** 06

**Status:** ready-for-agent

- [ ] La tecla T selecciona el Text tool
- [ ] Hacer clic fija el punto donde se anclará el Label y entra en Editing
- [ ] En Editing, todas las teclas son texto: escribir "pen" escribe la palabra y no cambia de herramienta
- [ ] Enter confirma y crea el Label
- [ ] Esc cancela y no crea nada
- [ ] Al salir de Editing vuelven a funcionar los atajos de una sola tecla
- [ ] Un Label confirmado es inmutable: no se edita ni se mueve
- [ ] El Eraser lo borra entero y Cmd+Z lo deshace, igual que a un Stroke
- [ ] Hay tests de que en Editing las teclas de atajo se tratan como texto, y de confirmar y cancelar
