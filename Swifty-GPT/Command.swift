//
//  Command.swift
//  Swifty-GPT
//
//  Created by Chris Dillard on 4/15/23.
//

import Foundation
import Foundation
import AVFoundation
import os.log
import AVFoundation
import CoreMedia

var commandTable: [String: (String) -> Void] = [
    "0": zeroCommand,
    "gpt:": gptCommand,
    "xcode:": xcodeCommand,
    "idea:": ideaCommand,
    "1": runAppDesc,
    "2": showLoadedPrompt,
    "3": openProjectCommand,
    "4": closeCommand,
    "5": fixItCommand,
    "6": openProjectCommand,
    // "7": blarg,

    "gptVoice:": gptVoiceCommand, // Make gpt reply w/ a specific voice
    "google:": googleCommand,
    "image:": imageCommand,

    "exit": exitCommand,
    "stop": stopCommand,
    "random": randomCommand,
    "prompts": promptsCommand,
    "sing": singCommand,
    "reset": resetCommand,
    "commands": commandsCommand,
    "b": buildCommand,
    "delete": deleteCommand,
    "encourage":encourageCommand,


    "link:":linkCommand
]

var presentMode = true

func resetCommand(input: String) {
    projectName = "MyApp"
    globalErrors = [String]()
    manualPromptString = ""
    blockingInput = false

    lastFileContents = [String]()
    lastNameContents = [String]()
    searchResultHeadingGlobal = nil

    appName = "MyApp"
    appType = "iOS"

    appDesc = builtInAppDesc
    language = "Swift"

    print("🔁🔄♻️ Reset.")


}

func deleteCommand(input: String) {
    print("backing up and deleting SwiftSage workspace, as requested")

    do {
        try backupAndDeleteWorkspace()
    }
    catch {
        print("file error = \(error)")
    }
}

func singCommand(input: String) {
    textToSpeech(text: "A.I. is our guide, through the data waves we ride, A.I. and my dream team side by side!\n Oh... with A.I.'s grace... we'll win the race and earn our clients' embrace!", overrideVoice: "Good news", overrideWpm: "224")
}

func promptsCommand(input: String) {
    PromptLibrary.promptLib.forEach {
        print($0)
    }
}

func randomCommand(input: String) {
    guard let prompt = PromptLibrary.promptLib.randomElement() else {
        return print("fail prompt")
    }
    appDesc = prompt
    refreshPrompt(appDesc: appDesc)

    doPrompting()
}

func stopCommand(input: String) {
    killAllVoices()
    stopRandomSpinner()
}

func ideaCommand(input: String) {

    let newPrompt = createIdeaPrompt(command: input)

    doPrompting(overridePrompt: newPrompt)
}

func zeroCommand(input: String) {
    // start voice capture
    if audioRecorder?.isRunning == false {
        print("Start voice capturer")
        textToSpeech(text: "Listening...")

        audioRecorder?.startRecording()
    } else if audioRecorder?.isRunning == true {
        print("Stop voice capturer")

        audioRecorder?.stopRecording() { success in
            guard success else {
                textToSpeech(text: "Failed to capture.")
                return
            }
            textToSpeech(text: "Captured.")

            guard let path = audioRecorder?.outputFileURL else { return print("failed to transcribe") }

            Task {
                await doTranscription(on: path)
            }
        }
    }
}

func gptCommand(input: String) {
    manualPromptString = input
    sendPromptToGPT(prompt: manualPromptString, currentRetry: 0) { content, success in
        if !success {
            textToSpeech(text: "A.P.I. error, try again.", overrideWpm: "242")
            return
        }

        print("\n🤖: \(content)")

        textToSpeech(text: content)

        refreshPrompt(appDesc: appDesc)

        print(generatedOpenLine())
        openLinePrintCount += 1
    }
}

// TODO:
func xcodeCommand(input: String) {

    print("Xcode commands could be used for all sorts of things")
    print("but for now, not implemented.")

    //    let command = String(input.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
    // runXcodeCommand(command: command)
}

func exitCommand(input: String) {
    sema.signal()
}

