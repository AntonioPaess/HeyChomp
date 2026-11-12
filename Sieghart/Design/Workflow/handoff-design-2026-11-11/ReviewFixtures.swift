import AppKit
import CoreAudio
import SwiftUI

final class CatalogSensor: AccelerometerProviding {
    var onSample: ((AccelerationSample) -> Void)?
    let isRunning = false
    func start() throws { throw UtilityFailure(message:"Controle disponível no app principal.") }
    func stop() {}
}
@MainActor final class CatalogSystem: SystemSampling {
    func read() -> MonitorReading {
        var value = MonitorReading(); value.sampledAt = Date()
        value.memoryTotal = 16_000_000_000; value.memoryUsed = 7_000_000_000
        value.memoryPressure = "Normal"; value.thermalState = "Normal"
        value.battery = 0.8; value.batteryHealth = 0.95; value.onAC = true
        return value
    }
}
@MainActor final class CatalogAwake: AwakeBackend {
    func context() -> AwakeContext { .init() }
    func acquire(display: Bool) throws -> UInt32 { throw UtilityFailure(message:"Controle disponível no app principal.") }
    func isHeld(_ token: UInt32, display: Bool) -> Bool { false }
    func release(_ token: UInt32) {  }
}
@MainActor final class CatalogDisplay: DisplayPowerBackend {
    func displays() -> [DisplayInfo] { [.init(id: 1, name: "Tela de exemplo", builtIn: true, brightness: 0.7, hdrHeadroom: 1)] }
    func brightness(_ value: Double, display: CGDirectDisplayID) throws { throw UtilityFailure(message:"Controle disponível no app principal.") }
    func dim(_ value: Double, display: CGDirectDisplayID) throws { throw UtilityFailure(message:"Controle disponível no app principal.") }
    func restore() {}
    func sleepDisplays() throws { throw UtilityFailure(message:"Controle disponível no app principal.") }
    func connectedBluetooth() -> [String] { [] }
    func disconnectBluetooth(_ id: String) throws { throw UtilityFailure(message:"Controle disponível no app principal.") }
    func reconnectBluetooth(_ id: String) throws { throw UtilityFailure(message:"Controle disponível no app principal.") }
}
@MainActor final class CatalogAudio: AudioBackend {
    func snapshot() -> AudioSnapshot { .init() }
    func prepareApplicationAudio() async throws { throw UtilityFailure(message:"Controle disponível no app principal.") }
    func setVolume(_ volume: Float, device: UInt32, input: Bool) throws { throw UtilityFailure(message:"Controle disponível no app principal.") }
    func setDefault(_ device: UInt32, input: Bool) throws { throw UtilityFailure(message:"Controle disponível no app principal.") }
    func setInputMuted(_ muted: Bool, device: UInt32) throws { throw UtilityFailure(message:"Controle disponível no app principal.") }
    func setApplication(_ app: AudioApplicationInfo, gain: Float, output: AudioDeviceInfo) throws { throw UtilityFailure(message:"Controle disponível no app principal.") }
    func retainApplications(_ ids: Set<String>) {}
    func stopApplications() {}
}
