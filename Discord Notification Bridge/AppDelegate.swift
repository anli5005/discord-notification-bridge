//
//  AppDelegate.swift
//  Discord Notification Bridge
//
//  Created by Anthony Li on 12/25/21.
//

import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: { _, _ in })
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Context.shared.token = deviceToken
    }
}

class Context: ObservableObject {
    static var shared = Context()
    
    @Published var token: Data?
}
