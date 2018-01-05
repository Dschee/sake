import Foundation
import PathKit
import SakefileDescription

/// Runs the Sakefile.
public class RunSakefile {

    // MARK: - Attributes

    /// Path where the Sakefile.swift file is.
    let path: String

    /// Arguments to be passed.
    let arguments: [String]

    /// Verbose
    let verbose: Bool

    /// Run bash command.
    let runBashCommand: (String) throws -> ()

    /// Returns the Sakefile.swift path if it exists in the given directory.
    let sakefilePath: (Path) -> Path?

    /// Returns the file description library path.
    let fileDescriptionLibraryPath: () -> Path?

    // MARK: - Init

    /// Default constructor.
    ///
    /// - Parameters:
    ///   - path: path where the Sakefile.swift file is.
    ///   - arguments: arguments to be passed.
    ///   - verbose: if it should print logs verbosely.
    convenience public init(path: String,
                            arguments: [String],
                            verbose: Bool) {
        self.init(path: path,
                  arguments: arguments,
                  verbose: verbose,
                  sakefilePath: RunSakefile.sakefilePath,
                  fileDescriptionLibraryPath: { Runtime.filedescriptionLibraryPath() },
                  runBashCommand: { try Utils.shell.runAndPrint(bash: $0) })
    }

    /// Default constructor.
    ///
    /// - Parameters:
    ///   - path: path where the Sakefile.swift file is.
    ///   - arguments: arguments to be passed.
    ///   - verbose: if it should print logs verbosely.
    ///   - sakefilePath: returns the Sakefile.swift path if it exists in the given directory.
    ///   - fileDescriptionLibraryPath: returns the file description library path.
    ///   - runBashCommand: closure runs the bash command.
    init(path: String,
         arguments: [String],
         verbose: Bool,
         sakefilePath: @escaping (Path) -> Path?,
         fileDescriptionLibraryPath: @escaping () -> Path?,
         runBashCommand: @escaping (String) throws -> Void) {
        self.path = path
        self.arguments = arguments
        self.verbose = verbose
        self.sakefilePath = sakefilePath
        self.fileDescriptionLibraryPath = fileDescriptionLibraryPath
        self.runBashCommand = runBashCommand
    }

    // MARK: - Public

    /// Executes the Sakefile.swift
    ///
    /// - Throws: an error if the execution fails for any reason.
    public func execute() throws {
        guard let sakefilePath = sakefilePath(Path(path)) else {
            throw "Couldn't find Sakefile.swift in directory \(path)"
        }
        guard let filedescriptionLibraryPath = fileDescriptionLibraryPath() else {
            throw "Couldn't find libSakefileDescription.dylib to link against to"
        }

        var arguments: [String] = []
        arguments += ["--driver-mode=swift"]
        arguments += ["-suppress-warnings"]
        arguments += ["-L", filedescriptionLibraryPath.parent().normalize().string]
        arguments += ["-I", filedescriptionLibraryPath.parent().normalize().string]
        arguments += ["-lSakefileDescription"]
        arguments += [sakefilePath.string]
        arguments += self.arguments
        do {
            var bashCommand = "swiftc \(arguments.joined(separator: " "))"
            if !verbose {
                bashCommand = "exec 2>/dev/null; \(bashCommand)"
            }
            try runBashCommand(bashCommand)
        } catch {
            throw "Something went wrong running Sakefile.swift. Use --verbose to get more details about the problem."
        }
    }

    // MARK: - Fileprivate

    static func sakefilePath(path: Path) -> Path? {
        let sakefilePath = (path + "Sakefile.swift").normalize()
        if sakefilePath.exists {
            return sakefilePath
        }
        return nil
    }

}
