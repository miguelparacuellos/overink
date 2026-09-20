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

@Test("Quince minutos sin entrada descartan el Overlay")
func quinceMinutosSinEntradaDescartanElOverlay() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.timeTick, at: Instant(sinceLaunch: .seconds(15 * 60)))

    #expect(overlay.state == .dismissed)
}

@Test("Una entrada reinicia los quince minutos del Auto-Dismiss")
func unaEntradaReiniciaLosQuinceMinutosDelAutoDismiss() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.inputReceived, at: Instant(sinceLaunch: .seconds(14 * 60)))
    overlay.apply(.timeTick, at: Instant(sinceLaunch: .seconds(15 * 60)))

    #expect(overlay.state.stage == monitor)
    overlay.apply(.timeTick, at: Instant(sinceLaunch: .seconds(29 * 60)))
    #expect(overlay.state == .dismissed)
}

@Test("El Auto-Dismiss confirma el Label que se está editando")
func elAutoDismissConfirmaElLabelQueSeEstaEditando() {
    var overlay = Overlay()
    let anchor = Point(x: 10, y: 20)

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.selectTool(.text), at: arranque)
    overlay.apply(.penDown(at: anchor), at: arranque)
    overlay.apply(.typeText("pen"), at: arranque)
    overlay.apply(.timeTick, at: Instant(sinceLaunch: .seconds(15 * 60)))

    #expect(overlay.state == .dismissed)
    overlay.apply(.toggle(stageUnderCursor: monitor), at: Instant(sinceLaunch: .seconds(15 * 60)))
    #expect(overlay.state.finishedMarks == [.label(Label(anchor: anchor, text: "pen"))])
}

@Test("El Auto-Dismiss conserva los Marks terminados del Canvas")
func elAutoDismissConservaLosMarksTerminadosDelCanvas() {
    var overlay = Overlay()
    let point = Point(x: 10, y: 20)

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.penDown(at: point), at: arranque)
    overlay.apply(.penUp, at: arranque)
    overlay.apply(.timeTick, at: Instant(sinceLaunch: .seconds(15 * 60)))

    #expect(overlay.state == .dismissed)
    overlay.apply(.toggle(stageUnderCursor: monitor), at: Instant(sinceLaunch: .seconds(15 * 60)))
    #expect(overlay.state.finishedMarks == [.stroke(Stroke(points: [point]))])
}

@Test("El tic de tiempo en Dismissed no inicia una cuenta")
func elTicDeTiempoEnDismissedNoIniciaUnaCuenta() {
    var overlay = Overlay()

    overlay.apply(.timeTick, at: Instant(sinceLaunch: .seconds(15 * 60)))

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

@Test("P, H y E cambian la Tool activa")
func lasTeclasDeToolCambianLaToolActiva() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.selectTool(.highlighter), at: arranque)
    #expect(overlay.state.tool == .highlighter)
    overlay.apply(.selectTool(.eraser), at: arranque)
    #expect(overlay.state.tool == .eraser)
    overlay.apply(.selectTool(.pen), at: arranque)

    #expect(overlay.state.tool == .pen)
}

@Test("T selecciona el Text tool")
func tSeleccionaElTextTool() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.selectTool(.text), at: arranque)

    #expect(overlay.state.tool == .text)
}

@Test("El Laser deja un rastro efímero sin añadir Marks ni operaciones al History")
func elLaserNoEntraEnCanvasNiHistory() {
    var overlay = Overlay()
    let inicio = Point(x: 10, y: 20)
    let fin = Point(x: 30, y: 40)

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    dibujaUnStroke(en: &overlay, desde: Point(x: 1, y: 2))
    overlay.apply(.selectTool(.laser), at: arranque)
    overlay.apply(.penDown(at: inicio), at: arranque)
    overlay.apply(.penMoved(to: fin), at: Instant(sinceLaunch: .seconds(1)))
    overlay.apply(.penUp, at: Instant(sinceLaunch: .seconds(1)))

    #expect(overlay.state.tool == .laser)
    #expect(overlay.state.finishedMarkCount == 1)
    #expect(overlay.state.laserTrail?.points == [inicio, fin])

    overlay.apply(.undo, at: Instant(sinceLaunch: .seconds(1)))
    #expect(overlay.state.finishedMarks.isEmpty)
}

