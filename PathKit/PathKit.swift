// PathKit - Effortless path operations

import Foundation

/// Represents a filesystem path.
public struct Path {
    public static let separator = "/"

    private var path: String

    internal static var fileManager = NSFileManager.defaultManager()

    // MARK: Init

    public init() {
        self.path = ""
    }

    /// Create a Path from a given String
    public init(_ path: String) {
        self.path = path
    }

    /// Create a Path by joining multiple path components together
    public init(components:[String]) {
        path = components.joinWithSeparator(Path.separator)
    }
}


// MARK: StringLiteralConvertible

extension Path : StringLiteralConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType
    
    public init(extendedGraphemeClusterLiteral path: StringLiteralType) {
        self.init(stringLiteral: path)
    }
    
    public init(unicodeScalarLiteral path: StringLiteralType) {
        self.init(stringLiteral: path)
    }
    
    public init(stringLiteral value: StringLiteralType) {
        self.path = value
    }
}


// MARK: CustomStringConvertible

extension Path : CustomStringConvertible {
    public var description: String {
        return self.path
    }
}


// MARK: Hashable

extension Path : Hashable {
    public var hashValue: Int {
        return path.hashValue
    }
}


// MARK: Path Info

extension Path {
    /** Method for testing whether a path is absolute.
    :return: true if the path begings with a slash
    */
    public var isAbsolute: Bool {
        return path.hasPrefix(Path.separator)
    }

    /// Returns true if a path is relative (not absolute)
    public var isRelative: Bool {
        return !isAbsolute
    }

    /// Returns the absolute path in the actual filesystem
    public func absolute() -> Path {
        if isAbsolute {
            return normalize()
        }

        return (Path.current + self).normalize()
    }

    /// Normalizes the path, this cleans up redundant ".." and ".", double slashes
    /// and resolves "~".
    public func normalize() -> Path {
        return Path((self.path as NSString).stringByStandardizingPath)
    }
}


// MARK: File Info

extension Path {
    /// Returns whether a file or directory exists at a specified path
    public var exists: Bool {
        return Path.fileManager.fileExistsAtPath(self.path)
    }
    
    /** Method for testing whether a path is a directory.
    :return: true if the path exists on disk and is a directory
    */
    public var isDirectory: Bool {
        var directory = ObjCBool(false)
        return Path.fileManager.fileExistsAtPath(normalize().path, isDirectory: &directory) && directory.boolValue
    }
}


// MARK: File Manipulation

extension Path {
    public func delete() throws -> () {
        try Path.fileManager.removeItemAtPath(self.path)
    }

    public func move(destination: Path) throws -> () {
        try Path.fileManager.moveItemAtPath(self.path, toPath: destination.path)
    }
}


// MARK: Current Directory

extension Path {
    // Returns the current working directory of the process
    public static var current: Path {
        get {
            return self.init(Path.fileManager.currentDirectoryPath)
        }
        set {
            Path.fileManager.changeCurrentDirectoryPath(newValue.description)
        }
    }
    
    /** Changes the current working directory of the process to the path during the execution of the given block.
    - parameter closure: A closure to be executed while the current directory is configured to the path.
    :note: The original working directory is restored when the block exits.
    */
    public func chdir(closure: (() -> ())) {
        let previous = Path.current
        Path.current = self
        closure()
        Path.current = previous
    }
}


// MARK: Contents

extension Path {
    public func read() -> NSData? {
        return Path.fileManager.contentsAtPath(self.path)
    }

    public func read() -> String? {
        if let data:NSData = read() {
            return NSString(data:data, encoding: NSUTF8StringEncoding) as? String
        }

        return nil
    }

    public func write(data: NSData) -> Bool {
        return data.writeToFile(path, atomically: true)
    }

    public func write(string: String) -> Bool {
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
            return write(data)
        }

        return false
    }
}


// MARK: Traversing

extension Path {
    public func children(directories directories: Bool = true) throws -> [Path] {
        let manager = NSFileManager()
        let contents = try manager.contentsOfDirectoryAtPath(path)
        let paths = contents.map {
            self + Path($0)
        }

        if directories {
            return paths
        }

        return paths.filter { !$0.isDirectory }
    }
}


// MARK: Equatable

extension Path : Equatable {}

/** Determines if two paths are identical
:note: The comparison is string-based. Be aware that two different paths (foo.txt and ./foo.txt) can refer to the same file.
*/
public func ==(lhs: Path, rhs: Path) -> Bool {
    return lhs.path == rhs.path
}


// MARK: Operators

/// Appends a Path fragment to another Path to produce a new Path
public func +(lhs: Path, rhs: Path) -> Path {
    switch (lhs.path.hasSuffix(Path.separator), rhs.path.hasPrefix(Path.separator)) {
        case (true, true):
            return Path("\(lhs.path)\(rhs.path.substringFromIndex(rhs.path.startIndex.successor()))")
        case (false, false):
            return Path("\(lhs.path)\(Path.separator)\(rhs.path)")
        default:
            return Path("\(lhs.path)\(rhs.path)")
    }
}

