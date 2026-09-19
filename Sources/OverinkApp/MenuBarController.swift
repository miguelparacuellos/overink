import AppKit

/// El ítem de la barra de menús y su menú: la única presencia permanente de Overink
/// en el sistema. Mientras el Overlay está en Dismissed —es decir, casi siempre— esto
/// es todo lo que hay.
@MainActor
final class MenuBarController: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let icon = NSImage(systemSymbolName: "pencil.tip", accessibilityDescription: "Overink") {
            icon.isTemplate = true
            item.button?.image = icon
        } else {
            item.button?.title = "Overink"
        }

        item.menu = buildMenu()
        statusItem = item
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        // Todavía no hay estado que mostrar: hasta que exista el Overlay, el menú solo
        // sirve para confirmar que la app arrancó y para salir de ella.
        let alive = NSMenuItem(title: "Overink está en marcha", action: nil, keyEquivalent: "")
        alive.isEnabled = false
        menu.addItem(alive)

        menu.addItem(.separator())

        menu.addItem(
            withTitle: "Salir de Overink",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        return menu
    }
}