@Test("El rastro del Laser se desvanece por completo tras dos segundos")
func elRastroDelLaserSeDesvanece() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.selectTool(.laser), at: arranque)
    overlay.apply(.penDown(at: Point(x: 10, y: 20)), at: arranque)
    overlay.apply(.timeTick, at: Instant(sinceLaunch: .seconds(1)))

    #expect(overlay.state.laserTrail?.opacity == 0.5)
    overlay.apply(.timeTick, at: Instant(sinceLaunch: .seconds(2)))
    #expect(overlay.state.laserTrail == nil)
}

@Test("Un tic de tiempo que no vence el Auto-Dismiss conserva el Label en edición")
func unTicDeTiempoConservaElLabelEnEdicion() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.selectTool(.text), at: arranque)
    overlay.apply(.penDown(at: Point(x: 10, y: 20)), at: arranque)
    overlay.apply(.typeText("Laser"), at: arranque)
    overlay.apply(.timeTick, at: Instant(sinceLaunch: .seconds(1)))

    #expect(overlay.state.editingLabel?.text == "Laser")
}

@Test("Clear y Dismissed no conservan ni afectan al rastro del Laser")
func clearYDismissedNoAfectanAlLaser() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.selectTool(.laser), at: arranque)
    overlay.apply(.penDown(at: Point(x: 10, y: 20)), at: arranque)
    overlay.apply(.clear, at: arranque)

    #expect(overlay.state.laserTrail != nil)
    #expect(overlay.state.finishedMarks.isEmpty)
    overlay.apply(.dismiss, at: arranque)
    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    #expect(overlay.state.laserTrail == nil)
}

@Test("En Editing las teclas de atajo se añaden al Label")
func enEditingLosAtajosSonTexto() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.selectTool(.text), at: arranque)
    overlay.apply(.penDown(at: Point(x: 10, y: 20)), at: arranque)
    overlay.apply(.typeText("pen"), at: arranque)

    #expect(overlay.state.editingLabel?.text == "pen")
    #expect(overlay.state.tool == .text)
}

@Test("Confirmar un Label lo añade al Canvas")
func confirmarUnLabelLoAnadeAlCanvas() {
    var overlay = Overlay()
    let anchor = Point(x: 10, y: 20)

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.selectTool(.text), at: arranque)
    overlay.apply(.penDown(at: anchor), at: arranque)
    overlay.apply(.typeText("pen"), at: arranque)
    overlay.apply(.confirmLabel, at: arranque)

    #expect(overlay.state.finishedMarks == [.label(Label(anchor: anchor, text: "pen"))])
    #expect(overlay.state.tool == .text)
}

@Test("Cancelar un Label no modifica el Canvas")
func cancelarUnLabelNoModificaElCanvas() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.selectTool(.text), at: arranque)
    overlay.apply(.penDown(at: Point(x: 10, y: 20)), at: arranque)
    overlay.apply(.typeText("pen"), at: arranque)
    overlay.apply(.cancelLabel, at: arranque)

    #expect(overlay.state.finishedMarks.isEmpty)
    #expect(overlay.state.tool == .text)
}

@Test("El Eraser borra entero un Label y Undo lo devuelve")
func elEraserBorraEnteroUnLabelYUndoLoDevuelve() {
    var overlay = Overlay()
    let label = Label(anchor: Point(x: 10, y: 20), text: "pen")

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.selectTool(.text), at: arranque)
    overlay.apply(.penDown(at: label.anchor), at: arranque)
    overlay.apply(.typeText(label.text), at: arranque)
    overlay.apply(.confirmLabel, at: arranque)
    overlay.apply(.selectTool(.eraser), at: arranque)
    borra(en: &overlay, desde: Point(x: 15, y: 25), hasta: Point(x: 15, y: 25))

    #expect(overlay.state.finishedMarks.isEmpty)
    overlay.apply(.undo, at: arranque)
    #expect(overlay.state.finishedMarks == [.label(label)])
}

