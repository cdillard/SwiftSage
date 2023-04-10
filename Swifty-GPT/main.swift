//
//  main.swift
//  Swifty-GPT
//
//  Created by Chris Dillard on 4/8/23.
//

import Foundation

// Note you must have xcodegen brew and gem xcodeproj installed.

// Replace this with your OpenAI API key
let OPEN_AI_KEY = "sk-OPEN-AI-KEY"
let PIXABAY_KEY = "PIXABAY_KEY"

// TODO: Fix hardcoded paths.
let xcodegenPath = "/opt/homebrew/bin/xcodegen"
let infoPlistPath = "/Users/sprinchar/Documents/GPT/Swifty-GPT/Swifty-GPT/Info.plist"
let rubyScriptPath = "/Users/sprinchar/Documents/GPT/Swifty-GPT/Swifty-GPT/add_file_to_project.rb"
let apiEndpoint = "https://api.openai.com/v1/chat/completions"
let swiftyGPTWorkspaceName = "SwiftyGPTWorkspace"

struct GPTAction: Codable {
    let command: String
    let name: String?
    let fileContents: String?
}

var projectName = ""

// Main function to run the middleware
func main() {
    // Parse command-line arguments
    let arguments = CommandLine.arguments
    let appName = arguments.contains("--name") ? arguments[arguments.firstIndex(of: "--name")! + 1] : "MyApp"
    let appType = arguments.contains("--type") ? arguments[arguments.firstIndex(of: "--type")! + 1] : "iOS"
    let language = arguments.contains("--language") ? arguments[arguments.firstIndex(of: "--language")! + 1] : "Swift"

    // TODO: Check workspace and delete or backup if req

    // Other optional command-line arguments, like frameworks or additional features, can be added here

   // let appDesc = "that displays a text label that says."
    let appDesc = "that displays a text label that says 'Hello World! with text color that randomly changes to a random color every random number of seconds between 1-3."

    // Working PROMPTS that generate somewhat working code.
  //  let appDesc = "that displays a label that says I love you so much! with heart emojis all around the scren in random places."
    // let appDesc = "containing a label that says 'Hello World!"
    // let appDesc = "containing a color picker and a label that says `Hi bud` which changes color based on the picker."
    // let appDesc = "containing a scrollable grid with random colors in each square."
    //let appDesc = "containing a circle that can be moved by tapping and dragging."
    // let appDesc = "containing a circle that can be moved by tapping and dragging and stays where you move it."
//    let appDesc = "containing a list of hilarious jokes."
//    let appDesc = "that displays a beautiful gradient between green and light green across the entire screen. Show a system symbol in multicolor of the palette in the center of the screen."
  //  let appDesc = "that displays a checkers board. you can make this out of the shapes build into the SwiftUI drawing library."

   //   let appDesc = "that shows a 3d scene using SceneKit. Show a beach ball in the SceneKit 3d view."
   // let appDesc = "that displays the following text using a typewriter animation: \"You are feeling very sleepy...\nYou want to know more...\nDreams slowly take you...\""

    // PARTIALLY WORKS. EXCITED TO see gpt-4
   // let appDesc = "that displays the classic Hangman game. A random word should be chosen and the user should be able to guess by entering into the text field."
   // let appDesc = "that implments the classic game battleships. The user should be able to play against the computer opponent."

    // Should use import Accelerate ????
    //  let appDesc = "that displays a mandelbrot set fractal in green on a black background."

    // let appDesc = "Generate Swift code for an iOS app that displays an interactive Mandelbrot set fractal. The app should allow users to zoom in and out, and pan the fractal using touch gestures. The fractal should be rendered in real-time, with adjustable color schemes. Include code for basic touch gesture handling and the fractal generation algorithm."

    //let appDesc = "that shows an wave using sin function. Animate the wave by changing the value passed to sin over time. "
    // let appDesc = "that shows a spiral that rotates 360 degrees repeatedly."
    // let appDesc = "that displays all the emoji related to plants and green across the screen in random locations."

    // borky
//    let appDesc = "that displays an american flag. The american flag should be drawn using the built in shape drawing in SwiftUI."
    // let appDesc = "that displays a list of saved notes. The app should allow the user to create a new note."

    // Example GPT prompt with command-line arguments included
    let prompt = """
You are working on a \(appType) app in the \(language) programming language named \(appName).

As an AI language model, please generate \(language) code for a SwiftUI app \(appDesc). Your response should include the necessary \(language) code files. Please ensure that the generated code is valid and properly formatted. The files should be returned as a JSON array with the following structure:

It is essential you return your response as a JSON array matching the structure below.
[{"command": "Create file","name": "Filename.swift","fileContents": "SWIFT_FILE_CONTENTS"}]

Please keep in mind the following constraints when generating the response:

1. Focus on generating valid and properly formatted Swift code that includes proper escaping for JSON parsing.
2. Complete tasks in this order: Create project. Create Swift files including App file. Open project. Close project.
3. Ensure that the app uses SwiftUI.
4. The response should include all necessary files for a basic SwiftUI app.

Use these commands in your response:
     Close project {x}
     Create project {x}
     Open project {x}
     Create file {fileName} {fileContents}
"""
/*
 3. Run project
 4. Build project
 5. Test project
 6. Commit changes
 7. Push changes
 8. Send Slack message
 */

    // Send the prompt to GPT
    sendPromptToGPT(prompt: prompt) { gptOutput in
        print("GPT OUTPUT =\n\(gptOutput)\nEND GPT...")
        // Parse GPT's output and execute the corresponding Xcode commands
        parseAndExecuteGPTOutput(gptOutput)
    }
}

