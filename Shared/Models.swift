//
//  Models.swift
//  Discord Notification Bridge
//
//  Created by Anthony Li on 12/26/21.
//

import Foundation

struct Author: Decodable {
    var username: String
    var id: String
    var discriminator: String
    var avatar: String?
    var public_flags: Int?
    var bot: Bool?
}

struct Member: Decodable {
    var avatar: String?
    var nick: String?
}

struct Attachment: Decodable {
    var id: String
    var width: Int?
    var height: Int?
    var proxy_url: String
    var content_type: String?
}

struct Message: Decodable {
    var id: String
    var tts: Bool
    var mentions: [Author]
    var channel_id: String
    var author: Author
    var member: Member?
    var content: String
    var guild_id: String?
    var attachments: [Attachment]
    var guild_name: String?
    var channel_name: String?
    var pk: Bool?
    
    var subtitle: String? {
        if let guild = guild_name {
            if let channel = channel_name {
                return "\(guild) - \(channel)"
            } else {
                return guild
            }
        }
        
        return channel_name
    }
}
