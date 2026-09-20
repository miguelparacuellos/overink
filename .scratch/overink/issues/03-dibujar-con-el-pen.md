# 03: Dibujar trazos con el Pen

**What to build:** Con el Overlay en Armed, arrastrar el lápiz deja un trazo visible sobre lo
que hubiera en pantalla, y ese trazo sigue ahí al ocultar y volver a mostrar el Overlay.

Aquí nace `OverinkCore`, el módulo puro donde vive todo el modelo. Este ticket fija la costura
para los doce restantes, así que su interfaz y sus tests importan más que la funcionalidad que
entrega.

**Blocked by:** 02

**Status:** resolved

- [x] Existe un módulo de dominio que no importa AppKit ni ningún framework de interfaz
- [x] Su interfaz se reduce a aplicar un comando en un instante dado y leer el estado a pintar
- [x] El instante se recibe como parámetro: el módulo nunca lee el reloj del sistema
- [x] Los comandos son intenciones semánticas, nunca eventos de macOS
- [x] La shell se limita a traducir eventos a comandos y a pintar el estado; no toma decisiones de dominio
- [x] Arrastrar el lápiz produce un Stroke visible, con grosor fijo
- [x] Los Strokes se conservan al pasar a Dismissed y reaparecen al volver a Armed
- [x] Hay tests que conducen el módulo solo a través de sus comandos y comprueban el estado resultante
- [x] Ningún test conoce la representación interna de un Stroke ni comprueba que se llamó a un método

## Comments

### Implementación (2026-09-20)

- `OverinkCore` recibe las intenciones `.penDown`, `.penMoved` y `.penUp`; el estado Armed
  expone el `Canvas` y el Stroke vivo que la shell debe pintar. No importa AppKit ni consulta
  el reloj.
- `OverlayView` adapta los eventos de puntero a esos comandos y redibuja los Strokes vectoriales
  en rojo, con el grosor fijo que establece `Stroke.penWidth`.
- Los tests de `OverinkCore` cubren un gesto de Pen y que el Stroke reaparece tras Dismissed.
  Verificados con `swift test --filter` y `swift build`.
