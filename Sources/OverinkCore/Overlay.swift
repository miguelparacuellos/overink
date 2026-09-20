/// La máquina de estados del Overlay: la única que decide si Overink está puesto y
/// sobre qué Stage. La shell de AppKit no toma esa decisión, solo aporta el dato que el
/// core no puede conocer —qué pantalla contiene el cursor— y pinta el resultado.
public struct Overlay: Sendable {
    public private(set) var state: OverlayState
    private var contentsByStage: [StageID: StageContent] = [:]
    private var strokeInProgress: [Point] = []
    private var strokeWidth = Stroke.penWidth
    private var strokeColor = PaletteColor.one
    private var strokeOpacity = 1.0
    private var selectedTool = Tool.pen
    private var selectedColor = PaletteColor.one
    private var eraserPoint: Point?
    private var labelInProgress: Label?
    private var lastInputAt: Instant?

    private static let autoDismissDelay = Duration.seconds(15 * 60)

    public init() {
        state = .dismissed
    }

    /// Aplica un comando en un instante dado. El instante se recibe siempre desde fuera:
    /// el core nunca lee el reloj, que es lo que mantiene determinista el Auto-Dismiss.
    public mutating func apply(_ command: Command, at instant: Instant) {
        if command.isInputEvent {
            recordInput(at: instant)
        }

        switch command {
        case .toggle(let stageUnderCursor):
            switch state {
            // El Stage se fija aquí, en el instante de pasar a Armed, y no vuelve a
            // mirarse mientras dure: el atajo pulsado con el cursor en la otra pantalla
            // descarta, nunca mueve el Overlay de sitio.
            case .dismissed:
                state = .armed(
                    stage: stageUnderCursor,
                    canvas: contentsByStage[stageUnderCursor]?.canvas ?? Canvas(),
                    liveStroke: liveStroke,
                    tool: selectedTool,
                    color: selectedColor
                )
                lastInputAt = instant
            case .armed:
                cancelLiveStroke()
                state = .dismissed
                lastInputAt = nil
            case .editing:
                cancelLiveLabel()
                state = .dismissed
                lastInputAt = nil
            }
        case .dismiss:
            cancelLiveStroke()
            cancelLiveLabel()
            state = .dismissed
            lastInputAt = nil
        case .inputReceived:
            break
        case .timeTick:
            autoDismissIfNeeded(at: instant)
        case .penDown(let point):
            beginPointer(at: point)
        case .penMoved(let point):
            movePointer(to: point)
        case .penUp:
            endPointer()
        case .eraserDown(let point):
            guard case .armed(let stage, _, _, _, _) = state else { return }

            cancelLiveStroke()
            eraseMarks(touchedBy: point, and: point)
            eraserPoint = point
            state = armedState(on: stage)
        case .eraserMoved(let point):
            guard case .armed(let stage, _, _, _, _) = state, let previousPoint = eraserPoint else { return }

            eraseMarks(touchedBy: previousPoint, and: point)
            eraserPoint = point
            state = armedState(on: stage)
        case .eraserUp:
            guard case .armed(let stage, _, _, _, _) = state else { return }

            eraserPoint = nil
            state = armedState(on: stage)
        case .deleteMark(let index):
            guard case .armed(let stage, _, _, _, _) = state, canvas.marks.indices.contains(index) else { return }

            cancelLiveStroke()
            let operation = CanvasOperation.remove(canvas.marks[index], at: index)
            applyAndRecord(operation)
            state = armedState(on: stage)
        case .clear:
            guard case .armed(let stage, _, _, _, _) = state else { return }

            cancelLiveStroke()
            guard !canvas.marks.isEmpty else {
                state = armedState(on: stage)
                return
            }
            let operation = CanvasOperation.clear(canvas.marks)
            applyAndRecord(operation)
            state = armedState(on: stage)
        case .undo:
            guard case .armed(let stage, _, _, _, _) = state else { return }

            cancelLiveStroke()
            var updatedCanvas = canvas
            var updatedHistory = history
            updatedHistory.undo(on: &updatedCanvas)
            canvas = updatedCanvas
            history = updatedHistory
            state = armedState(on: stage)
        case .redo:
            guard case .armed(let stage, _, _, _, _) = state else { return }

            cancelLiveStroke()
            var updatedCanvas = canvas
            var updatedHistory = history
            updatedHistory.redo(on: &updatedCanvas)
            canvas = updatedCanvas
            history = updatedHistory
            state = armedState(on: stage)
        case .typeText(let text):
            guard case .editing(let stage, _, _, _, _) = state, var label = labelInProgress else { return }

            label.append(text)
            labelInProgress = label
            state = editingState(on: stage)
        case .confirmLabel:
            guard case .editing(let stage, _, _, _, _) = state, let label = labelInProgress else { return }

            applyAndRecord(.add(.label(label)))
            labelInProgress = nil
            state = armedState(on: stage)
        case .cancelLabel:
            guard case .editing(let stage, _, _, _, _) = state else { return }

            cancelLiveLabel()
            state = armedState(on: stage)
        case .selectTool(let tool):
            guard case .armed(let stage, _, _, _, _) = state else { return }

            cancelLiveStroke()
            selectedTool = tool
            state = armedState(on: stage)
        case .selectColor(let color):
            guard case .armed(let stage, _, _, _, _) = state else { return }

            selectedColor = color
            state = armedState(on: stage)
        case .stagesChanged(let availableStages):
            let disconnectedStages = Set(contentsByStage.keys).subtracting(availableStages)
            for stage in disconnectedStages {
                contentsByStage[stage] = nil
            }
            if let activeStage = state.stage, !availableStages.contains(activeStage) {
                cancelLiveStroke()
                state = .dismissed
                lastInputAt = nil
            }
        }
    }

