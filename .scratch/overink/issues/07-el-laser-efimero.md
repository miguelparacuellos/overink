# 07: El Laser efímero

**What to build:** Una herramienta para seguir un recorrido con el alumno sin ensuciar la
pizarra: el rastro se desvanece solo a los pocos segundos y no deja nada detrás.

Es la única Tool que no produce Marks, así que el trabajo está en mantenerla fuera del Canvas
y del History sin abrir un agujero en el modelo.

**Blocked by:** 06

**Status:** resolved

- [x] La tecla L selecciona el Laser
- [x] Su rastro se desvanece por completo en unos dos segundos
- [x] Nunca produce un Mark: el Canvas no cambia al usarlo
- [x] Undo no lo ve, y no puede resucitar un rastro ya desaparecido
- [x] Vaciar el Canvas no le afecta, porque no hay nada suyo que vaciar
- [x] Pasar a Dismissed y volver no deja ningún rastro del Laser
- [x] Hay tests que verifican que usarlo no añade Marks ni operaciones al History

## Comments

- Implementado: `L` selecciona Laser; su Stroke transitorio se redibuja a 30 Hz y se
  desvanece linealmente durante dos segundos. No se almacena en Canvas ni History.
- Verificado con `swift test`: 38 tests superados, incluidos los nuevos casos de
  aislamiento de Canvas/History, desvanecimiento, Clear y Dismissed.
