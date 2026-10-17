import SwiftUI

@main
struct AquaRoomApp: App {
    @StateObject private var store = RoomStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                AquariumView().tabItem { Label("水槽", systemImage: "fish") }
                AdsView().tabItem { Label("広告", systemImage: "megaphone") }
            }
            .environmentObject(store)
            .preferredColorScheme(.dark)
            .onAppear { store.start() }
        }
    }
}
