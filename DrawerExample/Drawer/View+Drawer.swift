import Foundation
import SwiftUI

extension Binding {
    func isPresent<Wrapped>() -> Binding<Bool>
    where Value == Wrapped? {
        .init(
            get: { self.wrappedValue != nil },
            set: { isPresented in
                if !isPresented {
                    self.wrappedValue = nil
                }
            }
        )
    }
}

extension Binding {
    init?(unwrap binding: Binding<Value?>) {
        guard let wrappedValue = binding.wrappedValue
        else { return nil }

        self.init(
            get: { wrappedValue },
            set: { binding.wrappedValue = $0 }
        )
    }
}

func returningLastNonNilValue<A, B>(
    _ f: @escaping (A) -> B?
) -> (A) -> B? {
    var lastValue: B?
    return { a in
        lastValue = f(a) ?? lastValue
        return lastValue
    }
}

struct ItemDrawerModifier<Item: Identifiable, DrawerContent: View>: ViewModifier {

    @Namespace var namespace
    @Binding var item: Item?

    var showsGrabHandle: Bool = true
    var animationEnableDelay: UInt64

    @ViewBuilder var drawerContent: (Item) -> DrawerContent

    var lastNonNil: (Item?) -> Item?

    init(
        item: Binding<Item?>,
        showsGrabHandle: Bool,
        animationEnableDelay: UInt64,
        drawerContent: @escaping (Item) -> DrawerContent
    ) {
        self._item = item
        self.showsGrabHandle = showsGrabHandle
        self.animationEnableDelay = animationEnableDelay
        self.drawerContent = drawerContent

        let optionalReturningFunction: (Item?) -> Item? = { input in
            return input
        }

        self.lastNonNil = returningLastNonNilValue(optionalReturningFunction)
    }

    @ViewBuilder
    func drawerContents() -> some View {
        if let item = lastNonNil(item) {
            drawerContent(item)
        } else {
            EmptyView()
        }
    }

    func body(content: Content) -> some View {

        let _ = Self._printChanges()

        content
            .overlay {
                EmptyView()
                    .preference(
                        key: DrawerOverlayPreference.self,
                        value: [
                            .init(
                                viewID: namespace,
                                isPresented: item != nil,
                                showsGrabHandle: true,
                                content: AnyView(drawerContents()),
                                animationEnableDelay: animationEnableDelay,
                                onDismiss: {
                                    item = nil
                                }
                            )
                        ]
                    )
            }
    }
}

struct DrawerModifier<DrawerContent: View>: ViewModifier {

    @Namespace var namespace
    @Binding var isPresented: Bool

    var showsGrabHandle: Bool = true
    var animationEnableDelay: UInt64
    @ViewBuilder var drawerContent: () -> DrawerContent

    func body(content: Content) -> some View {
        content
        // NB: Views are each only allowed to set one value for a preference key
        //     if the callsite contains multiple calls to .toast() then without
        //     this, the last one would win.
        //     By creating a new leaf in the heirachy, we create a new view that
        //     can set its value for the ToastPreference, allowing us to collect
        //     all of the values set at the callsite.
            .overlay {
                EmptyView()
                    .preference(
                        key: DrawerOverlayPreference.self,
                        value: [
                            .init(
                                viewID: namespace,
                                isPresented: isPresented,
                                showsGrabHandle: showsGrabHandle,
                                content: AnyView(drawerContent()),
                                animationEnableDelay: animationEnableDelay,
                                onDismiss: {
                                    isPresented = false
                                }
                            )
                        ]
                    )
            }
    }
}

extension View {
    func drawer222<Value, Content>(
        unwrap item: Binding<Value?>,
        @ViewBuilder content: @escaping (Binding<Value>) -> Content
    ) -> some View
    where Value: Identifiable, Content: View {
        self.drawer(
            item: item,
            content: { _ in
                if let item = Binding(unwrap: item) {
                    content(item)
                }
            }
        )
    }
}

public extension View {

    @ViewBuilder
    func drawer<Item: Identifiable, Content>(
        item: Binding<Item?>,
        showsGrabHandle: Bool = true,
        animationEnableDelay: UInt64 = 10_000_000,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View where Content: View {
        self
            .modifier(
                ItemDrawerModifier(
                    item: item,
                    showsGrabHandle: showsGrabHandle,
                    animationEnableDelay: animationEnableDelay,
                    drawerContent: content
                )
            )
    }

    /// Display a drawer over the current content
    /// - Parameters:
    ///   - isPresented: A binding which determines when the content should be shown
    ///   - showsGrabHandle: Shows/hides the grab handle at the top of the sheet
    ///   - mode: The mode of the drawer. BottomSheet or Drawer
    ///   - animationEnableDelay: The duration in (ns) to wait before drawer animations are enabled. This works around some conflicts with transitions when displaying a view that shows a drawer itself.
    ///   - content: The contents of the sheet
    /// - Returns: ZStack containing `self` overlayed with the bottom sheet view
    @ViewBuilder
    func drawer<Content>(
        isPresented: Binding<Bool>,
        showsGrabHandle: Bool = true,
        animationEnableDelay: UInt64 = 10_000_000,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content: View {
        self
            .modifier(
                DrawerModifier(
                    isPresented: isPresented,
                    showsGrabHandle: showsGrabHandle,
                    animationEnableDelay: animationEnableDelay,
                    drawerContent: content
                )
            )
    }

    @ViewBuilder
    func drawerContainer() -> some View {
        DrawerContainerView {
            self
        }
    }

}
