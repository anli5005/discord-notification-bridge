//
//  UserSettings.swift
//  Discord Notification Bridge
//
//  Created by Anthony Li on 12/25/21.
//

import Foundation

let groupName = "group.dev.anli.ios.dnb"
let defaultsKey = "dnbUserSettings"

/// Yes
enum Yes: Codable, Equatable {
    /// Yes
    case yes
}

enum NameStyle: Codable, Hashable {
    case username
    case custom(name: String)
    case nickname
    case pluralKitFronters
    case pluralKitSystem
}

enum AvatarStyle: Codable, Hashable {
    case serverAvatar
    case avatar
    case pluralKitAvatar
    case pluralKitSystemAvatar
}

struct PluralKitSettings: Codable, Equatable {
    
}

extension Array where Element == NameStyle {
    static let `default` = [NameStyle.nickname, .username]
}

extension Array where Element == AvatarStyle {
    static let `default` = [AvatarStyle.serverAvatar, .avatar]
}

struct Contact: Codable, Equatable {
    var identifier: String
    var displayName: String?
}

struct UserSettings: Codable, Equatable {
    var nameStyles: [NameStyle] = .default
    var avatarStyles: [AvatarStyle] = .default
    var pluralKitIntegration: PluralKitSettings?
    var showDiscriminator: Yes?
    var contact: Contact?
}

struct UserDetails: Codable, Equatable {
    var username: String
    var discriminator: String
    var public_flags: Int
}

struct User: Codable, Equatable {
    var details: UserDetails
    var settings: UserSettings
}

func readSettings() -> [String: User] {
    let decoder = PropertyListDecoder()
    if let dict = UserDefaults(suiteName: groupName)?.dictionary(forKey: defaultsKey) as? [String: Data] {
        return dict.compactMapValues { data in try? decoder.decode(User.self, from: data) }
    }
    
    return [:]
}

func writeSettings(_ settings: [String: User]) {
    guard let defaults = UserDefaults(suiteName: groupName) else {
        return
    }
    
    let encoder = PropertyListEncoder()
    var newSettings = settings
    newSettings.merge(readSettings(), uniquingKeysWith: { current, _ in current })
    defaults.set(newSettings.compactMapValues { try? encoder.encode($0) }, forKey: defaultsKey)
}

extension UserDetails: CustomStringConvertible {
    var description: String {
        "\(username)#\(discriminator)"
    }
}
