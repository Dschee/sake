import Foundation

/// Shell error
public struct ShellError: Error, CustomStringConvertible, ShellExitCoding {

    /// Exit code
    public let exitCode: Int32
    
    /// Initializes the ShellError with the exit code
    ///
    /// - Parameter exitCode: exit code
    init(exitCode: Int32) {
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

// MARK: - ShellCommandExecutor

class ShellCommandExecutor {
    
    typealias ShellOutput = (output: String?, exitCode: Int32)
    typealias ProcessLauncher = (Process, StandardOutOutputStream) -> ShellOutput
    
    /// Output stream.
    let outputStream: StandardOutOutputStream
    
    /// Process.
    let process: Process
    
    /// Launcher
    let launcher: ProcessLauncher
    
    /// Initializes the CommandExecutor.
    ///
    /// - Parameters:
    ///   - launchPath: launch path.
    ///   - arguments: arguments.
    ///   - outputStream: output stream.
    init(launchPath: String,
         arguments: [String],
         outputStream: StandardOutOutputStream = StandardOutOutputStream(),
         launcher: @escaping ProcessLauncher = ShellCommandExecutor.launch) {
        self.outputStream = outputStream
        self.process = Process()
        self.process.launchPath = launchPath
        self.process.standardInput = Pipe()
        self.process.arguments = arguments
        let pipe = ShellCommandExecutor.outputStreamWritingPipe(outputStream: outputStream)
        process.standardOutput = pipe
        process.standardError = pipe
        self.launcher = launcher
    }
    
    /// Executes the command.
    ///
    /// - Returns: output string and exit code.
    func execute() -> ShellOutput {
        let result = launcher(process, outputStream)
        return (output: result.output.map(clean), exitCode: result.exitCode)
    }
    
    /// It returns the pipe to send the output through.
    ///
    /// - Returns: pipe to be used as the output pipe for the process.
    static func outputStreamWritingPipe(outputStream: OutputStream) -> Pipe {
        let outputPipe = Pipe()
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0 {
                _ = outputStream.write([UInt8](data), maxLength: data.count)
            }
        }
        return outputPipe
    }
    
    static func launch(process: Process, outputStream: StandardOutOutputStream) -> ShellOutput {
        process.launch()
        process.waitUntilExit()
        var output: String?
        if outputStream.output {
            output = String(data: outputStream.data, encoding: .utf8) ?? ""
        }
        return (output: output, exitCode: process.terminationStatus)
    }
    
}

// MARK: - Shell

public final class Shell: Shelling {
    
    typealias Execute = (_ launchPath: String, _ arguments: [String], _ printing: Bool, _ output: Bool) -> ShellCommandExecutor.ShellOutput
    
    // MARK: - Attributes
    
    fileprivate let execute: Execute
    fileprivate static var activeCommand: ShellCommandExecutor?
    
    // MARK: - Init
    
    init(execute: @escaping Execute = Shell.execute) {
        self.execute = execute
        Signals.trap(signal: .int) { signal in
            Shell.activeCommand?.process.terminate()
        }
    }
    
    // MARK: - Shelling
    
    public func runAndPrint(bash: String) throws {
        try runAndPrint(command: "/bin/bash", "-c", bash)
    }
    
    public func run(bash: String) throws -> String {
        return try run(command: "/bin/bash", "-c", bash)
    }
    
    public func runAndPrint(command: String, _ args: String...) throws {
        try runAndPrint(command: command, args)
    }
    
    public func runAndPrint(command: String, _ args: [String]) throws {
        let result = execute(command: command, printing: true, output: false, args)
        if result.exitCode != 0 {
            throw ShellError(exitCode: result.exitCode)
        }
    }
    
    public func run(command: String, _ args: String...) throws -> String {
        return try run(command: command, args)
    }
    
    public func run(command: String, _ args: [String]) throws -> String {
        let result = execute(command: command, printing: false, output: true, args)
        if result.exitCode == 0 {
            return result.output ?? ""
        } else {
            throw ShellError(exitCode: result.exitCode)
        }
    }
    
    // MARK: - Fileprivate
    
    @discardableResult fileprivate func execute(command: String,
                                                printing: Bool,
                                                output: Bool,
                                                _ args: [String]) -> ShellCommandExecutor.ShellOutput {
        func launchpath(_ command: String) -> String {
            if command.contains("/") { return command }
            let result = execute("/user/bin/which", [command], false, true)
            return result.output ?? command
        }
        return execute(launchpath(command), args, printing, output)
    }
    
    fileprivate static func execute(launchPath: String,
                                    arguments: [String],
                                    printing: Bool,
                                    output: Bool) -> ShellCommandExecutor.ShellOutput {
        let command = ShellCommandExecutor(launchPath: launchPath,
                                           arguments: arguments,
                                           outputStream: StandardOutOutputStream(printing: printing, output: output))
        Shell.activeCommand = command
        let output = command.execute()
        Shell.activeCommand = nil
        return output
    }

}
