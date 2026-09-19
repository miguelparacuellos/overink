import AppKit
import Carbon.HIToolbox

/// El atajo global, registrado con `RegisterEventHotKey` de Carbon.
///
/// Carbon es API antigua, pero es la única vía para un atajo global que **no exige
/// permiso de Accesibilidad** (ADR-0002): las alternativas modernas pasan por
/// `CGEventTap` o por `addGlobalMonitorForEvents`, y ambas lo piden. Mientras eso siga
/// siendo cierto, esto se queda como está.
///
/// El registro y el `deinit` ocurren siempre en el hilo principal, porque quien tiene
/// estos objetos es `OverlayController`, que es `@MainActor`. De ahí los
/// `nonisolated(unsafe)`: Swift no puede comprobarlo por su cuenta en un `deinit`.
@MainActor
final class GlobalHotKey {
    /// Carbon llama a una función C sin contexto: del atajo pulsado solo llega su `id`,
    /// así que los handlers vivos se buscan por ahí.
    nonisolated(unsafe) private static var handlers: [UInt32: () -> Void] = [:]
    nonisolated(unsafe) private static var nextID: UInt32 = 1
    nonisolated(unsafe) private static var eventHandler: EventHandlerRef?

    private let id: UInt32
    nonisolated(unsafe) private let hotKey: EventHotKeyRef

    /// - Parameters:
    ///   - keyCode: código virtual de la tecla (`kVK_ANSI_D` y compañía).
    ///   - modifiers: máscara de Carbon (`controlKey`, `shiftKey`…), no la de AppKit.
    /// - Returns: `nil` si Carbon rechaza el atajo, que es lo que pasa cuando otra
    ///   aplicación ya lo tiene cogido.
    init?(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        // Sin handler instalado, Carbon registraría el atajo y no llamaría a nadie: el
        // menú anunciaría un atajo que no hace nada.
        guard Self.installEventHandlerIfNeeded() else { return nil }

        let id = Self.nextID
        var reference: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            EventHotKeyID(signature: Self.signature, id: id),
            GetApplicationEventTarget(),
            0,
            &reference
        )

        guard status == noErr, let reference else { return nil }

        self.id = id
        hotKey = reference
        // Los `id` no se reutilizan nunca: un atajo recién registrado no puede heredar
        // el handler de uno que acabe de morir.
        Self.nextID += 1
        Self.handlers[id] = handler
    }

    deinit {
        UnregisterEventHotKey(hotKey)
        Self.handlers[id] = nil
    }

    /// `OVRK`, la firma de cuatro caracteres que Carbon exige para agrupar atajos.
    private static let signature: OSType = 0x4F56_524B

    @discardableResult
    private static func installEventHandlerIfNeeded() -> Bool {
        guard eventHandler == nil else { return true }

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var pressed = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &pressed
                )
                guard status == noErr else { return status }

                GlobalHotKey.handlers[pressed.id]?()
                return noErr
            },
            1,
            &spec,
            nil,
            &eventHandler
        )

        return status == noErr
    }
}
