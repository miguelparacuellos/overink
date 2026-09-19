// Reglas del módulo `OverinkCore`, el Swift puro donde vive el dominio:
//
// - No importa AppKit ni ningún framework de UI.
// - Nunca lee el reloj: el instante llega como parámetro en cada comando.
// - Expone exactamente dos operaciones, aplicar un comando y leer el estado, y nada más.
//
// La shell de AppKit traduce `NSEvent` a comandos y pinta el estado resultante, sin tomar
// ninguna decisión de dominio. Ver `Overlay`.