@Test("El color seleccionado recibe los Strokes nuevos")
func elColorActivoLlegaAlStrokeNuevo() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    for color in PaletteColor.allCases {
        overlay.apply(.selectColor(color), at: arranque)
        #expect(overlay.state.color == color)
    }
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 20))

    #expect(overlay.state.color == .four)
    #expect(overlay.state.finishedMarks == [.stroke(Stroke(points: [Point(x: 10, y: 20)], color: .four))])
}

@Test("El Highlighter crea un Stroke translúcido y más ancho que el Pen")
func elHighlighterCreaUnStrokeTranslucidoYAncho() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.selectTool(.highlighter), at: arranque)
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 20))

    guard case .stroke(let stroke) = overlay.state.finishedMarks[0] else {
        Issue.record("El Mark nuevo debería ser un Stroke")
        return
    }
    #expect(stroke.width > Stroke.penWidth)
    #expect(stroke.opacity < 1)
}

@Test("El color activo también llega al Highlighter")
func elColorActivoLlegaAlHighlighterNuevo() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    overlay.apply(.selectColor(.two), at: arranque)
    overlay.apply(.selectTool(.highlighter), at: arranque)
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 20))

    guard case .stroke(let stroke) = overlay.state.finishedMarks[0] else {
        Issue.record("El Mark nuevo debería ser un Stroke")
        return
    }
    #expect(stroke.color == .two)
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

@Test("Cada Stage conserva sus propios Marks sin trasladarlos")
func cadaStageConservaSusPropiosMarks() {
    var overlay = Overlay()
    let strokeDelMonitor = Stroke(points: [Point(x: 10, y: 20)])
    let strokeDelPortatil = Stroke(points: [Point(x: 900, y: 600)])

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 20))
    overlay.apply(.dismiss, at: arranque)
    overlay.apply(.toggle(stageUnderCursor: portatil), at: arranque)

    #expect(overlay.state.finishedMarks.isEmpty)

    dibujaUnStroke(en: &overlay, desde: Point(x: 900, y: 600))
    overlay.apply(.dismiss, at: arranque)
    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)

    #expect(overlay.state.finishedMarks == [.stroke(strokeDelMonitor)])
    overlay.apply(.dismiss, at: arranque)
    overlay.apply(.toggle(stageUnderCursor: portatil), at: arranque)
    #expect(overlay.state.finishedMarks == [.stroke(strokeDelPortatil)])
}

@Test("Undo solo revierte el History del Stage activo")
func undoSoloRevierteElHistoryDelStageActivo() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 20))
    overlay.apply(.dismiss, at: arranque)
    overlay.apply(.toggle(stageUnderCursor: portatil), at: arranque)
    dibujaUnStroke(en: &overlay, desde: Point(x: 900, y: 600))
    overlay.apply(.undo, at: arranque)

    #expect(overlay.state.finishedMarks.isEmpty)

    overlay.apply(.dismiss, at: arranque)
    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    #expect(overlay.state.finishedMarkCount == 1)
}

@Test("Desconectar un Stage descarta su Canvas e History")
func desconectarUnStageDescartaSuCanvasEHistory() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 20))
    overlay.apply(.dismiss, at: arranque)
    overlay.apply(.stagesChanged(to: [portatil]), at: arranque)
    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)

    #expect(overlay.state.finishedMarks.isEmpty)
    overlay.apply(.undo, at: arranque)
    #expect(overlay.state.finishedMarks.isEmpty)
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

@Test("Undo después de Clear devuelve todos los Marks")
func undoDespuesDeClearDevuelveTodosLosMarks() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 20))
    dibujaUnStroke(en: &overlay, desde: Point(x: 30, y: 40))
    overlay.apply(.clear, at: arranque)
    overlay.apply(.undo, at: arranque)

    #expect(overlay.state.finishedMarkCount == 2)
}

@Test("Undo devuelve un Mark borrado")
func undoDevuelveUnMarkBorrado() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 20))
    dibujaUnStroke(en: &overlay, desde: Point(x: 30, y: 40))
    let marksAntesDeBorrar = overlay.state.finishedMarks
    overlay.apply(.deleteMark(at: 0), at: arranque)
    overlay.apply(.undo, at: arranque)

    #expect(overlay.state.finishedMarks == marksAntesDeBorrar)
}

