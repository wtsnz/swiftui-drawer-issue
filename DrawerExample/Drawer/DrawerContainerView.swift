import SwiftUI

/// A view that hosts a Drawer specified by the `.drawer()` modifier. In order for the  modifier to work, it *must* be used in a child view of this `DrawerContainerView`.
///
/// Analogous to the `NavigationView` and `.navigationTitle()` modifier.
public struct DrawerContainerView<Container: View>: View {

    let container: Container

    @State private var drawers: [DrawerPreferenceState] = []

    public init(@ViewBuilder container: @escaping () -> Container) {
        self.container = container()
    }

    public var body: some View {

        let _ = Self._printChanges()

        ZStack(alignment: .top) {
            self.container
                .onPreferenceChange(DrawerOverlayPreference.self, perform: { value in
                    drawers = value
                })
                .transformPreference(DrawerOverlayPreference.self, { value in
                    // Prevent any `DrawerContainerView`s that are further up the view hierarchy
                    // from receiving the preference values from this level and below.
                    // Without this if you have a view hierarchy like the following
                    //
                    // AppView
                    //  - DrawerContainerView       (a)
                    //    - NavigationView
                    //      - HomeView
                    //    - PopoverView
                    //      - DrawerContainerView   (b)
                    //        - DropView            (c)
                    //
                    // and the `DropView` (c) configures a drawer using the `.drawer` modifier, then both
                    // (a) and (b) will receive the `DrawerOverlayPreferences` and show the drawer.
                    //
                    // This is not desired behaviour and instead we'd only want that drawer shown in
                    // the (b) `DrawerContainerView`. By reseting the preference value then we prevent
                    // this issue.

                    value = []
                })
            ZStack(alignment: .top) {
                ForEach(drawers, id: \.viewID) { contents in
                    DrawerPresenter(
                        isPresented: Binding(
                            get: {
                                contents.isPresented
                            },
                            set: { value in
                                if value == false {
                                    contents.onDismiss()
                                }
                            }
                        ),
                        showsGrabHandle: contents.showsGrabHandle,
                        content: contents.content
                            ,
                        animationEnableDelay: contents.animationEnableDelay
                    )
                }
            }
        }
    }
}
