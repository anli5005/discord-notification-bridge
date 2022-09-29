//
//  ContentView.swift
//  Discord Notification Bridge
//
//  Created by Anthony Li on 12/25/21.
//

import SwiftUI

let decoder = JSONDecoder()

extension Image {
    init(platformImage: UIImage) {
        self.init(uiImage: platformImage)
    }
}

func getImage(data: Data) -> UIImage? {
    UIImage(data: data)
}

struct UserButton: View {
    var user: User
    var avatar: UIImage?
    
    var avatarView: some View {
        if let avatar = avatar {
            return AnyView(Image(platformImage: avatar).resizable().scaledToFill().frame(width: 100, height: 100))
        } else {
            return AnyView(Circle().fill(Color.primary.opacity(0.2)).frame(width: 100, height: 100))
        }
    }
    
    var body: some View {
        VStack {
            avatarView.clipShape(Circle()).shadow(radius: 4)
            Text(user.details.description).foregroundColor(.primary).lineLimit(1).font(.callout)
            HStack(spacing: 2) {
                if user.settings.pluralKitIntegration != nil {
                    Image(systemName: "person.3.sequence.fill").accessibilityLabel("PluralKit Integration")
                }
                Text(user.settings.contact?.displayName ?? "").lineLimit(1).accessibilityHidden(user.settings.contact == nil)
            }.foregroundColor(.secondary).font(.caption)
        }
    }
}

struct UsersView: View {
    @State var userSettings = UserDatabase.default.readUsers()
    
    @State var avatars = [String: UIImage]()
    @MainActor func setAvatar(for id: String, to image: UIImage) {
        avatars[id] = image
    }
    
    var body: some View {
        ScrollView {
            LazyVStack {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), alignment: .top)], spacing: 16) {
                    ForEach(Array(userSettings).sorted(by: { $0.value.details.description.localizedCaseInsensitiveCompare($1.value.details.description) == .orderedAscending }), id: \.key) { user in
                        NavigationLink(destination: UserSettingsView(userID: user.key, user: $userSettings[user.key])) {
                            UserButton(user: user.value, avatar: avatars[user.key])
                        }.onChange(of: userSettings[user.key]!) { settings in
                            UserDatabase.default.writeSettings(settings, for: user.key)
                        }.onAppear {
                            Task.detached {
                                if let avatar = user.value.details.avatar_id, await avatars[user.key] == nil {
                                    if let data = AvatarCache.default?.getAvatarData(userID: user.key, avatarID: avatar), let image = getImage(data: data) {
                                        await setAvatar(for: user.key, to: image)
                                    }
                                }
                            }
                        }
                    }
                }.padding()
            }
        }.refreshable {
            userSettings = UserDatabase.default.readUsers()
        }
        .navigationBarTitle("Users")
    }
}

struct ContentView: View {
    @ObservedObject var context = Context.shared
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Users") {
                    UsersView()
                }
                Button("Copy APNS Token") {
                    UIPasteboard.general.string = context.token!.base64EncodedString()
                }.disabled(context.token == nil)
            }.navigationTitle(Text("Discord Bridge"))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