    private mutating func recordInput(at instant: Instant) {
        guard state != .dismissed else { return }
        lastInputAt = instant
    }

    private mutating func autoDismissIfNeeded(at instant: Instant) {
        guard let lastInputAt,
              instant.sinceLaunch - lastInputAt.sinceLaunch >= Self.autoDismissDelay
        else { return }

        cancelLiveStroke()
        if let label = labelInProgress {
            applyAndRecord(.add(.label(label)))
        }
        cancelLiveLabel()
        state = .dismissed
        self.lastInputAt = nil
    }

    private var activeStage: StageID? {
        state.stage
    }

    private var canvas: Canvas {
        get {
            guard let activeStage else { return Canvas() }
            return contentsByStage[activeStage]?.canvas ?? Canvas()
        }
        set {
            guard let activeStage else { return }
            var content = contentsByStage[activeStage] ?? StageContent()
            content.canvas = newValue
            contentsByStage[activeStage] = content
        }
    }

    private var history: History {
        get {
            guard let activeStage else { return History() }
            return contentsByStage[activeStage]?.history ?? History()
        }
        set {
            guard let activeStage else { return }
            var content = contentsByStage[activeStage] ?? StageContent()
            content.history = newValue
            contentsByStage[activeStage] = content
        }
    }

    private var liveStroke: Stroke? {
        strokeInProgress.isEmpty ? nil : Stroke(
            points: strokeInProgress,
            width: strokeWidth,
            color: strokeColor,
            opacity: strokeOpacity
        )
    }

    private mutating func finishStroke() {
        guard !strokeInProgress.isEmpty else { return }

        let operation = CanvasOperation.add(.stroke(Stroke(
            points: strokeInProgress,
            width: strokeWidth,
            color: strokeColor,
            opacity: strokeOpacity
        )))
        applyAndRecord(operation)
        strokeInProgress = []
    }

    private mutating func applyAndRecord(_ operation: CanvasOperation) {
        var updatedCanvas = canvas
        var updatedHistory = history
        operation.apply(to: &updatedCanvas)
        updatedHistory.record(operation)
        canvas = updatedCanvas
        history = updatedHistory
    }

    private mutating func cancelLiveStroke() {
        strokeInProgress = []
        eraserPoint = nil
    }

    private mutating func cancelLiveLabel() {
        labelInProgress = nil
    }

    private func armedState(on stage: StageID) -> OverlayState {
        .armed(
            stage: stage,
            canvas: canvas,
            liveStroke: liveStroke,
            tool: selectedTool,
            color: selectedColor
        )
    }

