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
        acceptsMouseMovedEvents = true
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
/// expone; la selección de Tool y Palette vive en el core, y aquí solo se refleja en el HUD.
final class OverlayView: NSView {
    /// Qué hacer con una tecla. La vista no decide nada: traduce y avisa.
    var onKeyDown: ((NSEvent) -> Void)?
    var onPointer: ((Command) -> Void)?
    var onInput: (() -> Void)?
    var canvas = Canvas() {
        didSet { invalidateFinishedMarksCache() }
    }
    var liveStroke: Stroke? {
        didSet {
            guard liveStroke != oldValue else { return }
            needsDisplay = true
        }
    }
    var laserTrail: Stroke? {
        didSet {
            guard laserTrail != oldValue else { return }
            needsDisplay = true
        }
    }
    var editingLabel: Label? {
        didSet {
            guard editingLabel != oldValue else { return }
            needsDisplay = true
        }
    }
    var activeTool = Tool.pen {
        didSet {
            guard activeTool != oldValue else { return }
            needsDisplay = true
        }
    }
    var activeColor = PaletteColor.one {
        didSet {
            guard activeColor != oldValue else { return }
            needsDisplay = true
        }
    }

    /// Los Marks terminados no cambian durante el gesto. Se rasterizan una vez por
    /// modificación del Canvas; los frames siguientes solo componen esta imagen con el
    /// contenido efímero. Así el coste de arrastrar no depende de lo lleno que esté el
    /// Canvas (ADR-0006).
    private var finishedMarksCache: NSImage?
    private var cacheSize = NSSize.zero
    private var cacheScale: CGFloat = 0

    var renderedCanvasRevision: UInt { canvas.renderingRevision }

