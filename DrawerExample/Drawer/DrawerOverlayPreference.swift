import Foundation
import SwiftUI

struct DrawerOverlayPreference: PreferenceKey {
    typealias Value = [DrawerPreferenceState]

    static var defaultValue: [DrawerPreferenceState] = []

    static func reduce(value: inout [DrawerPreferenceState], nextValue: () -> [DrawerPreferenceState]) {
        value.append(contentsOf: nextValue())
    }
}
