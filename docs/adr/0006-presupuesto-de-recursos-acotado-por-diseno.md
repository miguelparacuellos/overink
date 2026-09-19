# El consumo de recursos se acota por diseño, no por optimización

Overink está residente todo el día para que un atajo lo despierte, y se usa mientras el Mac ya
está comprimiendo y enviando vídeo de la pantalla compartida. Competir por CPU con la
videollamada degrada la clase, así que en lugar de optimizar cuando se note, el consumo se
acota en el diseño con tres decisiones y se verifica contra cifras.

## Las decisiones

- **El History tiene tope de cien operaciones.** Un historial ilimitado crece sin techo en una
  clase larga, incluido el contenido de Canvas ya vaciados con Clear que Undo debe poder
  devolver. Con tope, la memoria está acotada por construcción.
- **Los Marks terminados se cachean; solo se repinta el Stroke vivo.** Repintar todos los
  Marks en cada frame hace que el coste crezca con lo dibujado, y el tirón aparece justo
  cuando más has trazado. Cacheando, el coste por frame deja de depender del número de Marks.
- **En Dismissed no corre nada**: sin timers, sin display link, sin redibujado. La app pasa
  ahí la inmensa mayoría del tiempo.

## El presupuesto

| Medida | Límite |
| --- | --- |
| CPU en Dismissed | 0% |
| Memoria con ambos Canvas llenos | < 150 MB |
| Latencia del trazo | < 16 ms (un frame a 60 Hz) |
| Margen del watchdog | 5 s sin respuesta del hilo principal |

## Consecuencias

Estas cifras son criterios de aceptación, no aspiraciones: un ticket que las incumpla no está
terminado. La costura de test elegida (Canvas e History puros) cubre el tope del historial;
CPU, memoria y latencia se miden sobre la app real.
