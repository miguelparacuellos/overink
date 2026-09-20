import Darwin
import Dispatch
import Foundation

/// Vigila que el main queue pueda ejecutar trabajo mientras el Overlay está Armed.
///
/// ADR-0005 exige esta salida independiente: si el hilo principal se cuelga, ni Esc ni
/// el atajo global pueden ocultar el Overlay. Terminar el proceso es intencionado; el
/// Canvas solo existe en memoria y al morir el proceso desaparece también la ventana.
final class MainThreadWatchdog: @unchecked Sendable {
    private let lock = NSLock()
    private var timer: DispatchSourceTimer?
    private var lastMainQueueResponse: UInt64 = 0

    private let timeout: UInt64 = 5_000_000_000

    func start() {
        lock.lock()
        defer { lock.unlock() }

        guard timer == nil else { return }

        lastMainQueueResponse = DispatchTime.now().uptimeNanoseconds
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInitiated))
        timer.schedule(deadline: .now() + .seconds(1), repeating: .seconds(1))
        timer.setEventHandler { [weak self] in
            self?.checkMainQueue()
        }
        self.timer = timer
        timer.resume()
    }

    func stop() {
        lock.lock()
        let timer = self.timer
        self.timer = nil
        lock.unlock()

        timer?.cancel()
    }

    private func checkMainQueue() {
        let now = DispatchTime.now().uptimeNanoseconds

        lock.lock()
        let unresponsiveFor = now - lastMainQueueResponse
        let isRunning = timer != nil
        lock.unlock()

        guard isRunning else { return }

        if unresponsiveFor >= timeout {
            exit(EXIT_FAILURE)
        }

        DispatchQueue.main.async { [weak self] in
            self?.recordMainQueueResponse()
        }
    }

    private func recordMainQueueResponse() {
        lock.lock()
        lastMainQueueResponse = DispatchTime.now().uptimeNanoseconds
        lock.unlock()
    }
}