    private func editingState(on stage: StageID) -> OverlayState {
        guard let labelInProgress else { return armedState(on: stage) }
        return .editing(
            stage: stage,
            canvas: canvas,
            label: labelInProgress,
            tool: selectedTool,
            color: selectedColor
        )
    }

    private mutating func beginPointer(at point: Point) {
        guard case .armed(let stage, _, _, _, _) = state else { return }

        switch selectedTool {
        case .pen, .highlighter:
            finishStroke()
            eraserPoint = nil
            strokeInProgress = [point]
            strokeWidth = selectedTool == .highlighter ? Stroke.highlighterWidth : Stroke.penWidth
            strokeColor = selectedColor
            strokeOpacity = selectedTool == .highlighter ? Stroke.highlighterOpacity : 1
        case .eraser:
            cancelLiveStroke()
            eraseMarks(touchedBy: point, and: point)
            eraserPoint = point
        case .text:
            cancelLiveStroke()
            labelInProgress = Label(anchor: point, text: "", color: selectedColor)
            state = editingState(on: stage)
            return
        }
        state = armedState(on: stage)
    }

    private mutating func movePointer(to point: Point) {
        guard case .armed(let stage, _, _, _, _) = state else { return }

        switch selectedTool {
        case .pen, .highlighter:
            guard !strokeInProgress.isEmpty else { return }
            strokeInProgress.append(point)
        case .eraser:
            guard let previousPoint = eraserPoint else { return }
            eraseMarks(touchedBy: previousPoint, and: point)
            eraserPoint = point
        case .text:
            return
        }
        state = armedState(on: stage)
    }

    private mutating func endPointer() {
        guard case .armed(let stage, _, _, _, _) = state else { return }

        switch selectedTool {
        case .pen, .highlighter:
            finishStroke()
        case .eraser:
            eraserPoint = nil
        case .text:
            return
        }
        state = armedState(on: stage)
    }

    /// Cada Mark alcanzado se registra por separado: `Undo` revierte el último borrado,
    /// igual que revierte el último Mark añadido o un Clear.
    private mutating func eraseMarks(touchedBy start: Point, and end: Point) {
        let touchedIndices = canvas.marks.indices.filter {
            canvas.marks[$0].isTouched(byEraserSegmentFrom: start, to: end)
        }

        // De atrás hacia delante los índices de los Marks aún no borrados no cambian.
        for index in touchedIndices.reversed() {
            let operation = CanvasOperation.remove(canvas.marks[index], at: index)
            applyAndRecord(operation)
        }
    }
}

/// El estado persistente de un Stage: Canvas e History deben tener exactamente el mismo
/// ciclo de vida porque Undo solo puede actuar sobre el Canvas al que pertenece.
private struct StageContent: Sendable {
    var canvas = Canvas()
    var history = History()
}

/// En cuál de sus estados está el Overlay. Editing, el subestado de Armed en el que se
/// escribe un Label, llega con el Text tool.
public enum OverlayState: Equatable, Sendable {
    case dismissed
    case armed(stage: StageID, canvas: Canvas, liveStroke: Stroke?, tool: Tool, color: PaletteColor)
    case editing(stage: StageID, canvas: Canvas, label: Label, tool: Tool, color: PaletteColor)

    public var stage: StageID? {
        switch self {
        case .armed(let stage, _, _, _, _), .editing(let stage, _, _, _, _): stage
        case .dismissed: nil
        }
    }

    public var tool: Tool? {
        switch self {
        case .armed(_, _, _, let tool, _), .editing(_, _, _, let tool, _): tool
        case .dismissed: nil
        }
    }

    public var color: PaletteColor? {
        switch self {
        case .armed(_, _, _, _, let color), .editing(_, _, _, _, let color): color
        case .dismissed: nil
        }
    }

    public var editingLabel: Label? {
        guard case .editing(_, _, let label, _, _) = self else { return nil }
        return label
    }
}

/// La acción que aplica el gesto del puntero. Solo una está seleccionada mientras Armed.
public enum Tool: Equatable, Sendable {
    case pen
    case highlighter
    case eraser
    case text
}

