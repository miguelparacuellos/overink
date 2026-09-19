import AppKit

/// La ventana del Overlay: transparente, sin marco y del tamaño exacto de su Stage.
///
/// En Armed se queda con el puntero y el teclado enteros (ADR-0002), así que es una
/// `NSWindow` normal que se hace key. Lo único inhabitual es el nivel, y está elegido a
/// conciencia: ver `overlayLevel`.
final class OverlayWindow: NSWindow {
    // Una ventana sin `titled` no puede ser key ni main por defecto, y sin ser key no
    // llegan los eventos de teclado.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    /// - Parameter stage: la pantalla sobre la que se monta. El marco se fija aquí y no
    ///   vuelve a tocarse: el Stage no cambia mientras dure Armed.
    init(stage: NSScreen) {
        super.init(
            contentRect: stage.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        level = Self.overlayLevel
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        // Que aparezca en el Space que haya activo y también sobre una app a pantalla
        // completa, sin salir en el conmutador de ventanas.
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    }

    /// Un nivel por encima de la barra de menús, que es el más bajo que aún la cubre a
    /// ella y al Dock (el Dock está más abajo todavía).
    ///
    /// La regla 2 de ADR-0005 exige justo eso, el **más bajo** que cumpla la cobertura,
    /// para que las alertas del sistema y el diálogo de Forzar salida sigan apareciendo
    /// por encima del Overlay. Subirlo a `.screenSaver` o a `CGShieldingWindowLevel`
    /// taparía esas salidas y dejaría al usuario encerrado.
    static let overlayLevel = NSWindow.Level(
        rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1
    )
}

/// La vista que ocupa el Overlay. Hoy solo recibe la entrada: el Overlay es transparente
/// y no pinta nada todavía. El Canvas y el HUD se pintan aquí cuando lleguen sus tickets.
final class OverlayView: NSView {
    /// Qué hacer con una tecla. La vista no decide nada: traduce y avisa.
    var onKeyDown: ((NSEvent) -> Void)?

    // Sin esto la ventana no entrega el teclado a nadie.
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        // En Armed el Overlay se queda con el teclado entero (ADR-0002). No se llama a
        // `super`: eso haría sonar el beep de tecla no manejada en todo lo que aún no
        // hace nada.
        onKeyDown?(event)
    }
}
