import SwiftUI

@main
struct PoolChemistryApp: App {
    @StateObject private var manager = PoolManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appStateManager = AppStateManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(manager)
                    .environmentObject(appStateManager)
                    .environmentObject(networkMonitor)
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var manager: PoolManager
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var selectedTab: PoolTab = .dashboard

    var body: some View {
        ZStack {
            switch appStateManager.currentState {
            case .loading:
                LoadingView(message: appStateManager.loadingProgress)
                    .transition(.opacity)

            case .noInternet:
                NoInternetView {
                    Task {
                        await appStateManager.retryConnection()
                    }
                }
                .transition(.opacity)

            case .pushPermission:
                PushPermissionView(
                    onAccept: {
                        Task {
                            await appStateManager.onPushPermissionAccepted()
                        }
                    },
                    onSkip: {
                        Task {
                            await appStateManager.onPushPermissionSkipped()
                        }
                    }
                )
                .transition(.opacity)

            case .webView(let url):
                FullscreenWebView(urlString: url)
                    .transition(.opacity)

            case .native:
                // Original app content
                Group {
                    if manager.onboardingDone { MainView() } else { OnboardingView() }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appStateManager.currentState.description)
        .task {
            await appStateManager.initializeApp()
        }
    }
}
