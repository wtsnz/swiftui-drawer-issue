import SwiftUI

/// A view that hosts a Drawer specified by the `.drawer()` modifier. In order for the  modifier to work, it *must* be used in a child view of this `DrawerContainerView`.
///
/// Analogous to the `NavigationView` and `.navigationTitle()` modifier.
struct DrawerPresenter: View {

    @Binding var isPresented: Bool

    @State var animationsEnabled = false

    var showsGrabHandle: Bool
    var content: AnyView
    var animationEnableDelay: UInt64

    public init(isPresented: Binding<Bool>, showsGrabHandle: Bool, content: AnyView, animationEnableDelay: UInt64) {
        self._isPresented = isPresented
        self.showsGrabHandle = showsGrabHandle
        self.content = content
        self.animationEnableDelay = animationEnableDelay
    }

    enum DragState {
        enum VerticalDirection {
            case up
            case down
        }

        case inactive
        case dragging(translation: CGSize)

        var translation: CGFloat {
            switch self {
            case .inactive:
                return 0
            case let .dragging(translation):
                return translation.height
            }
        }
    }

    @GestureState private var dragState: DragState = .inactive
    @State private var lastDragDirection: DragState.VerticalDirection = .up
    @State private var lastDragPosition: CGPoint = .zero

    // Height of the content
    @State private var contentHeight: CGFloat = 0

    // Height of the container view
    @State private var containerHeight: CGFloat = 0

    private var contentsOffset: CGFloat {
        let contentHeight: CGFloat = isPresented ? self.contentHeight : 0

        var offset: CGFloat = 0
        // Dragging up
        let translation = self.dragState.translation
        if translation < 0 {
            // Reduce the translation exponentially as it increases using the sqrt.
            // End multiple is a random number that feels similar to the popover pullup
            // Thankyou, https://stackoverflow.com/a/55508300
            let distance = sqrt(-translation) * -3.5
            offset = containerHeight - contentHeight + distance
        } else {
            offset = containerHeight - contentHeight + translation
        }

        return offset
    }

    public var body: some View {
        Self._printChanges()

        let _ = print(self.isPresented)

        return ZStack(alignment: .top) {
            // Black overlay
            Color.black
                .opacity(isPresented ? 0.2 : 0.0)
                .allowsHitTesting(isPresented)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Contents of the Drawer view
            VStack(spacing: 22) {
                if showsGrabHandle {
                    grabHandle
                        .padding(.top, 10)
                }
                content
                // Drawing group here fixes the glitch, but prevents the consumer of the API from placing and
                // user interactive/input views in the drawer/sheet - like a TextField View. Is there a way to fix
                // it without this limitation?
//                    .drawingGroup()
            }
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                alignment: .topLeading
            )
            // Measure the height of the drawer content view so we can use it later
            // to position the view based on the gesture.
            .readSize(onChange: { size in
                contentHeight = size.height
            })
            .background(
                GeometryReader { preferenceGeometry in
                    Color.gray
                    // Additional "overhang" so that when dragging upwards, the background extends past the bottom of the view
                        .frame(height: 1000, alignment: .top)
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(isPresented ? 0.2 : 0.0), radius: 22, x: 0, y: 0)
                }
            )
            // Set the views position in the parent view
            .offset(y: contentsOffset)
            .highPriorityGesture(
                DragGesture()
                    .updating($dragState) { value, state, tx in
                        switch state {
                        case .inactive:
                            state = .dragging(translation: value.translation)
                        case .dragging:
                            state = .dragging(translation: value.translation)
                        }
                    }
                    .onChanged({ value in
                        let direction: DragState.VerticalDirection = lastDragPosition.y > value.location.y ? .up : .down
                        lastDragDirection = direction
                        lastDragPosition = value.location
                    })
                    .onEnded { value in
                        switch lastDragDirection {
                        case .up:
                            isPresented = true
                        case .down:
                            isPresented = false
                        }
                    }
            )
        }
        .readSize(onChange: { size in
            containerHeight = size.height
        })
        .clipped()
        .ignoresSafeArea()
        // Info: Added a longer animation to make the issue more visible.
//        .animation(animationsEnabled ? .drawerAnimation : .none, value: contentsOffset)
        .animation(animationsEnabled ? .linear(duration: 1) : .none, value: contentsOffset)
        .task {
            // Enable animations after 10ms.
            // This is a hack to fix the issue where the drawer animate into position when the
            // view appears on screen, either in a navigation view or any other way.
            try? await Task.sleep(nanoseconds: animationEnableDelay)
            self.animationsEnabled = true
        }
    }

    private var grabHandle: some View {
        Capsule()
            .fill(Color.gray)
            .frame(width: 36, height: 6)
            .onTapGesture {
                isPresented.toggle()
            }
    }

}

public extension Animation {
    static let drawerAnimation = Animation.interactiveSpring(response: 0.35, dampingFraction: 0.7)
}
