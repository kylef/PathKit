#if os(Linux)
import Glibc

let systemGlob = Glibc.glob
#else
import Darwin

let systemGlob = Darwin.glob
#endif

import Foundation

// MARK: Current Directory

extension Path {
    /**
     The current working directory of the process

     - Note: the current working directory of the process
    */
    public static var current: Path {
        get {
            return self.init(Path.fileManager.currentDirectoryPath)
        }
        set {
            _ = Path.fileManager.changeCurrentDirectoryPath(newValue.description)
        }
    }

    /**
     Changes the current working directory of the process to the path during the execution of the
     given block.

     - Note: The original working directory is restored when the block returns or throws.
     - Parameter closure: A closure to be executed while the current directory is configured to
       the path.
    */
    public func chdir(closure: () throws -> Void) rethrows {
        let previous = Path.current
        Path.current = self
        defer { Path.current = previous }
        try closure()
    }
}

// MARK: Directory Manipulation

extension Path {
    // Linux still uses the FileAttributeKey instead of String
    #if !os(Linux)
    public typealias FileAttributeKey = String
    #endif

    /**
     Create the directory.

     - Note: This method fails if any of the intermediate parent directories does not exist.
       This method also fails if any of the intermediate path elements corresponds to a file and
       not a directory.
    */
    public func mkdir(withIntermediateDirectories: Bool = false, attributes: [FileAttributeKey: Any]? = nil) throws {
        guard !isDirectory else { return }
        try Path.fileManager.createDirectory(atPath: path, withIntermediateDirectories: withIntermediateDirectories, attributes: attributes)
    }

    /**
     Create the directory and any intermediate parent directories that do not exist.

     - Note: This method fails if any of the intermediate path elements corresponds to a file and
       not a directory.
    */
    public func mkpath(attributes: [FileAttributeKey: Any]? = nil) throws {
        try mkdir(withIntermediateDirectories: true, attributes: attributes)
    }

    /**
     Create the directories up until the last path component

     - Note: This method fails if any of the intermediate path elements corresponds to a file and
       not a directory.
    */
    public func mkintermediatedirs(attributes: [FileAttributeKey: Any]? = nil) throws {
        try Path(components: components.dropLast()).mkpath(attributes: attributes)
    }
}

// MARK: Temporary

extension Path {
    /// The path to either the user’s or application’s home directory, depending on the platform.
    public static var home: Path {
        return Path(NSHomeDirectory())
    }

    /// The path of the temporary directory for the current user.
    public static var temporary: Path {
        return Path(NSTemporaryDirectory())
    }

    /**
     - Returns: the path of a temporary directory unique for the process.
     - Note: Based on `NSProcessInfo.globallyUniqueString`.
    */
    public static func processUniqueTemporary() throws -> Path {
        let path = temporary + ProcessInfo.processInfo.globallyUniqueString
        if !path.exists {
            try path.mkdir()
        }
        return path
    }

    /**
     - Returns: the path of a temporary directory unique for each call.
     - Note: Based on `NSUUID`.
    */
    public static func uniqueTemporary() throws -> Path {
        let path = try processUniqueTemporary() + UUID().uuidString
        try path.mkdir()
        return path
    }
}

// MARK: Traversing

extension Path {
    /// Get the normalized path of the parent directory
    public var parent: Path {
        return self + ".."
    }

    /**
     Performs a shallow enumeration in a directory

     - Returns: paths to all files, directories and symbolic links contained in the directory
    */
    public func children() throws -> [Path] {
        return try Path.fileManager.contentsOfDirectory(atPath: path).map {
            self + Path($0)
        }
    }

    /**
     Performs a deep enumeration in a directory

     - Returns: paths to all files, directories and symbolic links contained in the directory or
       any subdirectory.
    */
    public func recursiveChildren() throws -> [Path] {
        return try Path.fileManager.subpathsOfDirectory(atPath: path).map {
            self + Path($0)
        }
    }
}

// MARK: Globbing

extension Path {
    public static func glob(_ pattern: String) -> [Path] {
        var gt = glob_t()
        let cPattern = strdup(pattern)
        defer {
            globfree(&gt)
            free(cPattern)
        }

        let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
        if systemGlob(cPattern, flags, nil, &gt) == 0 {
            #if os(Linux)
                let matchc = gt.gl_pathc
            #else
                let matchc = gt.gl_matchc
            #endif
            return (0..<Int(matchc)).flatMap { index in
                guard let path = String(validatingUTF8: gt.gl_pathv[index]!) else { return nil }
                return Path(path)
            }
        }

        // GLOB_NOMATCH
        return []
    }

    public func glob(_ pattern: String) -> [Path] {
        return Path.glob((self + pattern).description)
    }
}
