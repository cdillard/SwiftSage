//
//  Trivia.swift
//  Swifty-GPT
//
//  Created by Chris Dillard on 4/21/23.
//
import Foundation

struct TriviaQuestion {
    let question: String
    let code: String?
    let options: [String]
    let correctOptionIndex: Int
    let reference: String
}

func printRandomUnusedTrivia() {
    guard !trivialQs.isEmpty else { print("nope no qs") ; return }
    let randDex = Int.random(in: 0...trivialQs.count - 1)

    chosenTQ = trivialQs[randDex]
    guard let tq = chosenTQ else { return print("no q.. failed.") }

    printTrivia(tq, index: randDex)
}

func printTrivia(_ trivia: TriviaQuestion, index: Int) {
    multiPrinter("---------\n")
    multiPrinter("Trivia Question:")
    multiPrinter(trivia.question)

    if trivia.code?.isEmpty == false {
        multiPrinter("\nCode:")
        multiPrinter(trivia.code ?? "")
    }

    multiPrinter("\nOptions:")

    for (optionIndex, option) in trivia.options.enumerated() {
        multiPrinter("\(optionIndex + 1). \(option)")
    }
    if !trivia.reference.isEmpty {
        multiPrinter("\nReference:")
        multiPrinter(trivia.reference)
    }
    multiPrinter("---------")
    multiPrinter("Choose correct answer [1-4], or quit w/ `q`?")
}

func parseMarkdown(_ content: String) -> [TriviaQuestion] {
    let lines = content.components(separatedBy: .newlines)
    var questions: [TriviaQuestion] = []
    var currentQuestion: String?
    var currentCode: String?
    var currentOptions: [String] = []
    var currentCorrectOptionIndex: Int?
    var currentReference: String?
    var insideCodeBlock = false
    var insideReferenceBlock = false

    for line in lines {
        if line.hasPrefix("#### Q") {
            currentQuestion = line.replacingOccurrences(of: "#### Q", with: "").trimmingCharacters(in: .whitespaces)
        } else if line.hasPrefix("```swift") {
            currentCode = ""
            insideCodeBlock = true
        } else if line.hasPrefix("```") {
            insideCodeBlock = false
            insideReferenceBlock = !insideReferenceBlock
            if insideReferenceBlock {
                currentReference = ""
            } else {
                if let question = currentQuestion,
                   let correctOptionIndex = currentCorrectOptionIndex,
                   let reference = currentReference {
                    let triviaQuestion = TriviaQuestion(question: question, code: currentCode, options: currentOptions, correctOptionIndex: correctOptionIndex, reference: reference)
                    questions.append(triviaQuestion)
                }
                currentQuestion = nil
                currentCode = nil
                currentOptions = []
                currentCorrectOptionIndex = nil
                currentReference = nil
            }
        } else if line.hasPrefix("- [") {
            let option = line.replacingOccurrences(of: "- [", with: "").replacingOccurrences(of: "]", with: "").trimmingCharacters(in: .whitespaces)
            if option.hasPrefix("x") {
                currentCorrectOptionIndex = currentOptions.count
                currentOptions.append(option.replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .whitespaces))
            } else {
                currentOptions.append(option.trimmingCharacters(in: .whitespaces))
            }
        } else if insideCodeBlock {
            currentCode! += line + "\n"
        } else if insideReferenceBlock {
            if line.isEmpty { continue }
            currentReference! += line + "\n"
        }
    }

    // Debugging quiz parsing
    //    multiPrinter(questions)

    return questions
}

func readMDFile(_ filePath: String) -> String? {
    do {
        let mdContent = try String(contentsOfFile: filePath, encoding: .utf8)
        return mdContent
    } catch {
        multiPrinter("Error reading MD file: \(error.localizedDescription)")
        return nil
    }
}

var trivialQs: [TriviaQuestion] = []

func loadTriviaSystem() {


    trivialQs.removeAll()

    if let path = Bundle.main.path(forResource: "swift-quiz", ofType: "md"), let text = readMDFile(path) {
        trivialQs += parseMarkdown(text)


        // Add obj-c quizing sometime
//        if let path2 = Bundle.main.path(forResource: "objective-c-quiz", ofType: "md"), let text2 = readMDFile(path2) {
//            trivialQs += parseTrivia(from: text2)
//        }
//        else {
//            multiPrinter("Failed to add objc-c qs....")
//
//        }
 //       multiPrinter("Parsed \(trivialQs.count) iOS trivia qs...")
    }
    else {
        multiPrinter("Failed to add Swift qs..")
    }

}
