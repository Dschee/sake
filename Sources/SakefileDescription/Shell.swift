import Foundation
import SwiftShell

/// Shell error
public struct ShellError: Error, CustomStringConvertible, ShellExitCoding {

    /// Exit code
    public let exitCode: Int
    
    /// Initializes the ShellError with the exit code
    ///
    /// - Parameter exitCode: exit code
    init(exitCode: Int) {
        self.exitCode = exitCode
    }
    
    public var description: String {
        return "Execution error with code: \(exitCode)"
    }
    
}

// MARK: - Shelling

public protocol Shelling {
    func runAndPrint(bash: String) throws
    @discardableResult func run(bash: String) throws -> String
    func runAndPrint(command: String, _ args: String...) throws
    func runAndPrint(command: String, _ args: [String]) throws
    @discardableResult func run(command: String, _ args: String...) throws -> String
    @discardableResult func run(command: String, _ args: [String]) throws -> String
}

/// Cleans the command output trimming whitespaces and newlines.
///
/// - Parameter output: output to be cleaned.
/// - Returns: cleaned output.
func clean(output: String) -> String {
    var output = output
    output = output.trimmingCharacters(in: .whitespacesAndNewlines)
    return output
}

// MARK: - StandardOutputStream

class StandardOutOutputStream: OutputStream {
    
    /// True if the stream prints the output in the console (line by line)
    let printing: Bool
    
    /// True if the output from the stream has to be saved.
    let output: Bool
    
    /// Output data.
    var data: Data = Data()
    
    /// Function that the stream uses to print the written data.
    let printer: (String) -> ()
    
    /// Initializes the StandardOutputStream with its attributes.
    ///
    /// - Parameters:
    ///   - printing: true if the output of the command execution should be printed in real time.
    ///   - output: true if the output of the script should be kept in memory.
    init(printing: Bool = true, output: Bool = false, printer: @escaping (String) -> () = { print($0) }) {
        self.printing = printing
        self.output = output
        self.printer = printer
        super.init(toMemory: ())
    }
    
    /// Writes data to the stream.
    ///
    /// - Parameters:
    ///   - buffer: buffer of data to be written.
    ///   - len: number of bytes to be written.
    /// - Returns: written length.
    override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        let data = Data.init(bytes: buffer, count: len)
        if output {
            self.data.append(data)
        }
        let text = String(data: data, encoding: .utf8)
        if printing {
            self.printer(clean(output: "\(text ?? "")"))
        }
        return len
    }
}

// MARK: - Shell

public final class Shell: Shelling {
    
    // MARK: - Shelling
    
    public func runAndPrint(bash: String) throws {
        try SwiftShell.runAndPrint(bash: bash)
    }
    
    public func run(bash: String) throws -> String {
        let output = SwiftShell.run(bash: bash)
        if output.exitcode == 0 { return output.stdout }
        throw ShellError(exitCode: output.exitcode)
    }
    
    public func runAndPrint(command: String, _ args: String...) throws {
        try SwiftShell.runAndPrint(command, args)
    }
    
    public func runAndPrint(command: String, _ args: [String]) throws {
        try SwiftShell.runAndPrint(command, args)
    }
    
    public func run(command: String, _ args: String...) throws -> String {
        let output = SwiftShell.run(command, args)
        if output.exitcode == 0 { return output.stdout }
        throw ShellError(exitCode: output.exitcode)
    }
    
    public func run(command: String, _ args: [String]) throws -> String {
        let output = SwiftShell.run(command, args)
        if output.exitcode == 0 { return output.stdout }
        throw ShellError(exitCode: output.exitcode)
    }

    public func ask(message: String) -> String {
        print(message, terminator: " ")
        var userInput: String? = readLine()

        while userInput == nil {
            print("Error, please try again.")
            print(message, terminator: " ")
            userInput = readLine()
        }

        return userInput!
    }
    
}