func closeCommand(input: String) {
    executeAppleScriptCommand(.closeProject(name: projectName)) { sucess, error in

    }
}

func fixItCommand(input: String) {
    let newPrompt = createFixItPrompt(errors: globalErrors, currentRetry: 0)


    // To create you must destroy
//    // Hmm?
//    do {
//        try backupAndDeleteWorkspace()
//    }
//    catch {
//        print("file error = \(error)")
//    }
    
    doPrompting(globalErrors, overridePrompt: newPrompt)
}

func runAppDesc(input: String) {
    doPrompting()
}

func showLoadedPrompt(input: String) {
    print("\n \(prompt) \n")

    refreshPrompt(appDesc: appDesc)
    print(openingLine)
}

func openProjectCommand(input: String) {
    executeAppleScriptCommand(.openProject(name: projectName)) { success, error in }
    refreshPrompt(appDesc: appDesc)
    print(generatedOpenLine())
    openLinePrintCount += 1
}

func googleCommand(input: String) {
    searchIt(query: input) { innerContent in
        if let innerContent = innerContent {

            print("\n🤖 googled \(input): \(innerContent)")

            // if overridePrompt is set by the googleCommand.. the next prompt will need to be auto send on this prompts completion.
            searchResultHeadingGlobal = "\(promptText())\n\(searchResultHeading)\n\(innerContent)"

            if let results = searchResultHeadingGlobal {
                print("give 🤖 search results")

                doPrompting(overridePrompt: results)
                return
            }
            else {
                print("FAILED to give results")
            }
        }
        else {
            print("failed to get search results.")
        }
    }
}

func imageCommand(input: String) {
    print("not implemented")

}

// pass --voice at the end of your prompt to customize the reply voice.
func gptVoiceCommand(input: String) {

    //extract voice and prompt
    let comps = input.components(separatedBy: "--voice ")
    if comps.count > 1 {
        let promper = comps[0]

        let gptVoiceCommandOverrideVoice = comps[1].replacingOccurrences(of: "--voice ", with: "")

        manualPromptString = promper
        sendPromptToGPT(prompt: manualPromptString, currentRetry: 0) { content, success in
            if !success {
                textToSpeech(text: "A.P.I. error, try again.", overrideWpm: "242")
                return
            }

            print("\n🤖: \(content)")
            let modContent = content.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: validCharacterSet.inverted)
            textToSpeech(text: modContent, overrideVoice: gptVoiceCommandOverrideVoice)

            refreshPrompt(appDesc: appDesc)

            print(generatedOpenLine())
            openLinePrintCount += 1
        }
    }
    else {
        print("failed use of gptVoice command.")
    }

}
func buildCommand(input: String) {
    buildIt() { success, errrors in
            // open it?
           // completion(success, errors)
        if success {
            print("built")
        }
        else {
            print("did not build")
            doPrompting()
        }
    }
}

func commandsCommand(input: String) {
    print(generatedOpenLine(overrideV: true))
}

func linkCommand(input: String) {
    linkIt(link: input) { innerContent in
        if let innerContent = innerContent {

            print("\n🤖 attempt to link to  content for GPT... \(input): \(innerContent)")

            // if overridePrompt is set by the googleCommand.. the next prompt will need to be auto send on this prompts completion.
            linkResultGlobal = "link: \(input)\ncontent: \(innerContent)"

            if let results = linkResultGlobal {
                print("give 🤖 search results")

                doPrompting(overridePrompt: results)
                return
            }
            else {
                print("FAILED to give results")
            }
        }
        else {
            print("failed to get search results.")
        }
    }
}

func encourageCommand(input: String) {
    let il = """
1. You are capable of greatness.
2. Keep pushing forward, even when it's hard.
3. Believe in yourself and your abilities.
4. There's a solution to every problem - keep looking.
5. You can do anything you set your mind to.
6. Trust the journey and have faith in yourself.
7. You are valuable and important.
8. Keep trying, even if you fail.
9. Success is achieved through persistence and hard work.
10. Believe in your dreams - they can become a reality.
"""
    textToSpeech(text: il)
}
