# 07: El Laser efímero

**What to build:** Una herramienta para seguir un recorrido con el alumno sin ensuciar la
pizarra: el rastro se desvanece solo a los pocos segundos y no deja nada detrás.

Es la única Tool que no produce Marks, así que el trabajo está en mantenerla fuera del Canvas
y del History sin abrir un agujero en el modelo.

**Blocked by:** 06

**Status:** ready-for-agent

- [ ] La tecla L selecciona el Laser
- [ ] Su rastro se desvanece por completo en unos dos segundos
- [ ] Nunca produce un Mark: el Canvas no cambia al usarlo
- [ ] Undo no lo ve, y no puede resucitar un rastro ya desaparecido
- [ ] Vaciar el Canvas no le afecta, porque no hay nada suyo que vaciar
- [ ] Pasar a Dismissed y volver no deja ningún rastro del Laser
- [ ] Hay tests que verifican que usarlo no añade Marks ni operaciones al History