// Function to send a prompt to GPT via the OpenAI API
func sendPromptToGPT(prompt: String, completion: @escaping (String) -> Void) {

    let sema = DispatchSemaphore(value: 0)

    let url = URL(string: apiEndpoint)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    // Set the required headers
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(OPEN_AI_KEY)", forHTTPHeaderField: "Authorization")

    // Prepare the request payload
    let requestBody: [String: Any] = [
        "model": "gpt-3.5-turbo",
        "messages": [
            [
                "role": "user",
                "content": prompt,
            ]
        ]
    ]

    // Convert the payload to JSON data
    let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

    request.httpBody = jsonData

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error occurred: \(error.localizedDescription)")
            return
        }

        guard let data  else { return print("failed to laod data") }

        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = jsonResponse["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(content)
                sema.signal()
            }
        } catch {
            print("Error parsing JSON: \(error.localizedDescription)")
        }
    }
    print("🐑🧠🧠🧠 THINKING... 🧠🧠🧠🐑")
    task.resume()
    sema.wait()
}

func executeXcodeCommand(_ command: XcodeCommand) {
    // Implement your logic here based on the command
    switch command {
    case let .openProject(name):

        print("Opening project with name: \(name)")
        executeAppleScriptCommand(.openProject(name: projectName))
    case let .createProject(name):
        print("Creating project with name: \(name)")
        projectName = name
        print("set current name")
        let projectPath = "\(getWorkspaceFolder())\(swiftyGPTWorkspaceName)/"

        // Call the createNewWorkspace function directly
        createNewProject(projectName: name, projectDirectory: projectPath)

    case .closeProject(name: let name):
        print("Closing project with name: \(name)")
        executeAppleScriptCommand(.closeProject(name: name))

    case .createFile(fileName: let fileName, fileContents: let fileContents):
        if projectName.isEmpty {
            print("missing proj, creating one")

            // MIssing projecr gen// create a proj
            executeXcodeCommand(.createProject(name: projectName))
        }
        let projectPath = "\(getWorkspaceFolder())\(swiftyGPTWorkspaceName)/\(projectName)"
        let filePath = "\(projectPath)/Sources/\(fileName)"
        print("Adding file w/ path: \(filePath) w/ contents w length = \(fileContents.count) to p=\(projectPath)")
        createFile(projectPath: "\(projectPath).xcodeproj", projectName: projectName, targetName: projectName, filePath: filePath, fileContent: fileContents)
    }
}

