//
//  UserSettings.swift
//  Discord Notification Bridge
//
//  Created by Anthony Li on 12/25/21.
//

import Foundation
import SQLite

let groupName = "group.dev.anli.ios.dnb"
let databaseName = "users.db"

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

class AvatarCache {
    let db: Connection
    
    let avatars = Table("avatars")
    let userID = Expression<String>("user_id")
    let avatarID = Expression<String>("avatar_id")
    let data = Expression<Data>("data")
    let date = Expression<Date>("date")
    
    init(db: Connection) throws {
        self.db = db
        try db.run(avatars.create(ifNotExists: true) { t in
            t.column(userID)
            t.column(avatarID)
            t.column(data)
            t.column(date)
            t.primaryKey(userID, avatarID)
        })
    }
    
    private func getQuery(userID: String, avatarID: String) -> some SchemaType {
        avatars.filter(self.userID == userID).filter(self.avatarID == avatarID)
    }
    
    func getAvatarData(userID: String, avatarID: String) -> Data? {
        if let row = try? db.pluck(getQuery(userID: userID, avatarID: avatarID).select(data)) {
            return try? row.get(data)
        } else {
            return nil
        }
    }
    
    func getAvatarData(userID: String, avatarID: String) -> Date? {
        if let row = try? db.pluck(getQuery(userID: userID, avatarID: avatarID).select(date)) {
            return try? row.get(date)
        } else {
            return nil
        }
    }
    
    func cacheAvatar(_ data: Data, userID: String, avatarID: String, date: Date) {
        let query = getQuery(userID: userID, avatarID: avatarID)
        do {
            if try db.pluck(query.select(self.userID)) != nil {
                try db.run(query.update(self.data <- data, self.date <- date))
            } else {
                try db.run(avatars.insert(self.userID <- userID, self.avatarID <- avatarID, self.data <- data, self.date <- date))
            }
        } catch {}
    }
    
    static let `default`: AvatarCache? = {
        guard let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName) else {
            return nil
        }
        return try? AvatarCache(db: Connection(directory.appendingPathComponent("Library").appendingPathComponent("Caches").appendingPathComponent("avatars.db").path))
    }()
}

class UserDatabase {
    let db: Connection
    
    let users = Table("users")
    let id = Expression<String>("id")
    let data = Expression<Data>("data")
    
    init(db: Connection) throws {
        self.db = db
        try db.run(users.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(data)
        })
    }
    
    func readSettings(for userID: String) -> User? {
        if let row = try? db.pluck(users.filter(id == userID)) {
            let decoder = JSONDecoder()
            return try? decoder.decode(User.self, from: row.get(data))
        } else {
            return nil
        }
    }
    
    func readUsers() -> [String: User] {
        var dict = [String: User]()
        let decoder = JSONDecoder()
        do {
            for row in try db.prepare(users.select(id, data)) {
                if let id = try? row.get(id), let user = try? decoder.decode(User.self, from: row.get(data)) {
                    dict[id] = user
                }
            }
        } catch {}
        return dict
    }
    
    func writeSettings(_ user: User, for userID: String) {
        let encoder = JSONEncoder()
        _ = try? db.run(users.upsert(id <- userID, data <- encoder.encode(user), onConflictOf: id))
    }
    
    static let `default`: UserDatabase = {
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)!
        return try! UserDatabase(db: Connection(directory.appendingPathComponent(databaseName).path))
    }()
}

extension UserDetails: CustomStringConvertible {
    var description: String {
        "\(username)#\(discriminator)"
    }
}
