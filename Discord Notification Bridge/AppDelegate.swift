//
//  AppDelegate.swift
//  Discord Notification Bridge
//
//  Created by Anthony Li on 12/25/21.
//

import UIKit
import UserNotifications
import SwiftUI

class AppDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
    
    @MainActor func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let str = response.notification.request.content.userInfo["data"] as? String, let data = str.data(using: .utf8), let message = try? JSONDecoder().decode(Message.self, from: data) else {
            return
        }
        
        var discordURL = URL(string: "discord://-/channels")!
        discordURL.append(path: message.guild_id ?? "@me")
        discordURL.append(path: message.channel_id)
        discordURL.append(path: message.id)
        
        await UIApplication.shared.open(discordURL)
        
        #if targetEnvironment(macCatalyst)
        UIApplication.shared.openSessions.first.map { (session: UISceneSession) in
            let options = UIWindowSceneDestructionRequestOptions()
            options.windowDismissalAnimation = .standard
            UIApplication.shared.requestSceneSessionDestruction(session, options: options)
        }
        #endif
    }
}

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: { a, b in
            print(a)
            print(b)
        })
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Context.shared.token = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
}

class Context: ObservableObject {
    static var shared = Context()
    
    @Published var token: Data?
}
