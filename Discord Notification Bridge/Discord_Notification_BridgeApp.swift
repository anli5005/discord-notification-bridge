//
//  Discord_Notification_BridgeApp.swift
//  Discord Notification Bridge
//
//  Created by Anthony Li on 12/25/21.
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

#if os(macOS)
import Cocoa
#endif

@main
struct Discord_Notification_BridgeApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    #endif
    
    #if os(macOS)
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
