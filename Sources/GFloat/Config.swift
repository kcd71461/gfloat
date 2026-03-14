import Foundation
import Carbon

struct HotkeyConfig: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let defaultHotkey = HotkeyConfig(
        keyCode: UInt32(kVK_ANSI_G),
        modifiers: UInt32(cmdKey | shiftKey)
    )
}

class Config {
    static let shared = Config()

    private let defaults = UserDefaults.standard
    private let hotkeyKey = "hotkeyConfig"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    var hotkey: HotkeyConfig {
        get {
            guard let data = defaults.data(forKey: hotkeyKey),
                  let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data) else {
                return .defaultHotkey
            }
            return config
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: hotkeyKey)
            }
        }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: hasCompletedOnboardingKey) }
        set { defaults.set(newValue, forKey: hasCompletedOnboardingKey) }
    }

    private let hideOnDeactivateKey = "hideOnDeactivate"

    var hideOnDeactivate: Bool {
        get {
            if defaults.object(forKey: hideOnDeactivateKey) == nil { return true }
            return defaults.bool(forKey: hideOnDeactivateKey)
        }
        set { defaults.set(newValue, forKey: hideOnDeactivateKey) }
    }

    var doubleEscToHide: Bool {
        get {
            if defaults.object(forKey: "doubleEscToHide") == nil { return true }
            return defaults.bool(forKey: "doubleEscToHide")
        }
        set { defaults.set(newValue, forKey: "doubleEscToHide") }
    }

    var windowWidth: Int {
        get {
            let v = defaults.integer(forKey: "windowWidth")
            return v > 0 ? v : 800
        }
        set { defaults.set(newValue, forKey: "windowWidth") }
    }

    var windowHeight: Int {
        get {
            let v = defaults.integer(forKey: "windowHeight")
            return v > 0 ? v : 800
        }
        set { defaults.set(newValue, forKey: "windowHeight") }
    }

    var windowX: Int? {
        get {
            if defaults.object(forKey: "windowX") == nil { return nil }
            return defaults.integer(forKey: "windowX")
        }
        set {
            if let v = newValue {
                defaults.set(v, forKey: "windowX")
            } else {
                defaults.removeObject(forKey: "windowX")
            }
        }
    }

    var windowY: Int? {
        get {
            if defaults.object(forKey: "windowY") == nil { return nil }
            return defaults.integer(forKey: "windowY")
        }
        set {
            if let v = newValue {
                defaults.set(v, forKey: "windowY")
            } else {
                defaults.removeObject(forKey: "windowY")
            }
        }
    }
}