@Test("El Eraser elimina entero el Stroke que roza")
func elEraserEliminaEnteroElStrokeQueRoza() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 10), hasta: Point(x: 30, y: 10))
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 30), hasta: Point(x: 30, y: 30))

    borra(en: &overlay, desde: Point(x: 20, y: 0), hasta: Point(x: 20, y: 20))

    #expect(overlay.state.finishedMarks == [.stroke(Stroke(points: [
        Point(x: 10, y: 30), Point(x: 30, y: 30),
    ]))])
}

@Test("Un gesto del Eraser no crea ningún Mark")
func unGestoDelEraserNoCreaNingunMark() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    borra(en: &overlay, desde: Point(x: 10, y: 10), hasta: Point(x: 30, y: 10))

    #expect(overlay.state.finishedMarkCount == 0)
}

@Test("El Eraser elimina todos los Marks que roza en un gesto")
func elEraserEliminaTodosLosMarksQueRozaEnUnGesto() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 10), hasta: Point(x: 30, y: 10))
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 30), hasta: Point(x: 30, y: 30))

    borra(en: &overlay, desde: Point(x: 20, y: 0), hasta: Point(x: 20, y: 40))

    #expect(overlay.state.finishedMarkCount == 0)
}

@Test("Undo devuelve entero el Mark eliminado por el Eraser")
func undoDevuelveEnteroElMarkEliminadoPorElEraser() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    let stroke = Stroke(points: [Point(x: 10, y: 10), Point(x: 30, y: 10)])
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 10), hasta: Point(x: 30, y: 10))
    borra(en: &overlay, desde: Point(x: 20, y: 0), hasta: Point(x: 20, y: 20))
    overlay.apply(.undo, at: arranque)

    #expect(overlay.state.finishedMarks == [.stroke(stroke)])
}

@Test("La operación más antigua deja de ser reversible al superar cien")
func laOperacionMasAntiguaDejaDeSerReversibleAlSuperarCien() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    for index in 0...100 {
        dibujaUnStroke(en: &overlay, desde: Point(x: Double(index), y: 0))
    }
    for _ in 0..<101 {
        overlay.apply(.undo, at: arranque)
    }

    #expect(overlay.state.finishedMarkCount == 1)
}

@Test("Undo y Redo restauran la misma secuencia de operaciones")
func undoYRedoRestauranLaMismaSecuenciaDeOperaciones() {
    var overlay = Overlay()

    overlay.apply(.toggle(stageUnderCursor: monitor), at: arranque)
    dibujaUnStroke(en: &overlay, desde: Point(x: 10, y: 20))
    dibujaUnStroke(en: &overlay, desde: Point(x: 30, y: 40))
    let marksAntesDeClear = overlay.state.finishedMarks
    overlay.apply(.clear, at: arranque)
    overlay.apply(.undo, at: arranque)
    overlay.apply(.undo, at: arranque)
    #expect(overlay.state.finishedMarks == [marksAntesDeClear[0]])
    overlay.apply(.redo, at: arranque)
    #expect(overlay.state.finishedMarks == marksAntesDeClear)
    overlay.apply(.redo, at: arranque)

    #expect(overlay.state.finishedMarks.isEmpty)
}

private func dibujaUnStroke(en overlay: inout Overlay, desde point: Point) {
    overlay.apply(.penDown(at: point), at: arranque)
    overlay.apply(.penUp, at: arranque)
}

private func dibujaUnStroke(en overlay: inout Overlay, desde inicio: Point, hasta fin: Point) {
    overlay.apply(.penDown(at: inicio), at: arranque)
    overlay.apply(.penMoved(to: fin), at: arranque)
    overlay.apply(.penUp, at: arranque)
}

private func borra(en overlay: inout Overlay, desde inicio: Point, hasta fin: Point) {
    overlay.apply(.eraserDown(at: inicio), at: arranque)
    overlay.apply(.eraserMoved(to: fin), at: arranque)
    overlay.apply(.eraserUp, at: arranque)
}

private extension OverlayState {
    var finishedMarkCount: Int {
        guard case .armed(_, let canvas, _, _, _, _) = self else { return 0 }
        return canvas.marks.count
    }

    var finishedMarks: [Mark] {
        guard case .armed(_, let canvas, _, _, _, _) = self else { return [] }
        return canvas.marks
    }
}
