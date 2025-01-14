//
//  SageMultiViewModel.swift
//  LogicSage
//
//  Created by Chris Dillard on 5/9/23.
//

import Foundation
import SwiftUI

private var lastConsoleUpdate = Date()
class SageMultiViewModel: ObservableObject, Identifiable {
    let id = UUID()
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var windowManager: WindowManager

    @Published var windowId: UUID

    @Published var sourceCode: String
    @Published var changes: [ChangeRow] = []

    var originalSourceCode: String
    @Published var windowInfo: WindowInfo
    @Published var position: CGSize = .zero
    @Published var viewSize: CGRect = .zero
    @Published var resizeOffset: CGSize = .zero
    @Published var frame: CGRect
    @Published var conversation: Conversation

    static func convoText(_ settingsViewModel: SettingsViewModel, _ conversation: Conversation?, windowInfo: WindowInfo) -> String {
        if windowInfo.convoId == Conversation.ID(-1) {
            return settingsViewModel.consoleManagerText
        }
        else if let conversation {
            return settingsViewModel.convoText(conversation)
        }
        else {
            return windowInfo.fileContents
        }
    }

    init(settingsViewModel: SettingsViewModel, windowId: UUID, windowManager: WindowManager, windowInfo: WindowInfo, frame: CGRect, conversation: Conversation?) {
        self.settingsViewModel = settingsViewModel
        self.windowId = windowId
        self.windowManager = windowManager
        self.windowInfo = windowInfo

        self.sourceCode =  SageMultiViewModel.convoText(settingsViewModel, conversation, windowInfo: windowInfo)

        self.originalSourceCode = windowInfo.fileContents
        self.frame = frame

        self.conversation = conversation ?? Conversation(id: "-1")

    }

    func refreshChanges(newText: String) {
        DispatchQueue.global(qos: .default).async {
            let calcChange = getLineChanges(original: self.originalSourceCode, edited: newText)
           DispatchQueue.main.async {
                self.changes = calcChange
           }
        }
    }

    func getConvoText() -> String {
        SageMultiViewModel.convoText(settingsViewModel, conversation, windowInfo: windowInfo)
    }

    func saveFileToDisk() {
        let newCode = sourceCode
        windowInfo.fileContents = newCode
        if let url = windowInfo.file?.url {
            do {
                try newCode.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            }
            catch {
                print("error writing file= \(error)")
            }
        }

    }
}


