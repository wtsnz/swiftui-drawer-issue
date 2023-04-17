//
//  ContentView.swift
//  DrawerExample
//
//  Created by Will Townsend on 2023-04-15.
//

import SwiftUI

struct ContentView: View {

    struct SheetContent: Identifiable {
        var id: UUID
    }

    struct SheetContentDetails: Identifiable {
        var id: UUID
        var showsImage: Bool
        var title: String
        var description: String
        var action: () -> Void
    }

    @State var isSheetShown: Bool = false
    @State var sheetContent: SheetContent? = nil

    @State var isDrawerShown: Bool = false
    @State var drawerContent: SheetContent? = nil
    @State var drawerContentDetail: SheetContentDetails? = nil

    var body: some View {
        NavigationView {
            List {
                Section("Built-in Sheet") {
                    Button("Show Sheet (isPresented)", action: {
                        isSheetShown = true
                    })

                    Button("Show Sheet (item)", action: {
                        sheetContent = .init(id: .init())
                    })
                }


                Section(
                    """
                    Our .drawer
                    """,
                    content: {
                        Button("Show drawer (isPresented)", action: {
                            isDrawerShown = true
                        })

                        Button("Show drawer (item)", action: {
                            drawerContent = .init(id: .init())
                        })

                        Button("Show drawer (detail)", action: {
                            drawerContentDetail = .init(id: .init(), showsImage: true, title: "Title", description: "Description!", action: {
                                print("tapped")
                            })
                        })
                    }
                )
            }
            .navigationTitle("Drawer Examples")
            .sheet(
                isPresented: $isSheetShown,
                onDismiss: {
                    print("dismissed")
                },
                content: {
                    HStack {
                        Spacer()
                        VStack {
                            Text("Title")
                            Text("\(isSheetShown.description)")
                        }
                        Spacer()
                    }
                    .padding(40)
                }
            )
            .sheet(
                item: $sheetContent,
                content: { value in
                    HStack {
                        Spacer()
                        VStack {
                            Text("Title")
                            Text("\(value.id)")
                        }
                        Spacer()
                    }
                    .padding(40)
                }
            )

            // Drawer using the isPresented:content: initialiser
            .drawer(
                isPresented: $isDrawerShown,
                content: {
                    ZStack {
                        HStack {
                            Spacer()
                            VStack(spacing: 10) {
                                Text("Drawer based on Bool")
                                    .font(.title)

                                TextField("sdfsdf", text: .constant("sdf"))

                                Text("This drawer is shown using a isPresented overload. A Binding<Bool> controls when this drawer is visible or not.")

                                // Issue:
                                // If any of the views in the drawers content are added/removed based on the state, the drawer "show" animation is not correct.
                                if isDrawerShown {
                                    Image(systemName: "folder.fill.badge.plus")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(isDrawerShown ? .white : .green)
                                }
                                Text("Any view in the drawers content that is conditional based on outside state causes the view to act oddly. See the Text View below during the presentation/dismiss animation.")

                                // Issue:
                                // Any view in the drawers content that is conditional based on outside state causes the view to act oddly. Why?
                                Text("\(isDrawerShown ? "shown" : "not shown")")
                                    .padding()
                                    // Issue: The background of the view works as expected though...? Why?
                                    .background(.green)

                                Button("Dismiss", action: {
                                    isDrawerShown = false
                                })
                            }
                            Spacer()
                        }
                        .padding()
                        .padding(.bottom, 40)
                    }
                    .background(isDrawerShown ? .red : .yellow)
                }
            )

            // Drawer using the item:content: initialiser
            .drawer(
                item: $drawerContent,
                content: { item in
                    VStack {
                        Text("Drawer based on Bool")
                            .font(.title)

                        Text("This drawer is shown using a item overload. A Binding<Item?> controls when this drawer is visible or not.")

                        // Issue:
                        // Again, any view in the drawers content here that uses the item causes that view to act oddly. Why?

                        Text(item.id.uuidString)
                            .monospaced()
                            .background(Color.red.ignoresSafeArea())

                        Image(systemName: "folder.fill.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)

                        Button("Close", action: {
                            withAnimation(.easeIn) {
                                drawerContent = nil
                            }
                        })
                    }
                    .padding()
                    .padding(.bottom, 60)
                }
            )

            // Drawer using the item:content: initialiser
            .drawer(
                item: $drawerContentDetail,
                content: { item in
                    VStack {
                        Text(item.title)
                            .font(.title)

                        Text(item.description)

                        // Issue:
                        // Again, any view in the drawers content here that uses the item causes that view to act oddly. Why?
                        Text(item.id.uuidString)

                        if item.showsImage {
                            Image(systemName: "folder.fill.badge.plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                        }

                        Button("Close", action: {
                            item.action()
                        })
                    }
                    .padding()
                    .padding(.bottom, 60)
                }
            )

        }
        .drawerContainer()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