/// Los cuatro colores de la Palette. Sus componentes viven aquí, sin depender de AppKit,
/// para que todos los Mark y futuros Label reciban el mismo color seleccionado.
public enum PaletteColor: CaseIterable, Equatable, Sendable {
    case one
    case two
    case three
    case four

    public var components: PaletteComponents {
        switch self {
        case .one: PaletteComponents(red: 1, green: 0.78, blue: 0.1)
        case .two: PaletteComponents(red: 0.18, green: 0.82, blue: 0.42)
        case .three: PaletteComponents(red: 0.15, green: 0.56, blue: 1)
        case .four: PaletteComponents(red: 0.92, green: 0.23, blue: 0.32)
        }
    }
}

public struct PaletteComponents: Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

/// Las intenciones que el core entiende. Son semánticas, nunca eventos de macOS: la
/// shell traduce el atajo global y la tecla Esc a estos dos.
public enum Command: Equatable, Sendable {
    /// El atajo global: arma sobre la pantalla que contiene el cursor, o descarta.
    case toggle(stageUnderCursor: StageID)
    /// Pasar a Dismissed sin pasar por el atajo. Es lo que hace Esc.
    case dismiss
    /// Un evento de entrada que no cambia ninguna otra decisión de dominio, pero reinicia
    /// la cuenta del Auto-Dismiss.
    case inputReceived
    /// El tic de la shell para comprobar si quince minutos sin entrada deben ocultar el
    /// Overlay. No cuenta como entrada.
    case timeTick
    /// El Pen empieza, continúa o termina un gesto. La shell traduce sus eventos de
    /// puntero a estas intenciones; el core no conoce `NSEvent`.
    case penDown(at: Point)
    case penMoved(to: Point)
    case penUp
    /// Un gesto del puntero se interpreta con la Tool activa, sin que la shell tenga que
    /// tomar la decisión de dominio de qué Tool está seleccionada.
    case selectTool(Tool)
    case selectColor(PaletteColor)
    /// El Eraser no deja un trazo propio: al recorrer el gesto elimina cada Mark que toca.
    case eraserDown(at: Point)
    case eraserMoved(to: Point)
    case eraserUp
    /// Borra un Mark terminado por índice. El Eraser usa sus propios comandos de gesto;
    /// History registra ambos borrados como operaciones del Canvas.
    case deleteMark(at: Int)
    /// Vacía el Canvas entero. Como toda operación sobre el Canvas, se puede deshacer.
    case clear
    /// Revierte o reaplica la última operación del History.
    case undo
    case redo
    /// Texto que se añade al Label en curso; durante Editing no se interpreta como atajo.
    case typeText(String)
    case confirmLabel
    case cancelLabel
    /// La shell comunica el conjunto de Stages disponibles cuando macOS cambia la
    /// configuración de pantallas. El core descarta Canvas e History de los ausentes.
    case stagesChanged(to: Set<StageID>)

    fileprivate var isInputEvent: Bool {
        switch self {
        case .timeTick, .stagesChanged:
            false
        default:
            true
        }
    }
}

/// Una coordenada de la superficie del Overlay, independiente de AppKit.
public struct Point: Equatable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// El conjunto ordenado de Marks que se han terminado en el Stage actual. Vive fuera del
/// estado visible del Overlay, así que pasar a Dismissed no lo destruye.
public struct Canvas: Equatable, Sendable {
    public private(set) var marks: [Mark]

    public init(marks: [Mark] = []) {
        self.marks = marks
    }

    mutating func append(_ mark: Mark) {
        marks.append(mark)
    }

    mutating func insert(_ mark: Mark, at index: Int) {
        marks.insert(mark, at: index)
    }

    mutating func removeLastMark() {
        marks.removeLast()
    }

    mutating func removeMark(at index: Int) {
        marks.remove(at: index)
    }

    mutating func removeAllMarks() {
        marks.removeAll()
    }

    mutating func replaceMarks(with marks: [Mark]) {
        self.marks = marks
    }
}

