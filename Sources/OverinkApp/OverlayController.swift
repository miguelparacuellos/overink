import AppKit
import Carbon.HIToolbox
import OverinkCore

/// La shell del Overlay: traduce el atajo global y las teclas a comandos del core, y
/// monta o quita la ventana según el estado que el core devuelva. No decide nada de
/// dominio; lo único que aporta es lo que el core no puede saber —qué pantalla contiene
/// el cursor— y el instante en que ocurre cada cosa.
@MainActor
final class OverlayController {
    private var overlay = Overlay()
    private var window: OverlayWindow?
    private var hotKey: GlobalHotKey?

    /// El core recibe el instante en cada comando y nunca lee el reloj. Aquí se usa un
    /// reloj monótono: el Auto-Dismiss no debe descolocarse porque cambie la hora.
    private let launch = ContinuousClock.now

    /// Registra `Ctrl+Shift+D`. Devuelve `false` si Carbon rechaza el atajo, que es lo
    /// que pasa cuando otra aplicación ya lo tiene cogido.
    @discardableResult
    func registerHotKey() -> Bool {
        hotKey = GlobalHotKey(
            keyCode: UInt32(kVK_ANSI_D),
            modifiers: UInt32(controlKey | shiftKey)
        ) { [weak self] in
            self?.toggle()
        }
        return hotKey != nil
    }

    private func toggle() {
        // Sin ninguna pantalla no hay Stage sobre el que armar, y la shell no se inventa
        // uno: el core no debe llegar nunca a estar Armed sin superficie que responda.
        guard let stage = stageUnderCursor() else {
            apply(.dismiss)
            return
        }
        apply(.toggle(stageUnderCursor: stage))
    }

    private func apply(_ command: Command) {
        overlay.apply(command, at: Instant(sinceLaunch: ContinuousClock.now - launch))
        syncWindow()
    }

    /// Monta o quita la ventana según lo que diga el estado del core, que es la única
    /// fuente.
    private func syncWindow() {
        switch overlay.state {
        case .armed(let stage):
            show(on: stage)
        case .dismissed:
            hide()
        }
    }

    private func show(on stage: StageID) {
        guard window == nil else { return }

        // La pantalla del Stage ya no está —se desconectó entre pulsar el atajo y
        // montar—: se descarta en lugar de quedarse en Armed sin ventana, que sería un
        // estado en el que Esc no tendría a quién llegar (regla 3 de ADR-0005).
        guard let screen = Self.screen(for: stage) else {
            apply(.dismiss)
            return
        }

        let overlayWindow = OverlayWindow(stage: screen)
        let view = OverlayView(frame: overlayWindow.contentLayoutRect)
        view.autoresizingMask = [.width, .height]
        view.onKeyDown = { [weak self] event in self?.handle(event) }
        overlayWindow.contentView = view

        // Una app `.accessory` no se activa sola: sin esto la ventana se vería pero el
        // teclado seguiría yendo a la aplicación de debajo.
        NSApp.activate(ignoringOtherApps: true)
        overlayWindow.makeKeyAndOrderFront(nil)
        overlayWindow.makeFirstResponder(view)

        // Deliberadamente **no** se tocan las `presentationOptions`: activar
        // `.disableForceQuit`, `.disableProcessSwitching`, `.disableHideApplication` o
        // `.disableSessionTermination` destruiría las salidas que macOS garantiza, y la
        // regla 1 de ADR-0005 las prohíbe. El Overlay tapa la barra de menús por nivel
        // de ventana, no ocultándola.

        window = overlayWindow
    }

    private func hide() {
        guard let window else { return }

        window.orderOut(nil)
        self.window = nil
        // En Dismissed no debe quedar nada corriendo (ADR-0006): la ventana se suelta
        // entera. `deactivate()` solo saca a Overink del primer plano; a qué aplicación
        // le da el foco después lo decide macOS, no esto.
        NSApp.deactivate()
    }

    private func handle(_ event: NSEvent) {
        // Esc nunca es inerte (regla 3 de ADR-0005): desde Armed pasa a Dismissed.
        if event.keyCode == UInt16(kVK_Escape) {
            apply(.dismiss)
        }
        // Las demás teclas se las traga el Overlay sin hacer nada todavía: en Armed la
        // aplicación de debajo no recibe entrada (ADR-0002).
        //
        // Esc llega por la ventana, así que depende de que siga siendo key: si una alerta
        // del sistema se lleva el foco —y ADR-0005 exige que pueda—, vuelve en cuanto se
        // hace clic en el Overlay, que cubre la pantalla entera. La salida que no depende
        // del foco es el atajo global, que va por Carbon y no por la ventana.
    }

    /// La pantalla que contiene el cursor ahora mismo. Se consulta solo al pulsar el
    /// atajo: una vez en Armed, el Stage lo fija el core y ya no se vuelve a mirar.
    private func stageUnderCursor() -> StageID? {
        let cursor = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(cursor) } ?? NSScreen.main
        return screen.flatMap(Self.stageID(of:))
    }

    private static func screen(for stage: StageID) -> NSScreen? {
        NSScreen.screens.first { stageID(of: $0) == stage }
    }

    /// El número de display de macOS identifica la pantalla y sobrevive a reordenarlas,
    /// que es justo lo que el Stage necesita. Es lo único que cruza la costura sobre las
    /// pantallas: el core compara `StageID`, no sabe qué hay dentro.
    private static func stageID(of screen: NSScreen) -> StageID? {
        let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        return number.map { StageID("display-\($0.uint32Value)") }
    }
}
