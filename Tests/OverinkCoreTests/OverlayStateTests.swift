import Testing

@testable import OverinkCore

// Los tests conducen el core solo a través de su interfaz de comandos y comprueban el
// estado observable. Se leen como guiones de uso: "pulso el atajo con el cursor en el
// monitor; el Overlay queda Armed sobre el monitor".
//
// Este es el primer fichero de tests del proyecto y fija el patrón: nada de estructuras
// internas, nada de comprobar que se llamó a tal método.

private let monitor = StageID("monitor")
private let portatil = StageID("portatil")

// El instante es un parámetro de la costura, no algo que el core lea del reloj. Mientras
// no exista el Auto-Dismiss (ticket 11) los guiones no necesitan avanzarlo.
private let arranque = Instant(sinceLaunch: .zero)

@Test("Al arrancar, el Overlay está Dismissed")
func arrancaDismissed() {
    let overlay = Overlay()

    #expect(overlay.state == .dismissed)
}

@Test("El atajo arma el Overlay sobre la pantalla que contiene el cursor")
func elAtajoArmaSobreLaPantallaDelCursor() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)

    #expect(overlay.state.stage == monitor)
}

@Test("El atajo pulsado de nuevo devuelve el Overlay a Dismissed")
func elAtajoPulsadoDeNuevoDescarta() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)

    #expect(overlay.state == .dismissed)
}

@Test("El Stage no cambia aunque el cursor esté en la otra pantalla al volver a pulsar")
func elStageNoSaltaDePantalla() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    // El cursor se ha ido al portátil: el atajo descarta, no rearma allí.
    overlay.apply(.toggle(stageUnderCursor: portatil), at: arranque)

    #expect(overlay.state == .dismissed)
}

@Test("Pasando por Dismissed, el Overlay se arma sobre la otra pantalla")
func pasandoPorDismissedSeCambiaDeStage() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.toggle(stageUnderCursor: portatil), at: arranque)

    #expect(overlay.state.stage == portatil)
}

@Test("Esc pasa a Dismissed")
func escDescarta() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.dismiss, at: arranque)

    #expect(overlay.state == .dismissed)
}

@Test("Descartar estando ya en Dismissed no cambia nada")
func descartarEnDismissedEsInocuo() {
    var overlay = Overlay()

    overlay.apply(.dismiss, at: arranque)

    #expect(overlay.state == .dismissed)
}

@Test("Un gesto del Pen deja un Stroke visible")
func unGestoDelPenDejaUnStrokeVisible() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.penDown(at: Point(x: 10, y: 20)), at: arranque)
    overlay.apply(.penMoved(to: Point(x: 30, y: 40)), at: arranque)
    overlay.apply(.penUp, at: arranque)

    #expect(overlay.state.finishedMarkCount == 1)
}

@Test("Los Strokes reaparecen al volver a armar el Overlay")
func losStrokesReaparecenAlVolverAArmarElOverlay() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.penDown(at: Point(x: 10, y: 20)), at: arranque)
    overlay.apply(.penMoved(to: Point(x: 30, y: 40)), at: arranque)
    overlay.apply(.penUp, at: arranque)
    overlay.apply(.dismiss, at: arranque)
    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)

    #expect(overlay.state.finishedMarkCount == 1)
}

@Test("Descartar durante un gesto no termina el Stroke")
func descartarDuranteUnGestoNoTerminaElStroke() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.penDown(at: Point(x: 10, y: 20)), at: arranque)
    overlay.apply(.penMoved(to: Point(x: 30, y: 40)), at: arranque)
    overlay.apply(.dismiss, at: arranque)
    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)

    #expect(overlay.state.finishedMarkCount == 0)
}

private extension OverlayState {
    var finishedMarkCount: Int {
        guard case .armed(_, let canvas, _) = self else { return 0 }
        return canvas.marks.count
    }
}
