//
//  ChatView.swift
//  LogicSage
//
//  Created by Chris Dillard on 5/23/23.
//

import Foundation
import SwiftUI
import Combine

struct ChatView: View {
    @ObservedObject var sageMultiViewModel: SageMultiViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel

    @Binding var isEditing: Bool
    @State var isLockToBottom: Bool = true

    @ObservedObject var windowManager: WindowManager

    @State var chatText = "" {
        didSet {

        }
    }
    @State var textEditorHeight : CGFloat = 86
    @State var editingSystemPrompt: Bool = false

    @Environment(\.dateProviderValue) var dateProvider
    @Environment(\.idProviderValue) var idProvider

    @Binding var isMoveGestureActive: Bool
    @Binding var isResizeGestureActive: Bool

    @Binding var keyboardHeight: CGFloat

    @Binding var frame: CGRect
    @Binding var position: CGSize
    @Binding var resizeOffset: CGSize
    @State private var lastDragLocation: CGFloat = 0
    @State private var isDraggedDown: Bool = false
    @State private var showCheckmark: Bool = false

    @State private var choseBuiltInPrompt: String = ""
    @State private var choseBuiltInModel: String = ""

    @FocusState var inFocus
    @Binding var focused: Bool
    @State private var isLoading = false

    @State private var currentRunId: String?
    @State private var currentThreadId: String?
    @State private var currentConversationId: String?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                let usableKeyboardHeight = sageMultiViewModel.frame.height > keyboardHeight ? (inFocus ? keyboardHeight : 0) : 0

#if !os(tvOS)
                SourceCodeTextEditor(text: $sageMultiViewModel.sourceCode, isEditing: $isEditing, isLockToBottom: $isLockToBottom, customization:
                                        SourceCodeTextEditor.Customization(didChangeText:
                                                                            { srcCodeTextEditor in
                    // do nothing
                }, insertionPointColor: {
#if !os(macOS)
                    Colorv(cgColor: settingsViewModel.buttonColor.cgColor!)
#else
                    Colorv(.darkGreen)
#endif
                }, lexerForSource: { lexer in
                    SwiftLexer()
                }, textViewDidBeginEditing: { srcEditor in
                    // do nothing
                }, theme: {
                    ChatSourceCodeTheme(settingsViewModel: settingsViewModel)
                }, overrideText:  {
                    return sageMultiViewModel.getConvoText()
                }, codeDidCopy: {
                    onCopy()
                }, windowType: {.chat }), isMoveGestureActive: $isMoveGestureActive, isResizeGestureActive: $isResizeGestureActive)
                .onAppear {
                    if let convoId = sageMultiViewModel.windowInfo.convoId {

                        if convoId == Conversation.ID(-1) {
                            Timer.scheduledTimer(withTimeInterval: settingsViewModel.chatUpdateInterval, repeats: true) { _ in
                                DispatchQueue.global(qos: .background).async {
                                    let convo = settingsViewModel.getConvo(convoId)
                                    DispatchQueue.main.async {
                                        sageMultiViewModel.conversation = convo ?? Conversation(id:"-1")
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(height: max(geometry.size.height/2,geometry.size.height - textEditorHeight - 30 - usableKeyboardHeight))

#endif
#if !os(tvOS)

                messgeEntry(size: geometry.size)
                    .padding(.trailing, focused ? 0 : settingsViewModel.cornerHandleSize)
                    .padding(.bottom,4)
                    .frame(height: textEditorHeight + 30)
                    .background(settingsViewModel.backgroundColorSrcEditor)
#endif
            }
            .overlay(CheckmarkView(text: "Copied", isVisible: $showCheckmark))
            .clipShape(RoundedBottomCorners(cornerRadius: 16))
        }
    }
#if !os(tvOS)

    func messgeEntry(size: CGSize) -> some View {
        HStack(spacing: 0) {
            GeometryReader { innerReader in

                ZStack(alignment: .leading) {

                    Text(chatText)
                        .font(.system(size: settingsViewModel.fontSizeSrcEditor))
                        .foregroundColor(.clear)
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewHeightKey.self,
                                                   value: $0.frame(in: .local).size.height)
                        })

                    TextEditor(text: $chatText)
                        .lineLimit(nil)
                        .font(.system(size: settingsViewModel.fontSizeSrcEditor))
                        .foregroundColor(settingsViewModel.plainColorSrcEditor)
                        .scrollContentBackground(.hidden)
                        .background(settingsViewModel.backgroundColorSrcEditor)
                        .frame(height: max( 40, textEditorHeight))
#if !os(macOS)
                        .autocorrectionDisabled(!settingsViewModel.autoCorrect)
#endif
#if !os(macOS)
                        .autocapitalization(.none)
#endif
#if !os(visionOS)
                        .scrollDismissesKeyboard(.interactively)
#endif
                        .lineLimit(20, reservesSpace: true)
                        .focused($inFocus)
                        .onChange(of: inFocus) { newValue in
                            focused = inFocus
                        }

                    Text(editingSystemPrompt ? "Set system msg" : "Send a \(sageMultiViewModel.windowInfo.convoId == Conversation.ID(-1) ? "cmd" : "message")")
                        .opacity(chatText.isEmpty && !inFocus ? 1.0 : 0.0 )
                        .padding(.leading,4)
                        .font(.system(size: settingsViewModel.fontSizeSrcEditor + 2))
                        .foregroundColor(settingsViewModel.plainColorSrcEditor)
                        .allowsHitTesting(false)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.secondary, lineWidth: 2)
                )
                //.border(.secondary)
                .cornerRadius(8)
                .onPreferenceChange(ViewHeightKey.self) { textEditorHeight = $0 }
                .padding(.bottom, 0)
                .gesture(
                    DragGesture(minimumDistance: 5, coordinateSpace: .local)
                        .onChanged { value in
                            if value.startLocation.y < value.location.y {
                                isDraggedDown = true
                            } else {
                                isDraggedDown = false
                            }
                            lastDragLocation = value.location.y
                        }
                        .onEnded { value in

                            isDraggedDown = false
                        }
                )
                .onChange(of: isDraggedDown) { isDraggedDown in
#if !os(macOS)
                    hideKeyboard()
#endif
                }
            }

            ChatBottomMenu(settingsViewModel: settingsViewModel, chatText: $chatText, windowManager: windowManager, windowInfo: $sageMultiViewModel.windowInfo, editingSystemPrompt: $editingSystemPrompt, choseBuiltInSystemPrompt: $choseBuiltInPrompt, choseBuiltInModel: $choseBuiltInModel, conversation: $sageMultiViewModel.conversation)
                .onChange(of: choseBuiltInPrompt) { value in

                    logD("EDIT SYSTEM PROMPT TO \(choseBuiltInPrompt)")
                    if let convoId = sageMultiViewModel.windowInfo.convoId {

                        settingsViewModel.setConvoSystemMessage(convoId, newMessage: choseBuiltInPrompt)

                    }
                    editingSystemPrompt = false

                    // UPDATE CHAT WHEN SETING built in prompt
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let convoId = sageMultiViewModel.windowInfo.convoId {

                            let convo = settingsViewModel.getConvo(convoId)
                            DispatchQueue.main.async {
                                sageMultiViewModel.conversation = convo ?? Conversation(id:"-1")
                            }
                        }

                    }
                }
                .onChange(of: choseBuiltInModel) { value in
                    // UPDATE CHAT WHEN SETING built in model
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let convoId = sageMultiViewModel.windowInfo.convoId {

                            var convo = settingsViewModel.getConvo(convoId)
                            convo?.model = choseBuiltInModel
                            DispatchQueue.main.async {
                                sageMultiViewModel.conversation = convo ?? Conversation(id:"-1")
                            }
                        }

                    }
                }
                .foregroundColor(SettingsViewModel.shared.buttonColor)

                .padding(.leading,8)
                .padding(.trailing,8)
