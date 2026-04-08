import Foundation
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

// MARK: - Push Notification Service
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()

    private let pushPermissionRequestedKey = "push_permission_requested"
    private let pushPermissionSkippedKey = "push_permission_skipped_date"
    private let fcmTokenKey = "fcm_push_token"

    @Published var fcmToken: String?
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNotificationURL: String?

    var hasRequestedPermission: Bool {
        get { UserDefaults.standard.bool(forKey: pushPermissionRequestedKey) }
        set { UserDefaults.standard.set(newValue, forKey: pushPermissionRequestedKey) }
    }

    var lastSkippedDate: Date? {
        get { UserDefaults.standard.object(forKey: pushPermissionSkippedKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: pushPermissionSkippedKey) }
    }

    private var skipInterval: TimeInterval { AppConfiguration.PushNotifications.retryInterval }

    var shouldShowPermissionScreen: Bool {
        if authorizationStatus == .authorized { return false }
        if authorizationStatus == .denied { return false }
        if !hasRequestedPermission && lastSkippedDate == nil { return true }

        if let skippedDate = lastSkippedDate {
            let elapsed = Date().timeIntervalSince(skippedDate)
            return elapsed >= skipInterval
        }

        return false
    }

    private override init() {
        super.init()
        fcmToken = UserDefaults.standard.string(forKey: fcmTokenKey)
    }

    // MARK: - Configure Firebase Messaging
    func configure() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - Check Authorization Status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        hasRequestedPermission = true

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )

            await MainActor.run {
                checkAuthorizationStatus()
            }

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }

            return granted
        } catch {
            print("[PushService] Permission request error: \(error)")
            return false
        }
    }

    // MARK: - Skip Permission
    func skipPermission() {
        lastSkippedDate = Date()
    }

    // MARK: - Register for Remote Notifications
    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Handle Notification
    func handleNotification(userInfo: [AnyHashable: Any]) {
        print("[PushService] Received notification: \(userInfo)")

        if let data = userInfo["data"] as? [String: Any],
           let url = data["url"] as? String, !url.isEmpty {
            pendingNotificationURL = url
        } else if let url = userInfo["url"] as? String, !url.isEmpty {
            pendingNotificationURL = url
        }
    }

    // MARK: - Clear Pending URL
    func clearPendingURL() {
        pendingNotificationURL = nil
    }

    // MARK: - Handle Device Token
    func handleDeviceToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

// MARK: - MessagingDelegate
extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("[PushService] FCM token: \(fcmToken ?? "nil")")

        guard let token = fcmToken else { return }

        DispatchQueue.main.async {
            self.fcmToken = token
            UserDefaults.standard.set(token, forKey: self.fcmTokenKey)
            ConfigService.shared.updatePushToken(token)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("[PushService] Foreground notification: \(userInfo)")
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("[PushService] Notification tapped: \(userInfo)")
        handleNotification(userInfo: userInfo)
        completionHandler()
    }
}
