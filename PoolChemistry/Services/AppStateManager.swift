import Foundation
import SwiftUI

// MARK: - App Mode
enum AppMode: String, Codable {
    case undetermined
    case webView
    case native
}

// MARK: - App State
enum AppState {
    case loading
    case noInternet
    case pushPermission
    case webView(url: String)
    case native
}

// MARK: - App State Description
extension AppState {
    var description: String {
        switch self {
        case .loading: return "loading"
        case .noInternet: return "noInternet"
        case .pushPermission: return "pushPermission"
        case .webView(let url): return "webView:\(url)"
        case .native: return "native"
        }
    }
}

// MARK: - App State Manager
@MainActor
class AppStateManager: ObservableObject {
    static let shared = AppStateManager()

    @Published var currentState: AppState = .loading
    @Published var isInitialized = false
    @Published var loadingProgress: String = "Initializing..."

    private let configService = ConfigService.shared
    private let appsFlyerService = AppsFlyerService.shared
    private let pushService = PushNotificationService.shared
    private let networkMonitor = NetworkMonitor.shared

    private var networkObservationTask: Task<Void, Never>?
    private var cachedURLForReconnect: String?

    private let appModeKey = "determined_app_mode"

    var savedAppMode: AppMode {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: appModeKey),
                  let mode = AppMode(rawValue: rawValue) else {
                return .undetermined
            }
            return mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: appModeKey)
        }
    }

    private let testWebViewURL: String? = nil

    private init() {}

    // MARK: - Initialize App
    func initializeApp() async {
        print("[AppStateManager] Starting initialization...")

        if let testURL = testWebViewURL {
            print("[AppStateManager] TEST MODE - Opening: \(testURL)")
            currentState = .webView(url: testURL)
            isInitialized = true
            return
        }

        loadingProgress = "Checking connection..."

        if savedAppMode != .undetermined {
            print("[AppStateManager] Mode already determined: \(savedAppMode)")
            await handleSubsequentLaunch()
            return
        }

        await handleFirstLaunch()
    }

    // MARK: - First Launch
    private func handleFirstLaunch() async {
        print("[AppStateManager] First launch flow...")

        guard networkMonitor.isConnected else {
            print("[AppStateManager] No internet on first launch")
            currentState = .noInternet
            return
        }

        loadingProgress = "Loading user's data..."

        // Delay before ATT dialog so UI has time to render
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        _ = await appsFlyerService.requestTrackingAuthorization()

        loadingProgress = "Loading user's data..."

        appsFlyerService.configure()
        appsFlyerService.start()

        loadingProgress = "Loading user's data..."

        let conversionReceived = await waitForConversionData(timeout: AppConfiguration.Timeouts.conversionDataTimeout)

        if !conversionReceived {
            print("[AppStateManager] Conversion data timeout - going native")
            savedAppMode = .native
            currentState = .native
            return
        }

        loadingProgress = "Loading user's data..."

        do {
            let response = try await configService.requestConfig(
                conversionData: appsFlyerService.conversionData,
                deepLinkData: appsFlyerService.deepLinkData,
                pushToken: pushService.fcmToken
            )

            if response.ok, let url = response.url {
                print("[AppStateManager] Config success - WebView mode")
                savedAppMode = .webView
                configService.isWebViewMode = true
                configService.isModeDetermined = true

                if pushService.shouldShowPermissionScreen {
                    currentState = .pushPermission
                } else {
                    currentState = .webView(url: url)
                }
            } else {
                print("[AppStateManager] Config returned false - Native mode")
                savedAppMode = .native
                configService.isModeDetermined = true
                currentState = .native
            }
        } catch {
            print("[AppStateManager] Config error: \(error) - Native mode")
            savedAppMode = .native
            configService.isModeDetermined = true
            currentState = .native
        }

        isInitialized = true
    }

    // MARK: - Subsequent Launch
    private func handleSubsequentLaunch() async {
        print("[AppStateManager] Subsequent launch flow...")

        switch savedAppMode {
        case .webView:
            await handleWebViewMode()
        case .native:
            currentState = .native
        case .undetermined:
            await handleFirstLaunch()
        }

        isInitialized = true
    }

    // MARK: - WebView Mode
    private func handleWebViewMode() async {
        guard networkMonitor.isConnected else {
            print("[AppStateManager] No internet on subsequent launch - showing no internet screen")
            cachedURLForReconnect = configService.storedConfig?.url
            currentState = .noInternet
            startNetworkObservation()
            return
        }

        stopNetworkObservation()

        if !appsFlyerService.isConfigured {
            appsFlyerService.configure()
        }
        appsFlyerService.start()

        if let notificationURL = pushService.pendingNotificationURL {
            pushService.clearPendingURL()
            currentState = .webView(url: notificationURL)
            return
        }

        if pushService.shouldShowPermissionScreen {
            currentState = .pushPermission
            return
        }

        if let url = await configService.getURLForWebView() {
            currentState = .webView(url: url)
        } else if let cachedURL = configService.storedConfig?.url {
            currentState = .webView(url: cachedURL)
        } else {
            currentState = .noInternet
            startNetworkObservation()
        }
    }

    // MARK: - Network Observation
    private func startNetworkObservation() {
        networkObservationTask?.cancel()

        networkObservationTask = Task { [weak self] in
            guard let self = self else { return }

            print("[AppStateManager] Started network observation")

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)

                if self.networkMonitor.isConnected {
                    print("[AppStateManager] Network restored!")
                    await MainActor.run {
                        Task {
                            await self.onNetworkRestored()
                        }
                    }
                    break
                }
            }
        }
    }

    private func stopNetworkObservation() {
        networkObservationTask?.cancel()
        networkObservationTask = nil
    }

    private func onNetworkRestored() async {
        stopNetworkObservation()

        guard savedAppMode == .webView else { return }

        if case .noInternet = currentState {
            print("[AppStateManager] Restoring WebView after network reconnection")
            await handleWebViewMode()
        }
    }

    // MARK: - Wait for Conversion Data
    private func waitForConversionData(timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if appsFlyerService.isConversionDataReceived {
                return true
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        return appsFlyerService.isConversionDataReceived
    }

    // MARK: - Actions
    func onPushPermissionAccepted() async {
        let granted = await pushService.requestPermission()
        print("[AppStateManager] Push permission granted: \(granted)")

        if let url = await configService.getURLForWebView() {
            currentState = .webView(url: url)
        } else if let cachedURL = configService.storedConfig?.url {
            currentState = .webView(url: cachedURL)
        }
    }

    func onPushPermissionSkipped() async {
        pushService.skipPermission()

        if let url = await configService.getURLForWebView() {
            currentState = .webView(url: url)
        } else if let cachedURL = configService.storedConfig?.url {
            currentState = .webView(url: cachedURL)
        }
    }

    func retryConnection() async {
        currentState = .loading
        loadingProgress = "Retrying..."

        let connected = await networkMonitor.waitForConnection(timeout: 5)

        if connected {
            if savedAppMode == .undetermined {
                await handleFirstLaunch()
            } else {
                await handleSubsequentLaunch()
            }
        } else {
            currentState = .noInternet
        }
    }

    func handleNotificationURL(_ url: String) {
        guard savedAppMode == .webView else { return }
        currentState = .webView(url: url)
    }

    func reset() {
        savedAppMode = .undetermined
        configService.reset()
        currentState = .loading
        isInitialized = false
    }
}
