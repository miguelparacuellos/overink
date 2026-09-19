# 03: Dibujar trazos con el Pen

**What to build:** Con el Overlay en Armed, arrastrar el lápiz deja un trazo visible sobre lo
que hubiera en pantalla, y ese trazo sigue ahí al ocultar y volver a mostrar el Overlay.

Aquí nace `OverinkCore`, el módulo puro donde vive todo el modelo. Este ticket fija la costura
para los doce restantes, así que su interfaz y sus tests importan más que la funcionalidad que
entrega.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Existe un módulo de dominio que no importa AppKit ni ningún framework de interfaz
- [ ] Su interfaz se reduce a aplicar un comando en un instante dado y leer el estado a pintar
- [ ] El instante se recibe como parámetro: el módulo nunca lee el reloj del sistema
- [ ] Los comandos son intenciones semánticas, nunca eventos de macOS
- [ ] La shell se limita a traducir eventos a comandos y a pintar el estado; no toma decisiones de dominio
- [ ] Arrastrar el lápiz produce un Stroke visible, con grosor fijo
- [ ] Los Strokes se conservan al pasar a Dismissed y reaparecen al volver a Armed
- [ ] Hay tests que conducen el módulo solo a través de sus comandos y comprueban el estado resultante
- [ ] Ningún test conoce la representación interna de un Stroke ni comprueba que se llamó a un método
