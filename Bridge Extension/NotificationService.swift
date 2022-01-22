//
//  NotificationService.swift
//  Bridge Extension
//
//  Created by Anthony Li on 12/25/21.
//

import UserNotifications
import Intents
import UniformTypeIdentifiers

extension NameStyle {
    func getName(for message: Message, with settings: UserSettings, urlSession: URLSession, pluralKitCache: inout PluralKitCache) async -> String? {
        switch self {
        case .username:
            if settings.showDiscriminator != nil {
                return "\(message.author.username)#\(message.author.discriminator)"
            } else {
                return message.author.username
            }
        case .custom(name: let name):
            return name
        case .nickname:
            return message.member?.nick
        case .pluralKitFronters:
            guard let pkSettings = settings.pluralKitIntegration else {
                return nil
            }
            
            do {
                return try await pluralKitCache.getNamesOfFronters(for: message.author.id, with: pkSettings, urlSession: urlSession)
            } catch {
                print(error)
                return nil
            }
        case .pluralKitSystem:
            guard let pkSettings = settings.pluralKitIntegration else {
                return nil
            }
            
            do {
                return try await pluralKitCache.getSystemName(for: message.author.id, with: pkSettings, urlSession: urlSession)
            } catch {
                print(error)
                return nil
            }
        }
    }
}

extension AvatarStyle {
    func getAvatar(for message: Message, with settings: UserSettings, urlSession: URLSession, pluralKitCache: inout PluralKitCache) async -> Data? {
        switch self {
        case .avatar:
            if let url = URL(string: "https://cdn.discordapp.com/avatars/\(message.author.id)/\(message.author.avatar).png"), let (data, _) = try? await urlSession.data(from: url, delegate: nil) {
                return data
            }
            return nil
        case .serverAvatar:
            if let avatar = message.member?.avatar, let url = URL(string: "https://cdn.discordapp.com/avatars/\(message.author.id)/\(avatar).png"), let (data, _) = try? await urlSession.data(from: url, delegate: nil) {
                return data
            }
            return nil
        case .pluralKitAvatar:
            guard let pkSettings = settings.pluralKitIntegration else {
                return nil
            }
            
            do {
                return try await pluralKitCache.getFronterAvatar(for: message.author.id, with: pkSettings, urlSession: urlSession)
            } catch {
                print(error)
                return nil
            }
        case .pluralKitSystemAvatar:
            guard let pkSettings = settings.pluralKitIntegration else {
                return nil
            }
            
            do {
                return try await pluralKitCache.getSystemAvatar(for: message.author.id, with: pkSettings, urlSession: urlSession)
            } catch {
                print(error)
                return nil
            }
        }
    }
}

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    let session: URLSession = {
        let session = URLSession(configuration: .default)
        return session
    }()
    
    func process(message: Message, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) async {
        guard var content = bestAttemptContent else {
            fatalError("process() called without bestAttemptContent")
        }
        
        let details = UserDetails(username: message.author.username, discriminator: message.author.discriminator, public_flags: message.author.public_flags)
        let settings: UserSettings
        if let user = UserDatabase.default.readSettings(for: message.author.id) {
            settings = user.settings
            if user.details != details {
                UserDatabase.default.writeSettings(User(details: details, settings: settings), for: message.author.id)
            }
        } else {
            settings = UserSettings()
            UserDatabase.default.writeSettings(User(details: details, settings: settings), for: message.author.id)
        }
        
        content.threadIdentifier = message.channel_id
        
        var pluralKitCache = PluralKitCache()
        
        let nameStyles = settings.nameStyles + [.username]
        var senderName: String?
        for style in nameStyles {
            senderName = await style.getName(for: message, with: settings, urlSession: session, pluralKitCache: &pluralKitCache)
            if senderName != nil {
                break
            }
        }
        content.title = senderName!
        content.subtitle = message.subtitle ?? ""
        
        var image: INImage?
        let avatarStyles = settings.avatarStyles + [.avatar]
        for style in avatarStyles {
            let data = await style.getAvatar(for: message, with: settings, urlSession: session, pluralKitCache: &pluralKitCache)
            if let data = data {
                image = INImage(imageData: data)
                break
            }
        }
        let person = INPerson(
            personHandle: INPersonHandle(value: message.author.id, type: .unknown),
            nameComponents: nil,
            displayName: senderName!,
            image: image,
            contactIdentifier: settings.contact?.identifier,
            customIdentifier: message.author.id,
            isMe: false,
            suggestionType: .none
        )
        let me = INPerson(personHandle: INPersonHandle(value: "@me", type: .unknown), nameComponents: nil, displayName: nil, image: nil, contactIdentifier: nil, customIdentifier: nil, isMe: true)
        let intent = INSendMessageIntent(recipients: message.subtitle != nil ? [me, person] : nil, outgoingMessageType: .outgoingMessageText, content: message.content, speakableGroupName: message.subtitle.map { INSpeakableString(spokenPhrase: $0) }, conversationIdentifier: message.channel_id, serviceName: "dev.anli.ios.Discord-Notification-Bridge.discord", sender: person, attachments: nil)
        if message.subtitle != nil {
            intent.setImage(image, forParameterNamed: \.speakableGroupName)
        } else {
            intent.setImage(image, forParameterNamed: \.sender)
        }
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        Task {
            try? await interaction.donate()
        }
        
        do {
            if let newContent = try content.updating(from: intent).mutableCopy() as? UNMutableNotificationContent {
                content = newContent
                bestAttemptContent = newContent
            }
        } catch let error {
            print(error)
        }
        
        for attachment in message.attachments {
            guard let type = attachment.content_type else {
                continue
            }
            
            if !type.starts(with: "image/") {
                continue
            }
            
            guard let uti = UTTypeReference(mimeType: type) else {
                continue
            }
            
            if attachment.width == nil {
                continue
            }
            
            if let url = URL(string: attachment.proxy_url), let (attachmentURL, _) = try? await session.download(from: url, delegate: nil) {
                do {
                    try content.attachments.append(UNNotificationAttachment(identifier: attachment.id, url: attachmentURL, options: [UNNotificationAttachmentOptionsTypeHintKey: uti.identifier]))
                    break
                } catch {
                    print(error)
                }
            }
        }
        
        contentHandler(content)
    }

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        let decoder = JSONDecoder()
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            guard let str = request.content.userInfo["data"] as? String else {
                contentHandler(bestAttemptContent)
                return
            }
            
            print(str)
            
            guard let data = str.data(using: .utf8) else {
                contentHandler(bestAttemptContent)
                return
            }
            
            let message: Message
            do {
                message = try decoder.decode(Message.self, from: data)
            } catch {
                print(error)
                contentHandler(bestAttemptContent)
                return
            }
            
            Task {
                await process(message: message, withContentHandler: contentHandler)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
