import AppKit

/// Lo que Overink monta al arrancar: el ítem de la barra de menús y el atajo global que
/// despierta al Overlay. Nada más: en Dismissed no corre ningún timer ni redibujado
/// (ADR-0006).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBar = MenuBarController()
    private let overlay = OverlayController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let registered = overlay.registerHotKey()
        menuBar.install(hotKeyRegistered: registered)
    }
}
