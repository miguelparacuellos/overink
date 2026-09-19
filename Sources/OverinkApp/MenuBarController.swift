import AppKit

/// El ítem de la barra de menús y su menú: la única presencia permanente de Overink en
/// el sistema. Mientras el Overlay está en Dismissed —es decir, casi siempre— esto es
/// todo lo que hay.
@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem?

    /// - Parameter hotKeyRegistered: si Carbon aceptó `Ctrl+Option+D`. Si no lo hizo, el
    ///   menú es el único sitio donde el usuario puede enterarse: la app sigue viva pero
    ///   no responde al atajo.
    func install(hotKeyRegistered: Bool) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let icon = NSImage(systemSymbolName: "pencil.tip", accessibilityDescription: "Overink") {
            icon.isTemplate = true
            item.button?.image = icon
        } else {
            item.button?.title = "Overink"
        }

        item.menu = buildMenu(hotKeyRegistered: hotKeyRegistered)
        statusItem = item
    }

    private func buildMenu(hotKeyRegistered: Bool) -> NSMenu {
        let menu = NSMenu()

        let hint = NSMenuItem(
            title: hotKeyRegistered
                ? "Pulsa ⌃⌥D para anotar"
                : "⌃⌥D está cogido por otra aplicación",
            action: nil,
            keyEquivalent: ""
        )
        hint.isEnabled = false
        menu.addItem(hint)

        menu.addItem(.separator())

        menu.addItem(
            withTitle: "Salir de Overink",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        return menu
    }
}
