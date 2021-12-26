//
//  PluralKitIntegration.swift
//  Bridge Extension
//
//  Created by Anthony Li on 12/25/21.
//

import Foundation

struct PluralKitSystem: Decodable {
    var avatar_url: String?
    var name: String?
}

struct PluralKitFronters: Decodable {
    var members: [PluralKitMember]
}

struct PluralKitMember: Decodable {
    var name: String?
    var display_name: String?
    var avatar_url: String?
}

enum PluralKitError: Error {
    case badURL
}

struct PluralKitCache {
    var fronters: PluralKitFronters?
    var system: PluralKitSystem?
    
    mutating func getSystem(for authorID: String, urlSession: URLSession) async throws -> PluralKitSystem {
        if let system = system {
            return system
        }
        
        guard let url = URL(string: "https://api.pluralkit.me/v2/systems/\(authorID)") else {
            throw PluralKitError.badURL
        }
        let (data, _) = try await urlSession.data(from: url)
        system = try JSONDecoder().decode(PluralKitSystem.self, from: data)
        return system!
    }
    
    mutating func getFronters(for authorID: String, urlSession: URLSession) async throws -> PluralKitFronters {
        if let fronters = fronters {
            return fronters
        }
        
        guard let url = URL(string: "https://api.pluralkit.me/v2/systems/\(authorID)/fronters") else {
            throw PluralKitError.badURL
        }
        let (data, _) = try await urlSession.data(from: url)
        fronters = try JSONDecoder().decode(PluralKitFronters.self, from: data)
        return fronters!
    }
    
    mutating func getNamesOfFronters(for authorID: String, with settings: PluralKitSettings, urlSession: URLSession) async throws -> String? {
        let fronters = try await getFronters(for: authorID, urlSession: urlSession)
        let names = fronters.members.compactMap { $0.display_name ?? $0.name }
        if names.isEmpty {
            return nil
        } else {
            return names.joined(separator: ", ")
        }
    }
    
    mutating func getSystemName(for authorID: String, with settings: PluralKitSettings, urlSession: URLSession) async throws -> String? {
        let system = try await getSystem(for: authorID, urlSession: urlSession)
        return system.name
    }
    
    mutating func getFronterAvatar(for authorID: String, with settings: PluralKitSettings, urlSession: URLSession) async throws -> Data? {
        let fronters = try await getFronters(for: authorID, urlSession: urlSession)
        if fronters.members.count == 1 {
            if let url = fronters.members[0].avatar_url.flatMap({ URL(string: $0) }) {
                let response = try? await urlSession.data(from: url)
                return response?.0
            }
        }
        
        return nil
    }
    
    mutating func getSystemAvatar(for authorID: String, with settings: PluralKitSettings, urlSession: URLSession) async throws -> Data? {
        let system = try await getSystem(for: authorID, urlSession: urlSession)
        if let url = system.avatar_url.flatMap({ URL(string: $0) }) {
            let response = try? await urlSession.data(from: url)
            return response?.0
        }
        
        return nil
    }
}
