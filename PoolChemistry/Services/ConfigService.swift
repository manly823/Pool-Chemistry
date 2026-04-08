import Foundation
import UIKit

// MARK: - Config Response
struct ConfigResponse: Codable {
    let ok: Bool
    let url: String?
    let expires: TimeInterval?
    let message: String?
}

// MARK: - Stored Config
struct StoredConfig: Codable {
    let url: String
    let expires: TimeInterval
    let savedAt: Date

    var isExpired: Bool {
        let expirationDate = Date(timeIntervalSince1970: expires)
        return Date() > expirationDate
    }
}

// MARK: - Config Service
class ConfigService: ObservableObject {
    static let shared = ConfigService()

    private var configEndpoint: String { AppConfiguration.Config.endpoint }

    private let storedConfigKey = "stored_config_data"
    private let appModeKey = "app_mode_determined"
    private let webViewModeKey = "is_webview_mode"

    @Published var currentURL: String?
    @Published var isLoading = false
    @Published var configError: Error?

    var isModeDetermined: Bool {
        get { UserDefaults.standard.bool(forKey: appModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: appModeKey) }
    }

    var isWebViewMode: Bool {
        get { UserDefaults.standard.bool(forKey: webViewModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: webViewModeKey) }
    }

    var storedConfig: StoredConfig? {
        get {
            guard let data = UserDefaults.standard.data(forKey: storedConfigKey),
                  let config = try? JSONDecoder().decode(StoredConfig.self, from: data) else {
                return nil
            }
            return config
        }
        set {
            if let config = newValue,
               let data = try? JSONEncoder().encode(config) {
                UserDefaults.standard.set(data, forKey: storedConfigKey)
            } else {
                UserDefaults.standard.removeObject(forKey: storedConfigKey)
            }
        }
    }

    private init() {}

    // MARK: - Request Config
    func requestConfig(
        conversionData: ConversionData?,
        deepLinkData: DeepLinkData?,
        pushToken: String?
    ) async throws -> ConfigResponse {
        isLoading = true
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }

        guard let url = URL(string: configEndpoint) else {
            throw ConfigError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = AppConfiguration.Timeouts.configRequestTimeout

        var body: [String: Any] = [:]

        if let conversionData = conversionData {
            for (key, value) in conversionData.toDictionary() {
                body[key] = value
            }
        }

        if let deepLinkData = deepLinkData {
            for (key, value) in deepLinkData.toDictionary() {
                if body[key] == nil {
                    body[key] = value
                }
            }
        }

        body["af_id"] = AppsFlyerService.shared.appsFlyerUID
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["os"] = "iOS"
        body["store_id"] = "id\(AppConfiguration.AppsFlyer.appleAppID)"
        body["locale"] = Locale.current.identifier
        body["firebase_project_id"] = AppConfiguration.Firebase.projectID

        if let pushToken = pushToken {
            body["push_token"] = pushToken
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData

        print("[ConfigService] Sending request with body: \(body)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConfigError.invalidResponse
        }

        print("[ConfigService] Response status: \(httpResponse.statusCode)")

        let configResponse = try JSONDecoder().decode(ConfigResponse.self, from: data)

        if httpResponse.statusCode == 200 && configResponse.ok {
            if let urlString = configResponse.url, let expires = configResponse.expires {
                let stored = StoredConfig(url: urlString, expires: expires, savedAt: Date())
                storedConfig = stored

                await MainActor.run {
                    currentURL = urlString
                }
            }
            return configResponse
        } else {
            throw ConfigError.serverError(message: configResponse.message ?? "Unknown error")
        }
    }

    // MARK: - Get URL for WebView
    func getURLForWebView() async -> String? {
        do {
            let response = try await requestConfig(
                conversionData: AppsFlyerService.shared.conversionData,
                deepLinkData: AppsFlyerService.shared.deepLinkData,
                pushToken: PushNotificationService.shared.fcmToken
            )
            return response.url
        } catch {
            print("[ConfigService] Failed to get fresh URL: \(error), using cached URL")
            if let stored = storedConfig {
                currentURL = stored.url
                return stored.url
            }
            return nil
        }
    }

    // MARK: - Update Push Token
    func updatePushToken(_ token: String) {
        guard isWebViewMode else { return }

        Task {
            do {
                _ = try await requestConfig(
                    conversionData: AppsFlyerService.shared.conversionData,
                    deepLinkData: AppsFlyerService.shared.deepLinkData,
                    pushToken: token
                )
                print("[ConfigService] Push token updated successfully")
            } catch {
                print("[ConfigService] Failed to update push token: \(error)")
            }
        }
    }

    // MARK: - Reset
    func reset() {
        storedConfig = nil
        isModeDetermined = false
        isWebViewMode = false
        currentURL = nil
    }
}

// MARK: - Config Error
enum ConfigError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(message: String)
    case noInternet
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid configuration URL"
        case .invalidResponse: return "Invalid server response"
        case .serverError(let message): return message
        case .noInternet: return "No internet connection"
        case .timeout: return "Request timed out"
        }
    }
}
