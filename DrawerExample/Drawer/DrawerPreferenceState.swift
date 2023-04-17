//
//  DrawerPreferenceState.swift
//  DrawerExample
//
//  Created by Will Townsend on 2023-04-15.
//

import Foundation
import SwiftUI

public struct DrawerPreferenceState: Equatable, Hashable {

    public static func == (lhs: DrawerPreferenceState, rhs: DrawerPreferenceState) -> Bool {
        return lhs.viewID == rhs.viewID &&
        lhs.itemID == rhs.itemID &&
        lhs.isPresented == rhs.isPresented &&
        lhs.showsGrabHandle == rhs.showsGrabHandle &&
        lhs.animationEnableDelay == rhs.animationEnableDelay
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(viewID)
        hasher.combine(itemID)
        hasher.combine(isPresented)
        hasher.combine(showsGrabHandle)
        hasher.combine(animationEnableDelay)
    }

    var viewID: Namespace.ID
    var itemID: AnyHashable?

    var isPresented: Bool
    var showsGrabHandle: Bool
    var content: AnyView

    var animationEnableDelay: UInt64
    var onDismiss: () -> Void
}
