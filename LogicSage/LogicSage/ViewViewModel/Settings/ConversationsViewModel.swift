//
//  ConversationsViewModel.swift
//  LogicSage
//
//  Created by Chris Dillard on 5/24/23.
//

import Foundation

struct Message {
    var id: String
    var role: Chat.Role
    var content: String
    var createdAt: Date
    var culled: Bool?
    var invisible: Bool?

    var isLocal: Bool?
    var isRunStep: Bool?
}

enum ConvoMode: Equatable, Codable, Hashable {
    case chat
    case assistant
}

extension Message: Equatable, Codable, Hashable, Identifiable {}

struct Conversation {
    init(id: String, messages: [Message] = [], model: String? = nil, temperature: Double? = nil, mode: ConvoMode = .chat, assId: String? = nil, assName: String? = nil) {
        self.id = id
        self.messages = messages
        self.model = model
        self.temperature = temperature
        self.mode = mode
        self.assId = assId
        self.assName = assName
    }

    typealias ID = String
    
    let id: String
    var messages: [Message]
    
    //Everything from this point for must be OPtional so we retain compat with early LogicSage versions.
    var name: String?
    var model: String?
    var systemPrompt: String?
    var tokens: Int?
    var hasAddedToolPrompt: Bool?
    var temperature: Double?
    var mode: ConvoMode?
    var assId: String?
    var threadId: String?
    var assName: String?
}

extension Conversation: Equatable, Codable, Hashable, Identifiable {}