// Function to execute an high level Xcode Shell/ Ruby / AppleScript command
func executeAppleScriptCommand(_ command: XcodeCommand) {
    if !command.appleScript.isEmpty {

        let appleScriptCommand = command.appleScript
        let script = NSAppleScript(source: appleScriptCommand)
        var errorDict: NSDictionary? = nil
        print("Executing AppleScript: \(command)")

        script?.executeAndReturnError(&errorDict)
        if let error = errorDict {
            print("AppleScript Error: \(error)")
        }
    } else {
        print("Unsupported command")
    }
}


func parseAndExecuteGPTOutput(_ output: String) {
    guard let data = output.data(using: .utf8) else {
         print("Invalid GPT output")
         return
     }

     do {
         let gptCommands = try JSONDecoder().decode([GPTAction].self, from: data)
         for gptAction in gptCommands {

             let fullCommand = gptAction.command

             switch fullCommand {
             case "Create project":
                 guard let name = gptAction.name else { return }

                 executeXcodeCommand(.createProject(name: name))
             case "Open project":
                 guard let name = gptAction.name else { return }

                 executeXcodeCommand(.openProject(name: name))
             case "Close project":
                 guard let name = gptAction.name else { return }

                 executeXcodeCommand(.createProject(name: name))
             case "Create file":
                 guard let fileName = gptAction.name, let fileContents = gptAction.fileContents else { return }

                 executeXcodeCommand(.createFile(fileName: fileName, fileContents:fileContents))

             default:
                 print("Unknown command \(fullCommand)")
             }
         }
     } catch {
         print("Error decoding JSON: \(error)")
     }
}

// TODO: Fix hardcoded paths to Info.plist.
func createNewProject(projectName: String, projectDirectory: String) {
    let projectSpec = """
    name: \(projectName)
    targets:
      \(projectName):
        type: application
        platform: iOS
        deploymentTarget: "14.0"
        sources: [Sources]
        info:
          path: \(infoPlistPath)
          properties:
            CFBundleVersion: "1.0"
            UILaunchScreen: []
        settings:
          base:
            PRODUCT_BUNDLE_IDENTIFIER: com.example.\(projectName)
            INFOPLIST_FILE: \(infoPlistPath)
    """

    // TODO: Fix harcoded path to xcodegen.
    let projectSpecPath = "\(projectDirectory)\(projectName)/project.yml"
    let createProjectScript = """
    mkdir -p \(projectDirectory)/\(projectName)/Sources
    echo '\(projectSpec)' > \(projectSpecPath)
    \(xcodegenPath) generate --spec \(projectSpecPath) --project \(projectDirectory)
    """

    let task = Process()
    task.launchPath = "/bin/zsh"
    task.arguments = ["-c", createProjectScript]
    task.launch()
    task.waitUntilExit()

    let status = task.terminationStatus
    if status == 0 {
        print("Project created successfully")
    } else {
        print("Error creating project")
    }
}

func createFile(projectPath: String, projectName: String, targetName: String, filePath: String, fileContent: String) {
    print("createFile w/ contents = \(fileContent)")

    // Create a new Swift file
    if let data = fileContent.data(using: .utf8) {
        try? data.write(to: URL(fileURLWithPath: filePath))
    }

    // Add the file to the project using xcodeproj gem
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    task.arguments = [
        "ruby",
        // TODO: Fix hardcoded path.
        rubyScriptPath,
        projectPath,
        filePath,
        targetName
    ]

    do {
        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            print("Error: Failed to add file to the project.")
        } else {
            print("File successfully added to the project.")
        }
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

main()
