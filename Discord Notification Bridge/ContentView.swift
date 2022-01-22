//
//  ContentView.swift
//  Discord Notification Bridge
//
//  Created by Anthony Li on 12/25/21.
//

import SwiftUI

let decoder = JSONDecoder()

struct ContentView: View {
    @ObservedObject var context = Context.shared
    @State var userSettings = UserDatabase.default.readUsers()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Users") {
                    ForEach(Array(userSettings).sorted(by: { $0.value.details.description < $1.value.details.description }), id: \.key) { user in
                        NavigationLink(destination: UserSettingsView(userID: user.key, user: $userSettings[user.key])) {
                            Text(user.value.details.description)
                        }.onChange(of: userSettings[user.key]!) { settings in
                            UserDatabase.default.writeSettings(settings, for: user.key)
                        }
                    }
                }
                
                Section("Settings") {
                    Button {
                        UIPasteboard.general.string = context.token!.base64EncodedString()
                    } label: {
                        Text("Copy APNS Token")
                    }.disabled(context.token == nil)
                }
            }.refreshable {
                userSettings = UserDatabase.default.readUsers()
            }.navigationBarTitle("Bridge")
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
