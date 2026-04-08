import Foundation

// MARK: - App Configuration

enum AppConfiguration {

    // MARK: - AppsFlyer Configuration
    enum AppsFlyer {
        static let devKey = "3va2dnoWfaJrcGpRd2AGnW"
        static let appleAppID = "6761384053"
    }

    // MARK: - Config Endpoint
    enum Config {
        static let endpoint = "https://poolchemistryio.com/config.php"
    }

    // MARK: - URLs
    enum URLs {
        static let siteURL = "https://poolchemistryio.com"
        static let privacyPolicy = "https://poolchemistryio.com/privacy-policy.html"
        static let support = "https://poolchemistryio.com/support.html"
    }

    // MARK: - App Store
    enum AppStore {
        static var storeID: String {
            return "id\(AppsFlyer.appleAppID)"
        }
    }

    // MARK: - Bundle Info
    enum Bundle {
        static var bundleID: String {
            return Foundation.Bundle.main.bundleIdentifier ?? "com.example.app"
        }

        static var appVersion: String {
            return Foundation.Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        }

        static var buildNumber: String {
            return Foundation.Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        }
    }

    // MARK: - Firebase
    enum Firebase {
        static let projectID = "pool-chemistryio"

        static var projectNumber: String {
            if let path = Foundation.Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path),
               let gcmSenderID = dict["GCM_SENDER_ID"] as? String {
                return gcmSenderID
            }
            return ""
        }
    }

    // MARK: - Push Notifications
    enum PushNotifications {
        static let retryInterval: TimeInterval = 259200 // 3 days
    }

    // MARK: - Timeouts
    enum Timeouts {
        static let conversionDataTimeout: TimeInterval = 15
        static let configRequestTimeout: TimeInterval = 30
        static let organicRetryDelay: TimeInterval = 5
    }

    // MARK: - Debug
    enum Debug {
        static var isAppsFlyerDebugEnabled: Bool {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }

        static var isLoggingEnabled: Bool {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
    }
}

// MARK: - Configuration Validation
extension AppConfiguration {
    static func validate() -> [String] {
        var errors: [String] = []

        if AppsFlyer.devKey.isEmpty {
            errors.append("AppsFlyer Dev Key not configured")
        }

        if AppsFlyer.appleAppID.isEmpty {
            errors.append("Apple App ID not configured")
        }

        if Config.endpoint.isEmpty {
            errors.append("Config Endpoint not configured")
        }

        if Firebase.projectNumber.isEmpty {
            errors.append("Firebase Project Number not found (check GoogleService-Info.plist)")
        }

        return errors
    }

    static func printStatus() {
        print("[Config] Bundle ID: \(Bundle.bundleID)")
        print("[Config] App Version: \(Bundle.appVersion) (\(Bundle.buildNumber))")
        print("[Config] Firebase Project: \(Firebase.projectNumber)")

        let errors = validate()
        if errors.isEmpty {
            print("[Config] All configurations set correctly")
        } else {
            errors.forEach { print("[Config] ERROR: \($0)") }
        }
    }
}
