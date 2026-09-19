/// La máquina de estados del Overlay: la única que decide si Overink está puesto y
/// sobre qué Stage. La shell de AppKit no toma esa decisión, solo aporta el dato que el
/// core no puede conocer —qué pantalla contiene el cursor— y pinta el resultado.
public struct Overlay: Sendable {
    public private(set) var state: OverlayState

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
            case .dismissed: state = .armed(stage: stageUnderCursor)
            case .armed: state = .dismissed
            }
        case .dismiss:
            state = .dismissed
        }
    }
}

/// En cuál de sus estados está el Overlay. Editing, el subestado de Armed en el que se
/// escribe un Label, llega con el Text tool.
public enum OverlayState: Equatable, Sendable {
    case dismissed
    case armed(stage: StageID)
}

/// Las intenciones que el core entiende. Son semánticas, nunca eventos de macOS: la
/// shell traduce el atajo global y la tecla Esc a estos dos.
public enum Command: Equatable, Sendable {
    /// El atajo global: arma sobre la pantalla que contiene el cursor, o descarta.
    case toggle(stageUnderCursor: StageID)
    /// Pasar a Dismissed sin pasar por el atajo. Es lo que hace Esc.
    case dismiss
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
