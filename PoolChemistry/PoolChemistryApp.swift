import SwiftUI

@main
struct PoolChemistryApp: App {
    @StateObject private var manager = PoolManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if manager.onboardingDone { MainView() } else { OnboardingView() }
            }
            .environmentObject(manager)
            .preferredColorScheme(.dark)
        }
    }
}
