/// La máquina de estados del Overlay: la única que decide si Overink está puesto y
/// sobre qué Stage. La shell de AppKit no toma esa decisión, solo aporta el dato que el
/// core no puede conocer —qué pantalla contiene el cursor— y pinta el resultado.
public struct Overlay: Sendable {
    public private(set) var state: OverlayState
    private var canvas = Canvas()
    private var strokeInProgress: [Point] = []
    private var eraserPoint: Point?
    private var history = History()

    public init() {
        state = .dismissed
    }

    /// Aplica un comando en un instante dado. El instante se recibe siempre desde fuera:
    /// el core nunca lee el reloj, que es lo que mantiene determinista el Auto-Dismiss.
    /// Ninguno de los comandos de hoy lo usa todavía.
    public mutating func apply(_ command: Command, at instant: Instant) {
        switch command {
        case .toggle(let stageUnderCursor):
            switch state {
            // El Stage se fija aquí, en el instante de pasar a Armed, y no vuelve a
            // mirarse mientras dure: el atajo pulsado con el cursor en la otra pantalla
            // descarta, nunca mueve el Overlay de sitio.
            case .dismissed:
                state = .armed(stage: stageUnderCursor, canvas: canvas, liveStroke: liveStroke)
            case .armed:
                cancelLiveStroke()
                state = .dismissed
            }
        case .dismiss:
            cancelLiveStroke()
            state = .dismissed
        case .penDown(let point):
            guard case .armed(let stage, _, _) = state else { return }

            // Empezar un gesto nuevo cierra el anterior para que una entrada incompleta
            // nunca tape el trazo que el usuario ya ha terminado.
            finishStroke()
            eraserPoint = nil
            strokeInProgress = [point]
            state = .armed(stage: stage, canvas: canvas, liveStroke: liveStroke)
        case .penMoved(let point):
            guard case .armed(let stage, _, _) = state, !strokeInProgress.isEmpty else { return }

            strokeInProgress.append(point)
            state = .armed(stage: stage, canvas: canvas, liveStroke: liveStroke)
        case .penUp:
            guard case .armed(let stage, _, _) = state else { return }

            finishStroke()
            state = .armed(stage: stage, canvas: canvas, liveStroke: liveStroke)
        case .eraserDown(let point):
            guard case .armed(let stage, _, _) = state else { return }

            cancelLiveStroke()
            eraseMarks(touchedBy: point, and: point)
            eraserPoint = point
            state = .armed(stage: stage, canvas: canvas, liveStroke: liveStroke)
        case .eraserMoved(let point):
            guard case .armed(let stage, _, _) = state, let previousPoint = eraserPoint else { return }

            eraseMarks(touchedBy: previousPoint, and: point)
            eraserPoint = point
            state = .armed(stage: stage, canvas: canvas, liveStroke: liveStroke)
        case .eraserUp:
            guard case .armed(let stage, _, _) = state else { return }

            eraserPoint = nil
            state = .armed(stage: stage, canvas: canvas, liveStroke: liveStroke)
        case .deleteMark(let index):
            guard case .armed(let stage, _, _) = state, canvas.marks.indices.contains(index) else { return }

            cancelLiveStroke()
            let operation = CanvasOperation.remove(canvas.marks[index], at: index)
            operation.apply(to: &canvas)
            history.record(operation)
            state = .armed(stage: stage, canvas: canvas, liveStroke: liveStroke)
        case .clear:
            guard case .armed(let stage, _, _) = state else { return }

            cancelLiveStroke()
            guard !canvas.marks.isEmpty else {
                state = .armed(stage: stage, canvas: canvas, liveStroke: liveStroke)
                return
            }
            let operation = CanvasOperation.clear(canvas.marks)
            operation.apply(to: &canvas)
            history.record(operation)
            state = .armed(stage: stage, canvas: canvas, liveStroke: liveStroke)
        case .undo:
            guard case .armed(let stage, _, _) = state else { return }

            cancelLiveStroke()
            history.undo(on: &canvas)
            state = .armed(stage: stage, canvas: canvas, liveStroke: liveStroke)
        case .redo:
            guard case .armed(let stage, _, _) = state else { return }

            cancelLiveStroke()
            history.redo(on: &canvas)
            state = .armed(stage: stage, canvas: canvas, liveStroke: liveStroke)
        }
    }

    private var liveStroke: Stroke? {
        strokeInProgress.isEmpty ? nil : Stroke(points: strokeInProgress)
    }

    private mutating func finishStroke() {
        guard !strokeInProgress.isEmpty else { return }

        let operation = CanvasOperation.add(.stroke(Stroke(points: strokeInProgress)))
        operation.apply(to: &canvas)
        history.record(operation)
        strokeInProgress = []
    }

    private mutating func cancelLiveStroke() {
        strokeInProgress = []
        eraserPoint = nil
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
            operation.apply(to: &canvas)
            history.record(operation)
        }
    }
}

/// En cuál de sus estados está el Overlay. Editing, el subestado de Armed en el que se
/// escribe un Label, llega con el Text tool.
public enum OverlayState: Equatable, Sendable {
    case dismissed
    case armed(stage: StageID, canvas: Canvas, liveStroke: Stroke?)

    public var stage: StageID? {
        guard case .armed(let stage, _, _) = self else { return nil }
        return stage
    }
}

/// Las intenciones que el core entiende. Son semánticas, nunca eventos de macOS: la
/// shell traduce el atajo global y la tecla Esc a estos dos.
public enum Command: Equatable, Sendable {
    /// El atajo global: arma sobre la pantalla que contiene el cursor, o descarta.
    case toggle(stageUnderCursor: StageID)
    /// Pasar a Dismissed sin pasar por el atajo. Es lo que hace Esc.
    case dismiss
    /// El Pen empieza, continúa o termina un gesto. La shell traduce sus eventos de
    /// puntero a estas intenciones; el core no conoce `NSEvent`.
    case penDown(at: Point)
    case penMoved(to: Point)
    case penUp
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

    fileprivate func isTouched(byEraserSegmentFrom start: Point, to end: Point) -> Bool {
        switch self {
        case .stroke(let stroke):
            stroke.isTouched(byEraserSegmentFrom: start, to: end)
        }
    }
}

/// Un Mark vectorial creado con el Pen. Sus puntos no dependen de ningún framework de UI
/// y su grosor permanece fijo, incluso cuando la entrada procede de una tableta.
public struct Stroke: Equatable, Sendable {
    public static let penWidth = 3.0
    /// El radio de contacto hace que rozar un trazo no exija cruzar exactamente su eje.
    public static let eraserRadius = 8.0

    public let points: [Point]
    public let width: Double

    public init(points: [Point], width: Double = Self.penWidth) {
        self.points = points
        self.width = width
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