    // Sin esto la ventana no entrega el teclado a nadie.
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        // En Armed el Overlay se queda con el teclado entero (ADR-0002). No se llama a
        // `super`: eso haría sonar el beep de tecla no manejada en todo lo que aún no
        // hace nada.
        onInput?()
        onKeyDown?(event)
    }

    override func mouseDown(with event: NSEvent) {
        onInput?()
        onPointer?(.penDown(at: point(for: event)))
    }

    override func mouseDragged(with event: NSEvent) {
        onInput?()
        onPointer?(.penMoved(to: point(for: event)))
    }

    override func mouseUp(with event: NSEvent) {
        onInput?()
        onPointer?(.penUp)
    }

    override func mouseMoved(with event: NSEvent) {
        onInput?()
    }

    override func rightMouseDown(with event: NSEvent) {
        onInput?()
    }

    override func rightMouseDragged(with event: NSEvent) {
        onInput?()
    }

    override func rightMouseUp(with event: NSEvent) {
        onInput?()
    }

    override func otherMouseDown(with event: NSEvent) {
        onInput?()
    }

    override func otherMouseDragged(with event: NSEvent) {
        onInput?()
    }

    override func otherMouseUp(with event: NSEvent) {
        onInput?()
    }

    override func scrollWheel(with event: NSEvent) {
        onInput?()
    }

    override func flagsChanged(with event: NSEvent) {
        onInput?()
    }

    override func keyUp(with event: NSEvent) {
        onInput?()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        cachedFinishedMarks().draw(in: bounds)
        drawStrokes([liveStroke, laserTrail].compactMap { $0 })
        drawLabels([editingLabel].compactMap { $0 })
        drawHUD()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        invalidateFinishedMarksCache()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        invalidateFinishedMarksCache()
    }

    private func cachedFinishedMarks() -> NSImage {
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1
        guard let finishedMarksCache, cacheSize == bounds.size, cacheScale == scale else {
            let image = renderFinishedMarksCache(scale: scale)
            finishedMarksCache = image
            cacheSize = bounds.size
            cacheScale = scale
            return image
        }
        return finishedMarksCache
    }

    private func renderFinishedMarksCache(scale: CGFloat) -> NSImage {
        let pixelsWide = max(1, Int((bounds.width * scale).rounded(.up)))
        let pixelsHigh = max(1, Int((bounds.height * scale).rounded(.up)))
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelsWide,
            pixelsHigh: pixelsHigh,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        bitmap.size = bounds.size

        let previousContext = NSGraphicsContext.current
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        // Un bitmap usa píxeles como unidad; los Marks usan puntos del Stage. Mantener
        // ambas escalas evita que la caché quede reducida en pantallas Retina.
        NSGraphicsContext.current?.cgContext.scaleBy(x: scale, y: scale)
        NSColor.clear.setFill()
        bounds.fill()
        drawStrokes(canvas.marks.compactMap { mark in
            guard case .stroke(let stroke) = mark else { return nil }
            return stroke
        })
        drawLabels(canvas.marks.compactMap { mark in
            guard case .label(let label) = mark else { return nil }
            return label
        })
        NSGraphicsContext.current = previousContext

        let image = NSImage(size: bounds.size)
        image.addRepresentation(bitmap)
        return image
    }

    private func invalidateFinishedMarksCache() {
        finishedMarksCache = nil
        needsDisplay = true
    }

    private func drawStrokes(_ strokes: [Stroke]) {
        for stroke in strokes {
            let color = NSColor(
                red: stroke.color.components.red,
                green: stroke.color.components.green,
                blue: stroke.color.components.blue,
                alpha: stroke.opacity
            )
            color.setStroke()
            color.setFill()
            let path = NSBezierPath()
            guard let first = stroke.points.first else { continue }

            path.move(to: NSPoint(x: first.x, y: first.y))
            for point in stroke.points.dropFirst() {
                path.line(to: NSPoint(x: point.x, y: point.y))
            }
            path.lineWidth = stroke.width
            path.lineCapStyle = .round
            path.lineJoinStyle = .round

            let graphicsContext = NSGraphicsContext.current?.cgContext
            if stroke.opacity < 1 {
                // El path se pinta primero en una capa transparente con `.copy`: sus
                // auto-cruces reemplazan el alpha de la capa en vez de acumularlo. Al
                // cerrar la capa, Core Graphics la compone normalmente sobre los Marks
                // que ya existían, sin borrar ni reemplazar los de otros Strokes.
                graphicsContext?.saveGState()
                graphicsContext?.beginTransparencyLayer(auxiliaryInfo: nil)
                graphicsContext?.setBlendMode(.copy)
            }
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
            if stroke.opacity < 1 {
                graphicsContext?.endTransparencyLayer()
                graphicsContext?.restoreGState()
            }
        }
    }

    private func drawLabels(_ labels: [Label]) {
        for label in labels {
            let color = NSColor(
                red: label.color.components.red,
                green: label.color.components.green,
                blue: label.color.components.blue,
                alpha: 1
            )
            label.text.draw(
                at: NSPoint(x: label.anchor.x, y: label.anchor.y),
                withAttributes: [
                    .font: NSFont.systemFont(ofSize: Label.fontSize),
                    .foregroundColor: color,
                ]
            )
        }
    }

    /// El HUD es pintura de esta vista, no un control: no instala gestos, botones ni
    /// targets. Por eso nunca modifica la Tool ni la Palette al pulsarlo.
    private func drawHUD() {
        let label = "\(activeTool.hudName) · Color \(activeColor.hudName)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.9),
        ]
        let textSize = (label as NSString).size(withAttributes: attributes)
        let inset = CGFloat(10)
        let dotSize = CGFloat(10)
        let frame = NSRect(
            x: bounds.maxX - textSize.width - dotSize - (inset * 3),
            y: bounds.maxY - textSize.height - (inset * 2) - 12,
            width: textSize.width + dotSize + (inset * 3),
            height: textSize.height + (inset * 2)
        )

        NSColor.black.withAlphaComponent(0.55).setFill()
        NSBezierPath(roundedRect: frame, xRadius: 8, yRadius: 8).fill()

        let dotFrame = NSRect(
            x: frame.minX + inset,
            y: frame.midY - dotSize / 2,
            width: dotSize,
            height: dotSize
        )
        NSColor(
            red: activeColor.components.red,
            green: activeColor.components.green,
            blue: activeColor.components.blue,
            alpha: 1
        ).setFill()
        NSBezierPath(ovalIn: dotFrame).fill()

        (label as NSString).draw(
            at: NSPoint(x: dotFrame.maxX + inset, y: frame.midY - textSize.height / 2),
            withAttributes: attributes
        )
    }

    private func point(for event: NSEvent) -> Point {
        let location = convert(event.locationInWindow, from: nil)
        return Point(x: location.x, y: location.y)
    }
}

private extension Tool {
    var hudName: String {
        switch self {
        case .pen: "Pen"
        case .highlighter: "Highlighter"
        case .eraser: "Eraser"
        case .text: "Text"
        case .laser: "Laser"
        }
    }
}

private extension PaletteColor {
    var hudName: String {
        switch self {
        case .one: "1"
        case .two: "2"
        case .three: "3"
        case .four: "4"
        }
    }
}
