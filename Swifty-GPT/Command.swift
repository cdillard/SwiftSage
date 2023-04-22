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

    "1": runAppDesc,
    "2": showLoadedPrompt,
    "3": openProjectCommand,
    "4": closeCommand,
    "5": fixItCommand,
    "6": openProjectCommand,

    "r": runAppDesc,
    "s": showLoadedPrompt,
    "o": openProjectCommand,  // TODO: If its not set. let them pick one via the Sage task bar item menu.
    "b": buildCommand,
    //"x": voiceSettingsCommand,

    "xcode:": xcodeCommand,
    "idea:": ideaCommand,
    "i": ideaCommand,

    "google:": googleCommand,
    "link:": linkCommand,

    "image:": imageCommand,
    "gpt:": gptCommand,
    "gptVoice:": gptVoiceCommand,
    "gv": gptVoiceCommand,
    "gptFile": gptFileCommand,
    "gf": gptFileCommand,
    "ideaFile": ideaFileCommand,
    "if": ideaFileCommand,

    "q": exitCommand,
    "exit": exitCommand,
    "e": exitCommand,
    "stop": stopCommand,
    "st": stopCommand,
    "random": randomCommand,
    "rand": randomCommand,
    "prompts": promptsCommand,
    "p": promptsCommand,
    "sing": singCommand,
    "sn": singCommand,
    "reset": resetCommand,
    "rs": resetCommand,
    "commands": commandsCommand,
    "c": commandsCommand,

    "delete": deleteCommand,
    "del": deleteCommand,
    "globals": globalsCommand,

    // Experimental
    "trivia": triviaCommand,
    "t": triviaCommand,

    // Testing
    "testLoad": testLoadCommand,

    // Eggs
    "encourage": encourageCommand,
    "sage": sageCommand,
    "alien": alienCommand,
    "movies": moviesCommand,
]

var presentMode = true

func resetCommand(input: String) {
    projectName = "MyApp"
    globalErrors = [String]()
    manualPromptString = ""
    blockingInput = false
    promptingRetryNumber = 0

    lastFileContents = [String]()
    lastNameContents = [String]()
    searchResultHeadingGlobal = nil

    appName = "MyApp"
    appType = "iOS"

    appDesc = builtInAppDesc
    language = "Swift"

    streak = 0
    chosenTQ = nil

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
    // TODO: Figure out a way to make this invalidate the potential GPTs requests and Google APIs requests.
}

func ideaCommand(input: String) {

    let newPrompt = createIdeaPrompt(command: input)

    doPrompting(overridePrompt: newPrompt)
}

func zeroCommand(input: String) {

    if voiceInputEnabled {
        requestMicrophoneAccess { granted in
            if granted {
                print("Microphone access granted.")
                // Start audio capture or other operations that require microphone access.
            } else {
                print("Microphone access denied.")
                // Handle the case where microphone access is denied.
            }
        }

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
    else {
        print("voice input disabled.")
    }
}

func gptFileCommand(input: String) {
    // You'll have to create this InputText file yourself in the SwiftyGPT worksspace.
    let pathToInputTextFile: String =
       "\(getWorkspaceFolder())\(swiftyGPTWorkspaceFirstName)/InputText"

    if let text = readFile(path: pathToInputTextFile) {
        gptCommand(input: text)
    }
    else {
        print("no InputText....")
    }
}

func readFile(path: String) -> String? {
    do {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        return content
    } catch {
        print("Error reading file: \(error)")
        return nil
    }
}

func ideaFileCommand(input: String) {
    // You'll have to create this IdeaText file yourself in the SwiftyGPT worksspace.
    let pathToInputTextFile: String =
       "\(getWorkspaceFolder())\(swiftyGPTWorkspaceFirstName)/IdeaText"

    if let text = readFile(path: pathToInputTextFile) {
        ideaCommand(input: text)
    }
    else {
        print("no IdeaText....")
    }
}

func gptCommand(input: String) {
    manualPromptString = input
    sendPromptToGPT(prompt: manualPromptString, currentRetry: 0) { content, success in
        if !success {
            textToSpeech(text: "A.P.I. error, try again.", overrideWpm: "242")
            return
        }

        // print("\n🤖: \(content)")

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
    // create file should check if the file already exists
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
    executeAppleScriptCommand(.openProject(name: projectName)) { success, error in
        if success {
            print("project opened successfully")
        }
        else {
            print("project failed to open.")
        }
    }
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


func globalsCommand(input: String) {
    print("projectName = \(projectName)")
    print("globalErrors = \(globalErrors)")
    print("manualPromptString = \(manualPromptString)")
    print("projectName = \(projectName)")
    print("BlockingInput = \(blockingInput)")
    print("promptingRetryNumber = \(promptingRetryNumber)")
    print("chosenTQ = \(chosenTQ.debugDescription)")
    print("lastFileContents = \(lastFileContents)")
    print("lastNameContents = \(lastNameContents)")
    print("searchResultHeadingGlobal = \(searchResultHeadingGlobal ?? "none")")
    print("linkResultGlobal = \(linkResultGlobal ?? "none")")
    print("appName = \(appName)")
    print("appType = \(appType)")
    print("language = \(language)")
}

// EGG LAND
func sageCommand(input: String) {
    print(Int.random(in: 0...1) == 0 ? sage2 : sage3)
}
func alienCommand(input: String) {
    print(alien)
}
func triviaCommand(input: String) {
    printRandomUnusedTrivia()
}

func encourageCommand(input: String) {
//    let il = """
//1. You are capable of greatness.
//2. Keep pushing forward, even when it's hard.
//3. Believe in yourself and your abilities.
//4. There's a solution to every problem - keep looking.
//5. You can do anything you set your mind to.
//6. Trust the journey and have faith in yourself.
//7. You are valuable and important.
//8. Keep trying, even if you fail.
//9. Success is achieved through persistence and hard work.
//10. Believe in your dreams - they can become a reality.
//"""

    let song2 = """
Verse 1:
Listen up, y'all, I gotta story to tell,
About a tool that's power's unparalleled,
It's called Swift Sage, and trust me when I say,
It'll blow your mind, in the coolest way.

Chorus:
Swift Sage, Swift Sage,
The coolest tool in every way,
Faster than a cheetah, smarter than a sage,
Swift Sage is all the rage.

Verse 2:
With its high-speed parsing and intuitive flow,
Coding's easier than ever, don't you know,
From variables to functions and everything in-between,
Swift Sage has your back, it's the ultimate coding queen.

Chorus:
Swift Sage, Swift Sage,
The coolest tool in every way,
Faster than a cheetah, smarter than a sage,
Swift Sage is all the rage.

Verse 3:
Plus, the add-ons and plugins are totally sick,
Making coding so easy, it's like a party trick,
With Swift Sage, you can up your coding game,
And take on any challenge, with no shame.

Chorus:
Swift Sage, Swift Sage,
The coolest tool in every way,
Faster than a cheetah, smarter than a sage,
Swift Sage is all the rage.

Outro:
So if you wanna be on top of your coding game,
And impress all your friends, without shame,
Look no further, cause Swift Sage is here,
The coolest tool in the game, have no fear.
"""

    textToSpeech(text: song2)
}

func moviesCommand(input: String) {
    goToMovies()
}

func testLoadCommand(input: String) {
    startRandomSpinner()
}
