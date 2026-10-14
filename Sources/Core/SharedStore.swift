// State shared between the app and the DeviceActivity extension through an App Group.
import Foundation
import FamilyControls

enum SharedStore {
    static let groupID = "group.com.example.namazpause"
    static var defaults: UserDefaults { UserDefaults(suiteName: groupID) ?? .standard }

    static var selection: FamilyActivitySelection {
        get {
            guard let data = defaults.data(forKey: "selection"),
                  let s = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else { return .init() }
            return s
        }
        set { defaults.set(try? JSONEncoder().encode(newValue), forKey: "selection") }
    }
}
