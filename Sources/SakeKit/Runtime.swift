import Foundation
import PathKit

class Runtime {

    static func filedescriptionLibraryPath(exists: (Path) -> Bool = { $0.exists }) -> Path? {
        if let librariesPath = librariesPath,
            exists(Path(librariesPath) + "libSakefileDescription.dylib") {
            return Path(librariesPath) + "libSakefileDescription.dylib"
        }
        return Runtime.librariesFolders()
            .first { (potentialPath) -> Bool in
                exists(Path(potentialPath) + "libSakefileDescription.dylib")
            }.flatMap({ (Path($0)  + "libSakefileDescription.dylib").absolute() })
    }
    
    static func librariesFolders() -> [String] {
        return [
            ".build/debug", // Local
            ".build/release" // Local
        ]
    }
    
}
