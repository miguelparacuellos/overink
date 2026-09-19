import AppKit

// Overink no tiene ventanas al arrancar ni fichero de interfaz: la shell se monta a
// mano desde aquí.
let app = NSApplication.shared

// `.accessory` mantiene la app fuera del Dock y del conmutador de aplicaciones. El
// `LSUIElement` del Info.plist hace lo mismo desde el bundle; ponerlo también aquí es
// lo que permite ejecutar el binario a pelo sin que aparezca en el Dock.
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate

app.run()