/// Una modificación reversible del Canvas. El payload pertenece a la operación para que
/// History nunca tenga que almacenar snapshots de Marks como si fueran el historial.
private enum CanvasOperation: Sendable {
    case add(Mark)
    case remove(Mark, at: Int)
    case clear([Mark])

    func apply(to canvas: inout Canvas) {
        switch self {
        case .add(let mark):
            canvas.append(mark)
        case .remove(_, let index):
            canvas.removeMark(at: index)
        case .clear:
            canvas.removeAllMarks()
        }
    }

    func revert(on canvas: inout Canvas) {
        switch self {
        case .add:
            canvas.removeLastMark()
        case .remove(let mark, let index):
            canvas.insert(mark, at: index)
        case .clear(let marks):
            canvas.replaceMarks(with: marks)
        }
    }
}

/// El historial reversible del Canvas. Conserva operaciones, con su información para
/// revertirse, y limita ambas pilas a las cien operaciones aplicadas más recientes.
private struct History: Sendable {
    private static let capacity = 100
    private var undoStack: [CanvasOperation] = []
    private var redoStack: [CanvasOperation] = []

    mutating func record(_ operation: CanvasOperation) {
        undoStack.append(operation)
        if undoStack.count > Self.capacity {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    mutating func undo(on canvas: inout Canvas) {
        guard let operation = undoStack.popLast() else { return }

        operation.revert(on: &canvas)
        redoStack.append(operation)
    }

    mutating func redo(on canvas: inout Canvas) {
        guard let operation = redoStack.popLast() else { return }

        operation.apply(to: &canvas)
        undoStack.append(operation)
    }
}

/// Una forma terminada que vive en el Canvas. Por ahora el Pen es la única forma; Label
/// llegará con el Text tool sin cambiar la costura que lee la shell.
public enum Mark: Equatable, Sendable {
    case stroke(Stroke)
    case label(Label)

    fileprivate func isTouched(byEraserSegmentFrom start: Point, to end: Point) -> Bool {
        switch self {
        case .stroke(let stroke):
            stroke.isTouched(byEraserSegmentFrom: start, to: end)
        case .label(let label):
            label.isTouched(byEraserSegmentFrom: start, to: end)
        }
    }
}

/// Un Mark inmutable de texto, anclado al punto en el que se hizo clic con el Text tool.
public struct Label: Equatable, Sendable {
    public static let fontSize = 24.0
    public let anchor: Point
    public private(set) var text: String
    public let color: PaletteColor

    public init(anchor: Point, text: String, color: PaletteColor = .one) {
        self.anchor = anchor
        self.text = text
        self.color = color
    }

    mutating func append(_ text: String) {
        self.text.append(contentsOf: text)
    }

    fileprivate func isTouched(byEraserSegmentFrom start: Point, to end: Point) -> Bool {
        let width = max(Self.fontSize, Double(text.count) * Self.fontSize * 0.6)
        let height = Self.fontSize
        let nearestX = min(max(start.x, anchor.x), anchor.x + width)
        let nearestY = min(max(start.y, anchor.y), anchor.y + height)
        return squaredDistance(from: Point(x: nearestX, y: nearestY), to: start, end)
            <= pow2(Stroke.eraserRadius)
    }
}

/// Un Mark vectorial creado con el Pen. Sus puntos no dependen de ningún framework de UI
/// y su grosor permanece fijo, incluso cuando la entrada procede de una tableta.
public struct Stroke: Equatable, Sendable {
    public static let penWidth = 3.0
    public static let highlighterWidth = 18.0
    public static let highlighterOpacity = 0.35
    /// El radio de contacto hace que rozar un trazo no exija cruzar exactamente su eje.
    public static let eraserRadius = 8.0

    public let points: [Point]
    public let width: Double
    public let color: PaletteColor
    public let opacity: Double

    public init(
        points: [Point],
        width: Double = Self.penWidth,
        color: PaletteColor = .one,
        opacity: Double = 1
    ) {
        self.points = points
        self.width = width
        self.color = color
        self.opacity = opacity
    }

    fileprivate func isTouched(byEraserSegmentFrom start: Point, to end: Point) -> Bool {
        guard let firstPoint = points.first else { return false }

        let contactDistanceSquared = pow2(Self.eraserRadius + width / 2)
        if points.count == 1 {
            return squaredDistance(from: firstPoint, to: start, end) <= contactDistanceSquared
        }

        return zip(points, points.dropFirst()).contains { strokeStart, strokeEnd in
            segmentsIntersect(start, end, strokeStart, strokeEnd)
                || squaredDistance(from: start, to: strokeStart, strokeEnd) <= contactDistanceSquared
                || squaredDistance(from: end, to: strokeStart, strokeEnd) <= contactDistanceSquared
                || squaredDistance(from: strokeStart, to: start, end) <= contactDistanceSquared
                || squaredDistance(from: strokeEnd, to: start, end) <= contactDistanceSquared
        }
    }
}

private func pow2(_ value: Double) -> Double { value * value }

private func squaredDistance(from point: Point, to segmentStart: Point, _ segmentEnd: Point) -> Double {
    let dx = segmentEnd.x - segmentStart.x
    let dy = segmentEnd.y - segmentStart.y
    let segmentLengthSquared = pow2(dx) + pow2(dy)
    guard segmentLengthSquared > 0 else {
        return pow2(point.x - segmentStart.x) + pow2(point.y - segmentStart.y)
    }

    let projection = ((point.x - segmentStart.x) * dx + (point.y - segmentStart.y) * dy) / segmentLengthSquared
    let clampedProjection = min(1, max(0, projection))
    let closestX = segmentStart.x + clampedProjection * dx
    let closestY = segmentStart.y + clampedProjection * dy
    return pow2(point.x - closestX) + pow2(point.y - closestY)
}

private func segmentsIntersect(_ firstStart: Point, _ firstEnd: Point, _ secondStart: Point, _ secondEnd: Point) -> Bool {
    let firstOrientationAtSecondStart = orientation(firstStart, firstEnd, secondStart)
    let firstOrientationAtSecondEnd = orientation(firstStart, firstEnd, secondEnd)
    let secondOrientationAtFirstStart = orientation(secondStart, secondEnd, firstStart)
    let secondOrientationAtFirstEnd = orientation(secondStart, secondEnd, firstEnd)

    if firstOrientationAtSecondStart == 0, isOnSegment(secondStart, from: firstStart, to: firstEnd) { return true }
    if firstOrientationAtSecondEnd == 0, isOnSegment(secondEnd, from: firstStart, to: firstEnd) { return true }
    if secondOrientationAtFirstStart == 0, isOnSegment(firstStart, from: secondStart, to: secondEnd) { return true }
    if secondOrientationAtFirstEnd == 0, isOnSegment(firstEnd, from: secondStart, to: secondEnd) { return true }

    return (firstOrientationAtSecondStart > 0) != (firstOrientationAtSecondEnd > 0)
        && (secondOrientationAtFirstStart > 0) != (secondOrientationAtFirstEnd > 0)
}

private func orientation(_ start: Point, _ end: Point, _ point: Point) -> Double {
    (end.x - start.x) * (point.y - start.y) - (end.y - start.y) * (point.x - start.x)
}

private func isOnSegment(_ point: Point, from segmentStart: Point, to segmentEnd: Point) -> Bool {
    point.x >= min(segmentStart.x, segmentEnd.x)
        && point.x <= max(segmentStart.x, segmentEnd.x)
        && point.y >= min(segmentStart.y, segmentEnd.y)
        && point.y <= max(segmentStart.y, segmentEnd.y)
}

/// Identifica una pantalla sin que el core sepa nada de pantallas. La shell la deriva
/// del identificador de display de macOS; el core solo la compara.
public struct StageID: Hashable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Un instante, medido como el tiempo transcurrido desde que arrancó la app. El core lo
/// recibe en cada comando en lugar de consultar un reloj, para que los tests puedan
/// avanzar quince minutos sin esperarlos.
public struct Instant: Comparable, Hashable, Sendable {
    public let sinceLaunch: Duration

    public init(sinceLaunch: Duration) {
        self.sinceLaunch = sinceLaunch
    }

    public static func < (lhs: Instant, rhs: Instant) -> Bool {
        lhs.sinceLaunch < rhs.sinceLaunch
    }
}
