import AppKit
import OverinkCore

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

/// La vista que ocupa el Overlay. Traduce la entrada a comandos y pinta el Canvas que el core
/// expone; la selección de Tool y el HUD llegarán con sus tickets.
final class OverlayView: NSView {
    /// Qué hacer con una tecla. La vista no decide nada: traduce y avisa.
    var onKeyDown: ((NSEvent) -> Void)?
    var onPointer: ((Command) -> Void)?
    var canvas = Canvas() {
        didSet { needsDisplay = true }
    }
    var liveStroke: Stroke? {
        didSet { needsDisplay = true }
    }

    // Sin esto la ventana no entrega el teclado a nadie.
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        // En Armed el Overlay se queda con el teclado entero (ADR-0002). No se llama a
        // `super`: eso haría sonar el beep de tecla no manejada en todo lo que aún no
        // hace nada.
        onKeyDown?(event)
    }

    override func mouseDown(with event: NSEvent) {
        onPointer?(.penDown(at: point(for: event)))
    }

    override func mouseDragged(with event: NSEvent) {
        onPointer?(.penMoved(to: point(for: event)))
    }

    override func mouseUp(with event: NSEvent) {
        onPointer?(.penUp)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.systemRed.setStroke()
        let finishedStrokes = canvas.marks.compactMap { mark -> Stroke? in
            guard case .stroke(let stroke) = mark else { return nil }
            return stroke
        }
        for stroke in finishedStrokes + [liveStroke].compactMap({ $0 }) {
            let path = NSBezierPath()
            guard let first = stroke.points.first else { continue }

            path.move(to: NSPoint(x: first.x, y: first.y))
            for point in stroke.points.dropFirst() {
                path.line(to: NSPoint(x: point.x, y: point.y))
            }
            path.lineWidth = stroke.width
            path.lineCapStyle = .round
            path.lineJoinStyle = .round

            if stroke.points.count == 1 {
                NSBezierPath(ovalIn: NSRect(
                    x: first.x - stroke.width / 2,
                    y: first.y - stroke.width / 2,
                    width: stroke.width,
                    height: stroke.width
                )).fill()
            } else {
                path.stroke()
            }
        }
    }

    private func point(for event: NSEvent) -> Point {
        let location = convert(event.locationInWindow, from: nil)
        return Point(x: location.x, y: location.y)
    }
}
