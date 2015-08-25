// PathKit - Effortless path operations

import Foundation

/// Represents a filesystem path.
public struct Path {
    /// The character used by the OS to separate two path elements
    public static let separator = "/"

    /// The underlying string representation
    internal var path: String

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
    /// Test whether a path is absolute.
    ///
    /// - Returns: `true` iff the path begings with a slash
    ///
    public var isAbsolute: Bool {
        return path.hasPrefix(Path.separator)
    }

    /// Test whether a path is relative.
    ///
    /// - Returns: `true` iff a path is relative (not absolute)
    ///
    public var isRelative: Bool {
        return !isAbsolute
    }

    /// Concatenates relative paths to the current directory and derives the normalized path
    ///
    /// - Returns: the absolute path in the actual filesystem
    ///
    public func absolute() -> Path {
        if isAbsolute {
            return normalize()
        }

        return (Path.current + self).normalize()
    }

    /// Normalizes the path, this cleans up redundant ".." and ".", double slashes
    /// and resolves "~".
    ///
    /// - Returns: a new path made by removing extraneous path components from the underlying String
    ///   representation.
    ///
    public func normalize() -> Path {
        return Path((self.path as NSString).stringByStandardizingPath)
    }
}


// MARK: Path Components

extension Path {
    /// The last path component
    ///
    /// - Returns: the last path component
    ///
    public var lastComponent: String {
        return (path as NSString).lastPathComponent
    }
    
    /// The last path component without file extension
    ///
    /// - Note: This returns "." for "..".
    ///
    /// - Returns: the last path component without file extension
    ///
    public var lastComponentWithoutExtension: String {
        return (lastComponent as NSString).stringByDeletingPathExtension
    }
    
    /// Splits the string representation on the directory separator.
    /// Absolute paths remain the leading slash as first component.
    ///
    /// - Returns: all path components
    ///
    public var components: [String] {
        return (path as NSString).pathComponents
    }
    
    /// The file extension behind the last dot of the last component.
    ///
    /// - Returns: the file extension
    ///
    public var `extension`: String {
        return (path as NSString).pathExtension
    }
}


// MARK: File Info

extension Path {
    /// Test whether a file or directory exists at a specified path
    ///
    /// - Returns: `false` iff the path doesn't exist on disk or its existence could not be
    ///   determined
    ///
    public var exists: Bool {
        return Path.fileManager.fileExistsAtPath(self.path)
    }

    /// Test whether a path is a directory.
    ///
    /// - Returns: `true` if the path is a directory or a symbolic link that points to a directory;
    ///   `false` if the path is not a directory or the path doesn't exist on disk or its existence
    ///   could not be determined
    ///
    public var isDirectory: Bool {
        var directory = ObjCBool(false)
        return Path.fileManager.fileExistsAtPath(normalize().path, isDirectory: &directory) && directory.boolValue
    }
}


// MARK: File Manipulation

extension Path {
    /// Delete the file or directory.
    ///
    /// - Note: If the path specifies a directory, the contents of that directory are recursively
    ///   removed.
    ///
    public func delete() throws -> () {
        try Path.fileManager.removeItemAtPath(self.path)
    }

    /// Move the file or directory to a new location synchronously.
    ///
    /// - Parameter destination: The new path. This path must include the name of the file or
    ///   directory in its new location.
    ///
    public func move(destination: Path) throws -> () {
        try Path.fileManager.moveItemAtPath(self.path, toPath: destination.path)
    }
}


// MARK: Current Directory

extension Path {
    /// The current working directory of the process
    ///
    /// - Returns: the current working directory of the process
    ///
    public static var current: Path {
        get {
            return self.init(Path.fileManager.currentDirectoryPath)
        }
        set {
            Path.fileManager.changeCurrentDirectoryPath(newValue.description)
        }
    }
    
    /// Changes the current working directory of the process to the path during the execution of the
    /// given block.
    ///
    /// - Note: The original working directory is restored when the block exits.
    /// - Parameter closure: A closure to be executed while the current directory is configured to
    ///   the path.
    ///
    public func chdir(closure: () -> ()) {
        let previous = Path.current
        Path.current = self
        closure()
        Path.current = previous
    }
}


// MARK: Contents

extension Path {
    /// Reads the file.
    ///
    /// - Returns: the contents of the file at the specified path.
    ///
    public func read() -> NSData? {
        return Path.fileManager.contentsAtPath(self.path)
    }

    /// Reads the file contents and encoded its bytes to string applying the given encoding.
    ///
    /// - Parameter encoding: the encoding which should be used to decode the data.
    ///   (by default: `NSUTF8StringEncoding`)
    ///
    /// - Returns: the contents of the file at the specified path as string.
    ///
    public func read(encoding: NSStringEncoding = NSUTF8StringEncoding) -> String? {
        if let data: NSData = read() {
            return NSString(data: data, encoding: encoding) as? String
        }

        return nil
    }

    /// Write a file.
    ///
    /// - Note: Works atomically: the data is written to a backup file, and then — assuming no
    ///   errors occur — the backup file is renamed to the name specified by path.
    ///
    /// - Parameter data: the contents to write to file.
    ///
    public func write(data: NSData) -> Bool {
        return data.writeToFile(normalize().path, atomically: true)
    }

    /// Reads the file.
    ///
    /// - Note: Works atomically: the data is written to a backup file, and then — assuming no
    ///   errors occur — the backup file is renamed to the name specified by path.
    ///
    /// - Parameter string: the string to write to file.
    ///
    /// - Parameter encoding: the encoding which should be used to represent the string as bytes.
    ///   (by default: `NSUTF8StringEncoding`)
    ///
    /// - Returns: the contents of the file at the specified path as string.
    ///
    public func write(string: String, encoding: NSStringEncoding = NSUTF8StringEncoding) -> Bool {
        if let data = string.dataUsingEncoding(encoding, allowLossyConversion: true) {
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

/// Determines if two paths are identical
///
/// - Note: The comparison is string-based. Be aware that two different paths (foo.txt and
///   ./foo.txt) can refer to the same file.
///
public func ==(lhs: Path, rhs: Path) -> Bool {
    return lhs.path == rhs.path
}


// MARK: Pattern Matching

/// Implements pattern-matching for paths.
///
/// - Returns: `true` iff one of the following conditions is true:
///     - the paths are equal (based on `Path`'s `Equatable` implementation)
///     - the paths can be normalized to equal Paths.
///
public func ~=(lhs: Path, rhs: Path) -> Bool {
    return lhs == rhs
        || lhs.normalize() == rhs.normalize()
}


// MARK: Comparable

extension Path : Comparable {}

/// Defines a strict total order over Paths based on their underlying string representation.
public func <(lhs: Path, rhs: Path) -> Bool {
    return lhs.path < rhs.path
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

