import Dispatch
import Foundation
import Speech
import Testing

extension MacContractsTests {
  @Suite(.tags(.callbacks, .isolated)) @MainActor
  struct SpeechAuthorizationTests {
    @Test("G02.01 off-main authorization callbacks preserve all states")
    func offMainCallbacks() async throws {
      for expected in [SFSpeechRecognizerAuthorizationStatus.authorized, .denied, .restricted, .notDetermined] {
        let status = try await SpeechAuthorizationBridge.request { callback in
          DispatchQueue.global(qos: .userInitiated).async {
            #expect(!Thread.isMainThread)
            callback(expected)
          }
        }
        #expect(status == expected)
      }
    }

    @Test("G02.01 missing speech callback has a deadline and ignores late delivery")
    func missingSpeechCallback() async throws {
      let probe = AuthorizationCallbackProbe()
      do {
        _ = try await SpeechAuthorizationBridge.request(timeout: .milliseconds(25)) { probe.store($0) }
        Issue.record("A missing authorization callback must not report success")
      } catch let failure as VoiceCaptureFailure {
        #expect(failure == .speechPermissionTimedOut)
        #expect(failure.permissionSettingsURL?.absoluteString.contains("Privacy_SpeechRecognition") == true)
      }
      #expect(probe.hasCallback)
      probe.deliver(.authorized)
      probe.deliver(.denied)
    }

    @Test("G02.01 missing microphone callback has its own recovery destination")
    func missingMicrophoneCallback() async throws {
      do {
        _ = try await MicrophoneAuthorizationBridge.request(timeout: .milliseconds(25)) { _ in }
        Issue.record("A missing microphone callback must not report success")
      } catch let failure as VoiceCaptureFailure {
        #expect(failure == .microphonePermissionTimedOut)
        #expect(failure.permissionSettingsURL?.absoluteString.contains("Privacy_Microphone") == true)
      }
    }

    @Test("G02.01 cancellation finishes without waiting for the native callback")
    func cancelledAuthorization() async throws {
      let probe = AuthorizationCallbackProbe()
      let request = Task {
        try await SpeechAuthorizationBridge.request(timeout: .seconds(2)) { probe.store($0) }
      }
      try await PresentationWait.until { probe.hasCallback }
      request.cancel()
      do { _ = try await request.value; Issue.record("Cancelled authorization reported success") }
      catch is CancellationError {}
      probe.deliver(.authorized)
      probe.deliver(.restricted)
    }

    @Test("G02.01 an already cancelled request does not invoke the permission API")
    func cancelledBeforeRequest() async throws {
      let probe = AuthorizationCallbackProbe()
      let request = Task {
        try await SpeechAuthorizationBridge.request(timeout: .seconds(2)) { probe.store($0) }
      }
      request.cancel()
      do { _ = try await request.value; Issue.record("Cancelled authorization reported success") }
      catch is CancellationError {}
      #expect(!probe.hasCallback)
    }

    @Test("G02.01 duplicate callbacks resolve only once for speech and microphone")
    func duplicateCallbacks() async throws {
      let speech = try await SpeechAuthorizationBridge.request { callback in
        callback(.authorized); callback(.denied)
      }
      let microphone = try await MicrophoneAuthorizationBridge.request { callback in
        DispatchQueue.global(qos: .userInitiated).async { callback(true); callback(false) }
      }
      #expect(speech == .authorized && microphone)
    }
  }
}

private final class AuthorizationCallbackProbe: @unchecked Sendable {
  private let lock = NSLock()
  private var callback: (@Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void)?
  var hasCallback: Bool { lock.lock(); defer { lock.unlock() }; return callback != nil }
  func store(_ callback: @escaping @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void) {
    lock.lock(); self.callback = callback; lock.unlock()
  }
  func deliver(_ status: SFSpeechRecognizerAuthorizationStatus) {
    lock.lock(); let callback = callback; lock.unlock(); callback?(status)
  }
}
