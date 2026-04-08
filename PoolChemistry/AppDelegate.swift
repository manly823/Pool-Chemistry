import UIKit
import FirebaseCore
import FirebaseMessaging
import AppsFlyerLib

class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Application Did Finish Launching
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        AppConfiguration.printStatus()

        FirebaseApp.configure()
        print("[AppDelegate] Firebase configured")

        PushNotificationService.shared.configure()
        print("[AppDelegate] Push service configured")

        // NOTE: AppsFlyer configured AFTER ATT request in AppStateManager

        return true
    }

    // MARK: - Remote Notifications
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushNotificationService.shared.handleDeviceToken(deviceToken)
        AppsFlyerLib.shared().registerUninstall(deviceToken)

        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[AppDelegate] APNS Token: \(tokenString)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[AppDelegate] Failed to register for remote notifications: \(error)")
    }

    // MARK: - Background Fetch / Silent Push
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("[AppDelegate] Received remote notification: \(userInfo)")
        PushNotificationService.shared.handleNotification(userInfo: userInfo)
        completionHandler(.newData)
    }

    // MARK: - Open URL (Deep Links)
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }

    // MARK: - Continue User Activity (Universal Links)
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return true
    }

    // MARK: - App Lifecycle
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppsFlyerService.shared.start()
    }
}
