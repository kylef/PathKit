// PathKit - Effortless path operations

import Foundation

/// Represents a filesystem path.
public struct Path {
    /// The character used by the OS to separate two path elements
    public static let separator = "/"

    /// The underlying string representation
    internal var path: String

    internal static var fileManager = FileManager.default

    internal var fileSystemInfo: FileSystemInfo = DefaultFileSystemInfo()

    // MARK: Init

    public init() {
        self.path = ""
    }

    /// Create a Path from a given String
    public init(_ path: String) {
        self.path = path
    }

    /// Create a Path by joining multiple path components together
    public init<S: Collection>(components: S) where S.Iterator.Element == String {
        if components.isEmpty {
            path = "."
        } else if components.first == Path.separator && components.count > 1 {
            let p = components.joined(separator: Path.separator)
            path = p.substring(from: p.characters.index(after: p.startIndex))
        } else {
            path = components.joined(separator: Path.separator)
        }
    }
}

// MARK: StringLiteralConvertible

extension Path : ExpressibleByStringLiteral {
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

// MARK: Conversion

extension Path {
    public var string: String {
        return self.path
    }

    public var url: URL {
        return URL(fileURLWithPath: path)
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
    public var absolute: Path {
        guard !isAbsolute else { return normalize }

        let expandedPath = Path(NSString(string: self.path).expandingTildeInPath)
        guard !expandedPath.isAbsolute else { return expandedPath.normalize }

        return (Path.current + self).normalize
    }

    /// Normalizes the path, this cleans up redundant ".." and ".", double slashes
    /// and resolves "~".
    ///
    /// - Returns: a new path made by removing extraneous path components from the underlying String
    ///   representation.
    ///
    public var normalize: Path {
        return Path(NSString(string: self.path).standardizingPath)
    }

    /// De-normalizes the path, by replacing the current user home directory with "~".
    ///
    /// - Returns: a new path made by removing extraneous path components from the underlying String
    ///   representation.
    ///
    public var abbreviate: Path {
        let rangeOptions: String.CompareOptions = fileSystemInfo.isFSCaseSensitiveAt(path: self) ?
            [.anchored] : [.anchored, .caseInsensitive]
        let home = Path.home.string
        guard let homeRange = self.path.range(of: home, options: rangeOptions) else { return self }
        let withoutHome = Path(self.path.replacingCharacters(in: homeRange, with: ""))

        if withoutHome.path.isEmpty || withoutHome.path == Path.separator {
            return Path("~")
        } else if withoutHome.isAbsolute {
            return Path("~" + withoutHome.path)
        } else {
            return Path("~") + withoutHome.path
        }
    }

    /// Returns the path of the item pointed to by a symbolic link.
    ///
    /// - Returns: the path of directory or file to which the symbolic link refers
    ///
    public func symlinkDestination() throws -> Path {
        let symlinkDestination = try Path.fileManager.destinationOfSymbolicLink(atPath: path)
        let symlinkPath = Path(symlinkDestination)
        if symlinkPath.isRelative {
            return self + ".." + symlinkPath
        } else {
            return symlinkPath
        }
    }
}

internal protocol FileSystemInfo {
    func isFSCaseSensitiveAt(path: Path) -> Bool
}

internal struct DefaultFileSystemInfo: FileSystemInfo {
    func isFSCaseSensitiveAt(path: Path) -> Bool {
        #if os(Linux)
            // URL resourceValues(forKeys:) is not supported on non-darwin platforms...
            // But we can (fairly?) safely assume for now that the Linux FS is case sensitive.
            // TODO: refactor when/if resourceValues is available, or look into using something
            // like stat or pathconf to determine if the mountpoint is case sensitive.
            return true
        #else
            var isCaseSensitive = false
            // Calling resourceValues will fail if the path does not exist on the filesystem, which
            // makes sense, but means we can only guarantee the return value is correct if the
            // path actually exists.
            if let resourceValues = try? path.url.resourceValues(forKeys: [.volumeSupportsCaseSensitiveNamesKey]) {
                isCaseSensitive = resourceValues.volumeSupportsCaseSensitiveNames ?? isCaseSensitive
            }
            return isCaseSensitive
        #endif
    }
}

// MARK: Path Components

extension Path {
    /// The last path component
    ///
    /// - Returns: the last path component
    ///
    public var lastComponent: String {
        return NSString(string: path).lastPathComponent
    }

    /// The last path component without file extension
    ///
    /// - Note: This returns "." for "..".
    ///
    /// - Returns: the last path component without file extension
    ///
    public var lastComponentWithoutExtension: String {
        return NSString(string: lastComponent).deletingPathExtension
    }

    /// Splits the string representation on the directory separator.
    /// Absolute paths remain the leading slash as first component.
    ///
    /// - Returns: all path components
    ///
    public var components: [String] {
        return NSString(string: path).pathComponents
    }

    /// The file extension behind the last dot of the last component.
    ///
    /// - Returns: the file extension
    ///
    public var `extension`: String? {
        let pathExtension = NSString(string: path).pathExtension
        guard !pathExtension.isEmpty else { return nil }

        return pathExtension
    }
}
