/// La máquina de estados del Overlay: la única que decide si Overink está puesto y
/// sobre qué Stage. La shell de AppKit no toma esa decisión, solo aporta el dato que el
/// core no puede conocer —qué pantalla contiene el cursor— y pinta el resultado.
public struct Overlay: Sendable {
    public private(set) var state: OverlayState
    private var canvas = Canvas()
    private var strokeInProgress: [Point] = []

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
        }
    }

    private var liveStroke: Stroke? {
        strokeInProgress.isEmpty ? nil : Stroke(points: strokeInProgress)
    }

    private mutating func finishStroke() {
        guard !strokeInProgress.isEmpty else { return }

        canvas.append(.stroke(Stroke(points: strokeInProgress)))
        strokeInProgress = []
    }

    private mutating func cancelLiveStroke() {
        strokeInProgress = []
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
}

/// Una forma terminada que vive en el Canvas. Por ahora el Pen es la única forma; Label
/// llegará con el Text tool sin cambiar la costura que lee la shell.
public enum Mark: Equatable, Sendable {
    case stroke(Stroke)
}

/// Un Mark vectorial creado con el Pen. Sus puntos no dependen de ningún framework de UI
/// y su grosor permanece fijo, incluso cuando la entrada procede de una tableta.
public struct Stroke: Equatable, Sendable {
    public static let penWidth = 3.0

    public let points: [Point]
    public let width: Double

    public init(points: [Point], width: Double = Self.penWidth) {
        self.points = points
        self.width = width
    }
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
