//
//  UserView.swift
//  Discord Notification Bridge
//
//  Created by Anthony Li on 12/25/21.
//

import SwiftUI
import ContactsUI

extension NameStyle: CustomStringConvertible {
    var description: String {
        switch self {
        case .username:
            return "Username"
        case .custom(name: _):
            return "Custom"
        case .nickname:
            return "Nickname"
        case .pluralKitFronters:
            return "Fronter(s)"
        case .pluralKitSystem:
            return "System Name"
        }
    }
}

extension AvatarStyle: CustomStringConvertible {
    var description: String {
        switch self {
        case .serverAvatar:
            return "Server Avatar"
        case .avatar:
            return "Avatar"
        case .pluralKitSystemAvatar:
            return "System Avatar"
        case .pluralKitAvatar:
            return "Fronter(s)"
        }
    }
}

extension Binding where Value == Yes? {
    var boolBinding: Binding<Bool> {
        Binding<Bool> {
            wrappedValue == .yes
        } set: { newValue in
            if newValue {
                wrappedValue = .yes
            } else {
                wrappedValue = nil
            }
        }
    }
}

struct UserSettingsView: View {
    var userID: String
    @Binding var user: User?
    @State var showingContactPicker = false
    
    var body: some View {
        guard let user = user else {
            return AnyView(Text("User not found"))
        }
        
        let userBinding: Binding<User> = Binding {
            user
        } set: { newValue in
            self.user = newValue
        }
        
        return AnyView(Form {
            Section("Appearance") {
                NavigationLink {
                    List {
                        Section {
                            ForEach(user.settings.nameStyles, id: \.self) { style in
                                if case .custom(let name) = style {
                                    NavigationLink {
                                        TextField("Custom Name", text: Binding {
                                            name
                                        } set: { newValue in
                                            let index = user.settings.nameStyles.firstIndex(where: { style in
                                                if case .custom(_) = style {
                                                    return true
                                                } else {
                                                    return false
                                                }
                                            })!
                                            self.user!.settings.nameStyles[index] = .custom(name: newValue)
                                        }).navigationBarTitle("Custom")
                                    } label: {
                                        HStack {
                                            Text(style.description)
                                            Spacer()
                                            Text(name).foregroundColor(.secondary)
                                        }
                                    }
                                } else {
                                    Text(style.description)
                                }
                            }.onMove { source, destination in
                                self.user!.settings.nameStyles.move(fromOffsets: source, toOffset: destination)
                            }
                            
                            if !user.settings.nameStyles.contains(where: { style in
                                if case .custom(_) = style {
                                    return true
                                } else {
                                    return false
                                }
                            }) {
                                Button {
                                    self.user!.settings.nameStyles.insert(.custom(name: user.details.username), at: 0)
                                } label: {
                                    Text("Add Custom Name")
                                }
                            }
                        }
                        Section {
                            Toggle("Show Discriminator", isOn: userBinding.settings.showDiscriminator.boolBinding)
                        }
                    }.navigationTitle("Display Name As").toolbar {
                        EditButton()
                    }
                } label: {
                    HStack {
                        Text("Display Name As")
                        Spacer()
                        Text(user.settings.nameStyles.first?.description ?? [NameStyle].default[0].description).foregroundColor(.secondary)
                    }
                }
                NavigationLink {
                    List {
                        ForEach(user.settings.avatarStyles, id: \.self) { style in
                            Text(style.description)
                        }.onMove { source, destination in
                            self.user?.settings.avatarStyles.move(fromOffsets: source, toOffset: destination)
                        }
                    }.navigationTitle("Display Avatar As").toolbar {
                        EditButton()
                    }
                } label: {
                    HStack {
                        Text("Display Avatar As")
                        Spacer()
                        Text(user.settings.avatarStyles.first?.description ?? [AvatarStyle].default[0].description).foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Contacts") {
                if user.settings.contact != nil {
                    HStack {
                        Text("Associated Contact").foregroundColor(.primary)
                        Spacer()
                        if let contact = user.settings.contact {
                            Text(contact.displayName ?? "Selected").foregroundColor(.secondary)
                        }
                    }.lineLimit(1)
                }
                Button {
                    showingContactPicker = true
                } label: {
                    HStack {
                        Text(user.settings.contact != nil ? "Change Associated Contact" : "Add Associated Contact")
                        ContactPicker(isPresented: $showingContactPicker) { contact in
                            let formatter = CNContactFormatter()
                            let name: String?
                            if contact.nickname.isEmpty {
                                name = formatter.string(from: contact)
                            } else {
                                name = contact.nickname
                            }
                            self.user?.settings.contact = Contact(identifier: contact.identifier, displayName: name)
                            showingContactPicker = false
                        }.frame(width: 0, height: 0)
                    }
                }
                if user.settings.contact != nil {
                    Button {
                        self.user!.settings.contact = nil
                    } label: {
                        Text("Remove Associated Contact").foregroundColor(.red)
                    }
                }
            }
            
            Section("PluralKit") {
                Toggle("PluralKit Integration", isOn: Binding {
                    user.settings.pluralKitIntegration != nil
                } set: { newValue in
                    if newValue {
                        if user.settings.pluralKitIntegration == nil {
                            self.user!.settings.pluralKitIntegration = PluralKitSettings()
                        }
                    } else {
                        self.user!.settings.pluralKitIntegration = nil
                    }
                })
            }
        }.navigationTitle(user.details.description).onChange(of: user.settings.pluralKitIntegration != nil, perform: { hasPluralKit in
            if hasPluralKit {
                self.user!.settings.nameStyles.insert(contentsOf: [.pluralKitFronters, .pluralKitSystem].filter { !user.settings.nameStyles.contains($0) }, at: 0)
                self.user!.settings.avatarStyles.insert(contentsOf: [.pluralKitAvatar, .pluralKitSystemAvatar].filter { !user.settings.avatarStyles.contains($0) }, at: 0)
            } else {
                self.user!.settings.nameStyles.removeAll(where: { $0 == .pluralKitFronters || $0 == .pluralKitSystem })
                self.user!.settings.avatarStyles.removeAll(where: { $0 == .pluralKitAvatar || $0 == .pluralKitSystemAvatar })
            }
        }))
    }
}
