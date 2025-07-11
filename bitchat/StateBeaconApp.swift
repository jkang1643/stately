//
// StateBeaconApp.swift
// Stately - State Broadcasting System
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI
import UserNotifications

@main
struct StatelyApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    init() {
        // Request notification permissions for SOS alerts
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        requestNotificationPermissions()
    }
    
    var body: some Scene {
        WindowGroup {
            StateView()
                .preferredColorScheme(.dark) // Force dark theme for terminal look
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #endif
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("[STATE] Notification permissions granted")
            } else if let error = error {
                print("[STATE] Notification permission error: \(error)")
            }
        }
    }
}

#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Continue state broadcasting in background
        print("[STATE] App entered background - continuing state broadcasting")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("[STATE] App entering foreground")
    }
}
#endif

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        
        // Handle SOS notifications
        if identifier.hasPrefix("sos-") {
            print("[STATE] SOS notification tapped")
            // Could open app to SOS view or take other action
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    // Send SOS notification when someone nearby triggers SOS
    func sendSOSNotification(from peerName: String) {
        let content = UNMutableNotificationContent()
        content.title = "🆘 Emergency Alert"
        content.body = "\(peerName) has triggered an SOS signal nearby"
        content.sound = .default
        content.categoryIdentifier = "SOS_ALERT"
        
        let request = UNNotificationRequest(
            identifier: "sos-\(peerName)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[STATE] Error sending SOS notification: \(error)")
            }
        }
    }
}