#if !os(macOS)
                .hoverEffect(.automatic)
#endif

            if isLoading {
                ProgressView()
            } else {

                Button(action: {
                    doChat()
                }) {
                    resizableButtonImage(systemName:
                                            "paperplane.fill",
                                         size: size)
                    .foregroundColor(SettingsViewModel.shared.buttonColor)

                    .modifier(CustomFontSize(size: $settingsViewModel.commandButtonFontSize))
                    .background(Color.clear)

                }
                .disabled(chatText.isEmpty)
#if os(visionOS)
                .padding(.trailing,20)
#endif
#if !os(macOS)
                .hoverEffect(.automatic)
#endif
            }
        }
    }
#endif

    private func resizableButtonImage(systemName: String, size: CGSize) -> some View {
#if os(macOS) || os(tvOS)
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(width:  min(60.0, size.width * 0.5 * settingsViewModel.buttonScale), height: 100 * settingsViewModel.buttonScale)

#else
        return Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(width: min(60.0, size.width * 0.5 * settingsViewModel.buttonScale), height: 100 * settingsViewModel.buttonScale)
            .tint(settingsViewModel.appTextColor)

#endif
    }
    func doChat() {
        if chatText.isEmpty {
            logD("nothing to exec.")
            return
        }
#if !os(macOS)
        hideKeyboard()
#endif

        if editingSystemPrompt {
            logD("EDIT SYSTEM PROMPT TO ")
            if let convoId = sageMultiViewModel.windowInfo.convoId {

                settingsViewModel.setConvoSystemMessage(convoId, newMessage: chatText)

            }
            editingSystemPrompt = false
            chatText = ""
        }
        else {
            if let convoID = sageMultiViewModel.windowInfo.convoId {
                if convoID == Conversation.ID(-1) {
                    screamer.sendCommand(command: chatText)
                }
                else {
                    if sageMultiViewModel.conversation.mode == .assistant {
                        // if assistant and do chat either start thread and or add message to assistant
                        if sageMultiViewModel.conversation.messages.isEmpty {

                            SettingsViewModel.shared.appendMessageToConvoId(sageMultiViewModel.conversation.id,
                                                                            message: Message(id: UUID().uuidString, role: .user, content: chatText, createdAt: Date(), isLocal: true))

                            if let threadId = sageMultiViewModel.conversation.threadId {
                                print("Now lets do a run of thread")

                                let runsQuery = RunsQuery(assistantId: sageMultiViewModel.conversation.assId ?? "")
                                GPT.shared.openAINonBg.runs(threadId: threadId, query: runsQuery) { result in
                                    switch result {
                                    case .success(let result):
                                        print("Successfully started thread run \(result.id).. start polling")
                                        isLoading = true

                                        startPolling(threadId: threadId, runId: result.id)
                                    case .failure(let error):
                                        print("FAILED TO START thread run. error = \(error)")
                                    }
                                }
                            }
                            else {
                                GPT.shared.createThread(messages: [Chat(role: .user, content: chatText)]) { resultId in

                                    if let threadId = resultId {
                                        print("successfully created THREAD = \(threadId)")

                                        print("Now lets do a run of thread")

                                        let runsQuery = RunsQuery(assistantId: sageMultiViewModel.conversation.assId ?? "")
                                        GPT.shared.openAINonBg.runs(threadId: threadId, query: runsQuery) { result in
                                            switch result {
                                            case .success(let result):
                                                print("Successfully started thread run \(result.id).. start polling")
                                                isLoading = true

                                                startPolling(threadId: threadId, runId: result.id)
                                            case .failure(let error):
                                                print("FAILED TO START thread run. error = \(error)")
                                            }
                                        }
                                    }
                                    else {
                                        // FUCKING FAILURE
                                        print("FAILED TO Create THREAD")
                                    }
                                }
                            }
                        }
                        else {
                            // Send msg to thread
                            // TODO: HANDLE ADDING MESSAGES TO ALREADY CREATED THREAD
                            print("Send msg to already created thread....")
                            if let threadId = sageMultiViewModel.conversation.threadId {
                                currentThreadId = threadId
                            }
                            SettingsViewModel.shared.appendMessageToConvoId(sageMultiViewModel.conversation.id,
                                                                            message: Message(id: UUID().uuidString, role: .user, content: chatText, createdAt: Date(), isLocal: true))

                            guard let currentThreadId else { return print("No thread to add message to.")}

                            GPT.shared.openAINonBg.threadsAddMessage(threadId: currentThreadId, query: ThreadAddMessageQuery(role: "user", content: chatText)) { result in

                                switch result {
                                case .success(_):

                                    guard let currentAssistantId = sageMultiViewModel.conversation.assId else { return print("No assistant selected.")}

                                    let runsQuery = RunsQuery(assistantId: currentAssistantId)

                                    GPT.shared.openAINonBg.runs(threadId: currentThreadId, query: runsQuery) { result in
                                        switch result {
                                        case .success(let result):
                                            print("Successfully started thread run \(result.id).. start polling")
                                            isLoading = true

                                            startPolling(threadId: currentThreadId, runId: result.id)
                                        case .failure(let error):
                                            print("FAILED TO START thread run. error = \(error)")
                                        }
                                    }
                                    break
                                case .failure(let error):

                                    print("error: \(error) adding to thread w/ message")

                                    break
                                }
                            }

                        }
                    }
                    else {
                        settingsViewModel.sendChatText(convoID, chatText: chatText)
                    }
                }
                chatText = ""
            }
            else {
                logD("failed to chat")
            }
        }
    }

    func startPolling(threadId: String, runId: String) {
        currentRunId = runId
        currentThreadId = threadId

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {

            GPT.shared.openAINonBg.runRetrieve(threadId: threadId, runId: runId) { retResult in

                // TESTING RETRIEVAL OF RUN STEPS
                handleRunRetrieveSteps()


                switch retResult {
                case .success(let result):
                    print(result.status)
                    if result.status == "completed" {
                        handleCompleted(threadId: threadId)
                    }
                    else if result.status == "failed" {
                        isLoading = false
                    }
                    else {
                        isLoading = true
                        startPolling(threadId: threadId, runId: runId)
                    }
                    break
                case .failure(let error):
                    print(error.localizedDescription)

                    break
                }
            }
        }
    }

    private func handleCompleted(threadId: String) {
        print("RUN COMPLETED - get messages")

        var before: String?
        if let lastNonLocalMessage = sageMultiViewModel.conversation.messages.last(where: { $0.isLocal == false }) {
            before = lastNonLocalMessage.id
        }

        GPT.shared.openAINonBg.threadsMessages(threadId: threadId, before: before) { result in
            switch result {
            case .success(let threadMessageResult):
                print("GOT THREADS MESSAGES = \(threadMessageResult)")

                for item in threadMessageResult.data.reversed() {
                    let role = item.role
                    for innerItem in item.content {

                        let msg = Message(id: item.id, 
                                          role: Chat.Role(rawValue: role) ?? .user,
                                          content: innerItem.text?.value ?? "",
                                          createdAt: Date(), isLocal: false)

                        if let localMessageIndex = sageMultiViewModel.conversation.messages.firstIndex(where: { $0.isLocal == true }) {
                            SettingsViewModel.shared.setMessageWithConvoId(sageMultiViewModel.conversation.id,
                                                                           localMessageIndex: localMessageIndex,
                                                                           message: msg)

                        }
                        else {

                            SettingsViewModel.shared.appendMessageToConvoId(sageMultiViewModel.conversation.id,
                                                                            message: msg)
                            playSoftImpact()

                            SettingsViewModel.shared.speak(msg.content)

                        }

                    }
                }
                SettingsViewModel.shared.setThreadIdWithConvoId(sageMultiViewModel.conversation.id,
                                                                threadId: threadId)

            case .failure(let error):
                print("ERROR GETTING MESSAGES = \(error.localizedDescription)")

            }
            isLoading = false

        }
    }

    // The run retrieval steps are fetched in a separate task. This request is fetched, checking for new run steps, each time the run is fetched.
    private func handleRunRetrieveSteps() {
        Task {
//            guard let conversationIndex = conversations.firstIndex(where: { $0.id == currentConversationId }) else {
//                return
//            }
            var before: String?
//            if let lastRunStepMessage = self.conversations[conversationIndex].messages.last(where: { $0.isRunStep == true }) {
//                before = lastRunStepMessage.id
//            }

            let stepsResult = try await GPT.shared.openAINonBg.runRetrieveSteps(threadId: currentThreadId ?? "", runId: currentRunId ?? "", before: before)

            for item in stepsResult.data.reversed() {
                let toolCalls = item.stepDetails.toolCalls?.reversed() ?? []

                for step in toolCalls {
                    // TODO: Depending on the type of tool tha is used we can add additional information here
                    // ie: if its a retrieval: add file information, code_interpreter: add inputs and outputs info, or function: add arguemts and additional info.
                    let msgContent: String
                    switch step.type {
                    case "retrieval":
                        msgContent = "RUN STEP: \(step.type)"

                    case "code_interpreter":
                        msgContent = "code_interpreter\ninput:\n\(step.code?.input ?? "")\noutputs: \(step.code?.outputs?.first?.logs ?? "")"

                    default:
                        msgContent = "RUN STEP: \(step.type)"

                    }
                    let runStepMessage = Message(
                        id: step.id,
                        role: .assistant,
                        content: msgContent,
                        createdAt: Date(),
                        isRunStep: true
                    )
                    await MainActor.run {
                        if let localMessageIndex = sageMultiViewModel.conversation.messages.firstIndex(where: { $0.isRunStep == true && $0.id == step.id }) {
                           // self.conversations[conversationIndex].messages[localMessageIndex] = runStepMessage
                            SettingsViewModel.shared.setMessageWithConvoId(sageMultiViewModel.conversation.id,
                                                                           localMessageIndex: localMessageIndex,
                                                                           message: runStepMessage)

                        }
                        else {
                            //self.conversations[conversationIndex].messages.append(runStepMessage)

                            SettingsViewModel.shared.appendMessageToConvoId(sageMultiViewModel.conversation.id,
                                                                            message: runStepMessage)
                            playSoftImpact()
                        }
                    }
                }
            }
        }
    }



    // UI Bullshit

    func setLockToBottom() {
        isLockToBottom.toggle()
        if gestureDebugLogs {
            print("setting isLockToBottom to \(isLockToBottom)")
        }
    }
    private func onCopy() {
        withAnimation(Animation.easeInOut(duration: 0.666)) {
            showCheckmark = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.666) {
            withAnimation(Animation.easeInOut(duration: 0.6666)) {
                showCheckmark = false
            }
        }
    }
    struct ViewHeightKey: PreferenceKey {
        static var defaultValue: CGFloat { 0 }
        static func reduce(value: inout Value, nextValue: () -> Value) {
            value = value + nextValue()
        }
    }
    struct DemoStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(alignment: .center) {
                configuration.icon
                configuration.title
            }
        }
    }

}
