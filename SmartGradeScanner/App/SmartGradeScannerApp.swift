import SwiftUI

@main
struct SmartGradeScannerApp: App {
    @StateObject private var store = SmartGradeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environment(\.layoutDirection, store.isArabic ? .rightToLeft : .leftToRight)
        }
    }
}

