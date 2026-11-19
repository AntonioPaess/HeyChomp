import Foundation
import Testing

extension MacContractsTests {
  @Suite(.tags(.activity, .isolated)) @MainActor
  struct OnboardingPreferenceTests {
    @Test("G08.08 a troca de com.sieghart.app para com.heychomp.mac preserva as preferências uma única vez")
    func legacyIdentifierMigration() throws {
      let fixture = try TestDefaults()
      let defaults = fixture.value
      let legacy = "Sieghart.SwiftTesting.legacy.\(UUID().uuidString)"
      defer { fixture.cleanup(); defaults.removePersistentDomain(forName: legacy) }
      defaults.setPersistentDomain(["companion.onboardingComplete": true, "awake.active": true, "shared": "antigo"], forName: legacy)
      defaults.set("novo", forKey: "shared")

      LegacyIdentifierMigration.run(defaults: defaults, legacy: legacy, current: "com.heychomp.mac")
      #expect(defaults.bool(forKey: "companion.onboardingComplete"))
      #expect(defaults.bool(forKey: "awake.active"))
      #expect(defaults.string(forKey: "shared") == "novo", "A value already in the new domain wins")
      #expect(defaults.bool(forKey: LegacyIdentifierMigration.doneKey))

      defaults.setPersistentDomain(["late": 1], forName: legacy)
      LegacyIdentifierMigration.run(defaults: defaults, legacy: legacy, current: "com.heychomp.mac")
      #expect(defaults.object(forKey: "late") == nil, "The migration runs only once")
    }

    @Test("G08.07 first run has six characters and legacy avatar restores Sig")
    func onboarding() throws {
      let fixture = try TestDefaults()
      let defaults = fixture.value
      defer { fixture.cleanup() }
      let prefs = CompanionPreferences(defaults: defaults)
      #expect(
        !prefs.onboardingComplete && CompanionAvatar.allCases.count == 6,
        "First run introduces Sig and five specialists")
      defaults.set("coast-buddy", forKey: "appearance.avatar")
      prefs.onboardingComplete = true
      let restored = CompanionPreferences(defaults: defaults)
      #expect(
        restored.onboardingComplete && restored.avatar == .sig,
        "Finishing onboarding preserves consent and fixes Sig as principal")
    }

  }
}
