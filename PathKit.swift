// PathKit - Effortless path operations

import Foundation

/// Represents a filesystem path.
public struct Path : Equatable, Printable, StringLiteralConvertible, ExtendedGraphemeClusterLiteralConvertible, UnicodeScalarLiteralConvertible {
    public static let separator = "/"

    private var path:String

    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public static func convertFromExtendedGraphemeClusterLiteral(value: ExtendedGraphemeClusterLiteralType) -> Path {
        return self(value)
    }

    public typealias UnicodeScalarLiteralType = StringLiteralType
    public static func convertFromUnicodeScalarLiteral(value: UnicodeScalarLiteralType) -> Path {
        return self(value)
    }

    public static func convertFromStringLiteral(value: StringLiteralType) -> Path {
        return self(value)
    }

    // Returns the current working directory
    public static func current() -> Path {
        return self(NSFileManager().currentDirectoryPath)
    }

    // MARK: Init

    init() {
        self.path = ""
    }

    init(_ path:String) {
        self.path = path
    }

    init(components:[String]) {
        path = join(Path.separator, components)
    }

    // MARK: Printable

    public var description:String {
        return self.path
    }

    /** Method for testing whether a path is absolute.
    :return: true if the pathname begings with a slash
    */
    func isAbsolute() -> Bool {
        return path.hasPrefix(Path.separator)
    }

    /// Returns true if a path is relative (not absolute)
    func isRelative() -> Bool {
        return !isAbsolute()
    }

    /// Returns the absolute path in the actual filesystem
    func absolute() -> Path {
        if isAbsolute() {
            return normalize()
        }

        return (Path.current() + self).normalize()
    }

    /// Normalizes the path, this clenas up redundant ".." and "." and double slashes
    func normalize() -> Path {
        return Path(self.path.stringByStandardizingPath)
    }

    /// Returns whether a file or directory exists at a specified path
    func exists() -> Bool {
        return NSFileManager().fileExistsAtPath(self.path)
    }

    func delete() -> Bool {
        return NSFileManager().removeItemAtPath(self.path, error: nil)
    }

    func move(destination:Path) -> Bool {
        return NSFileManager().moveItemAtPath(self.path, toPath: destination.path, error: nil)
    }

}

public func ==(lhs: Path, rhs: Path) -> Bool {
    return lhs.path == rhs.path
}

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

