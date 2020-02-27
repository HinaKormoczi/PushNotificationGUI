//
//  Helpers.swift
//  Push Notification GUI
//
//  Created by Hina Kormoczi on 2020. 02. 24.
//  Copyright © 2020. Hina Kormoczi. All rights reserved.
//

import Foundation

protocol CommandExecuting {
    
    func execute(commandName: String) -> String?
    func execute(commandName: String, arguments: [String]) -> String?

}

class Helpers {
    
    static func sendPushToSimulator(uuid: String, bundle: String, filePath: String) {
        let bash: CommandExecuting = Bash()
        print("xcrun simctl push \(uuid) \(bundle) \(filePath)")
        _ = bash.execute(commandName: "xcrun", arguments: ["simctl", "push", uuid, bundle, filePath])
        //xcrun simctl push 6732348E-857C-4EB9-8D01-F90796C74845 mako.Push-Notification-Test Push.apns
    }
    
    static func getDevices() -> [String] {
        let bash: CommandExecuting = Bash()
        guard let output = bash.execute(commandName: "instruments", arguments: ["-s", "devices"]) else { return [""] }
        return output.split { $0.isNewline }.map { String($0) }
    }
    
    static func isBooted(_ uuid: String) -> Bool{
        let bash: CommandExecuting = Bash()
        guard let output = bash.execute(commandName: "xcrun", arguments: ["simctl", "spawn", uuid, "launchctl", "print", "system"]) else { return false }
        return output.contains("com.apple.springboard.services") 
    }
    
    static func stringToDevice(_ string: String) -> Device {
        let result = Device()
        result.name = String(string.split(separator: "[").first ?? "")
        result.uuid = string.slice(from: "[", to: "]") ?? ""
        do {
            let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask).first!
            _ = try FileManager.default.contentsOfDirectory(at: libraryURL.appendingPathComponent("Developer/CoreSimulator/Devices/\(result.uuid)/data/Containers/Bundle/Application/"), includingPropertiesForKeys: nil)
            result.isAvailable = isBooted(result.uuid)
            return result
        } catch {
            result.isAvailable = false
            return result
        }
    }
    
}

extension String {

    func slice(from: String, to: String) -> String? {

        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

final class Bash: CommandExecuting {
    
    // MARK: - CommandExecuting
    func execute(commandName: String) -> String? {
        return execute(commandName: commandName, arguments: [])
    }
    
    func execute(commandName: String, arguments: [String]) -> String? {
        guard var bashCommand = execute(command: "/bin/bash" , arguments: ["-l", "-c", "which \(commandName)"]) else { return "\(commandName) not found" }
        bashCommand = bashCommand.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        return execute(command: bashCommand, arguments: arguments)
    }
    // MARK: Private
        
    private func execute(command: String, arguments: [String] = []) -> String? {
        let process = Process()
        process.launchPath = command
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)
        return output
    }
}
