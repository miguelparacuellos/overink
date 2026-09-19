# Overink nunca puede encerrar al usuario

En Armed el Overlay se queda con toda la entrada y tapa la pantalla entera, menú y Dock
incluidos (ADR-0002). Eso lo convierte en la única pieza de esta app capaz de dejar el Mac
inservible en mitad de una clase, así que la salida garantizada se trata como un requisito de
corrección, por encima de cualquier funcionalidad.

## Las tres reglas duras

1. **Nunca activar** `.disableForceQuit`, `.disableProcessSwitching`,
   `.disableHideApplication` ni `.disableSessionTermination` en
   `NSApplicationPresentationOptions`. Cualquiera de ellas destruye la salida que macOS ya
   garantiza (`Cmd+Option+Shift+Esc` mantenido ~3 s mata la app en primer plano sin diálogo).
2. **Nunca poner la ventana por encima de las alertas del sistema.** El nivel debe ser el más
   bajo que aún cubra barra de menús y Dock, para que un diálogo del sistema o el de Forzar
   salida siga apareciendo *encima* del Overlay. El nivel concreto se verifica probándolo, no
   suponiéndolo. **Verificado en el ticket 02**: el nivel es
   `CGWindowLevelForKey(.mainMenuWindow) + 1` (25), que cubre la barra de menús (24) y el Dock
   (20), mientras que el diálogo de Forzar salida aparece en el 996 y queda por encima. No
   hace falta sacrificar la cobertura de la barra de menús.
3. **Esc nunca es inerte.** Desde Editing cancela el Label; desde Armed pasa a Dismissed. No
   existe ningún estado en el que pulsar Esc no haga nada.

## El watchdog

Las reglas anteriores no cubren el peor caso: el hilo principal bloqueado. Con él muerto no
responden ni Esc ni el atajo global, porque ambos se procesan ahí. Por eso un hilo
independiente comprueba periódicamente que el principal sigue vivo y, si no responde en cinco
segundos estando en Armed, llama a `exit()`. Matar el proceso hace desaparecer la ventana con
él, y como el Canvas solo vive en memoria y nunca se persiste (ADR pendiente sobre
persistencia), no hay nada importante que perder.

El Auto-Dismiss a los quince minutos es una segunda red, más floja y para otra cosa: cubre el
olvido, no el cuelgue. El watchdog es la defensa real.

## Consecuencias

Un hilo que llama a `exit()` parece una barbaridad leyendo el código, y alguien lo quitará por
"limpieza" si no encuentra esto escrito. Es deliberado, y es la única defensa que funciona
cuando el hilo principal ya no ejecuta nada.
