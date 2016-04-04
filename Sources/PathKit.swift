// PathKit - Effortless path operations

#if os(Linux)
import Glibc

let system_glob = Glibc.glob
#else
import Darwin

let system_glob = Darwin.glob
#endif

import Foundation

#if !swift(>=3.0)
  typealias Collection = CollectionType
  typealias Sequence = SequenceType
  typealias IteratorProtocol = GeneratorType
#endif


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
  #if !swift(>=3.0)
  public init<S : Collection where S.Generator.Element == String>(components: S) {
    if components.isEmpty {
      path = "."
    } else if components.first == Path.separator && components.count > 1 {
      let p = components.joinWithSeparator(Path.separator)
#if os(Linux)
      let index = p.startIndex.distanceTo(p.startIndex.successor())
      path = NSString(string: p).substringFromIndex(index)
#else
      path = p.substringFromIndex(p.startIndex.successor())
#endif

    } else {
      path = components.joinWithSeparator(Path.separator)
    }
    }
  #else
  public init<S : Collection where S.Iterator.Element == String>(components: S) {
    if components.isEmpty {
      path = "."
    } else if components.first == Path.separator && components.count > 1 {
      let p = components.joined(separator: Path.separator)
#if os(Linux)
      let index = p.startIndex.distance( to: p.startIndex.successor())
      path = NSString(string: p).substringFromIndex(index)
#else
      path = p.substring(from: p.startIndex.successor())
#endif

    } else {
      path = components.joined(separator: Path.separator)
    }
  }

  #endif
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
    #if !swift(>=3.0)
    return Path(NSString(string: self.path).stringByStandardizingPath)
    #else
      #if os(Linux)
      return Path(NSString(string: self.path).stringByStandardizingPath)
      #else
      return Path(NSString(string: self.path).standardizingPath)
      #endif
    #endif
  }

  /// De-normalizes the path, by replacing the current user home directory with "~".
  ///
  /// - Returns: a new path made by removing extraneous path components from the underlying String
  ///   representation.
  ///
  public func abbreviate() -> Path {
#if os(Linux)
    // TODO: actually de-normalize the path
    return self
#else
    #if !swift(>=3.0)
    return Path(NSString(string: self.path).stringByAbbreviatingWithTildeInPath)
    #else
    return Path(NSString(string: self.path).abbreviatingWithTildeInPath)
    #endif
#endif
  }

  /// Returns the path of the item pointed to by a symbolic link.
  ///
  /// - Returns: the path of directory or file to which the symbolic link refers
  ///
  public func symlinkDestination() throws -> Path {
    #if !swift(>=3.0)
    let symlinkDestination = try Path.fileManager.destinationOfSymbolicLinkAtPath(path)
    #else
      #if os(Linux)
      let symlinkDestination = try Path.fileManager.destinationOfSymbolicLinkAtPath(path)
      #else
      let symlinkDestination = try Path.fileManager.destinationOfSymbolicLink(atPath:path)
      #endif
    #endif
    let symlinkPath = Path(symlinkDestination)
    if symlinkPath.isRelative {
      return self + ".." + symlinkPath
    } else {
      return symlinkPath
    }
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
    #if !swift(>=3.0)
    return NSString(string: lastComponent).stringByDeletingPathExtension
    #else
      #if os(Linux)
      return NSString(string: lastComponent).stringByDeletingPathExtension
      #else
      return NSString(string: lastComponent).deletingPathExtension
      #endif
    #endif
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
    if pathExtension.isEmpty {
      return nil
    }

    return pathExtension
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
    #if !swift(>=3.0)
    return Path.fileManager.fileExistsAtPath(self.path)
    #else
      #if os(Linux)
      return Path.fileManager.fileExistsAtPath(self.path)
      #else
      return Path.fileManager.fileExists(atPath:self.path)
      #endif
    #endif
  }

  /// Test whether a path is a directory.
  ///
  /// - Returns: `true` if the path is a directory or a symbolic link that points to a directory;
  ///   `false` if the path is not a directory or the path doesn't exist on disk or its existence
  ///   could not be determined
  ///
  public var isDirectory: Bool {
    var directory = ObjCBool(false)
    #if !swift(>=3.0)
    guard Path.fileManager.fileExistsAtPath(normalize().path, isDirectory: &directory) else {
      return false
    }
    #else
      #if os(Linux)
      guard Path.fileManager.fileExistsAtPath(normalize().path, isDirectory: &directory) else {
        return false
      }
      #else
      guard Path.fileManager.fileExists(atPath: normalize().path, isDirectory: &directory) else {
        return false
      }
      #endif
    #endif
    return directory.boolValue
  }

  /// Test whether a path is a regular file.
  ///
  /// - Returns: `true` if the path is neither a directory nor a symbolic link that points to a
  ///   directory; `false` if the path is a directory or a symbolic link that points to a
  ///   directory or the path doesn't exist on disk or its existence
  ///   could not be determined
  ///
  public var isFile: Bool {
    var directory = ObjCBool(false)
    #if !swift(>=3.0)
    guard Path.fileManager.fileExistsAtPath(normalize().path, isDirectory: &directory) else {
      return false
    }
    #else
      #if os(Linux)
      guard Path.fileManager.fileExistsAtPath(normalize().path, isDirectory: &directory) else {
        return false
      }
      #else
      guard Path.fileManager.fileExists(atPath: normalize().path, isDirectory: &directory) else {
        return false
      }
      #endif
    #endif
    return !directory.boolValue
  }

  /// Test whether a path is a symbolic link.
  ///
  /// - Returns: `true` if the path is a symbolic link; `false` if the path doesn't exist on disk
  ///   or its existence could not be determined
  ///
  public var isSymlink: Bool {
    do {
      #if !swift(>=3.0)
      let _ = try Path.fileManager.destinationOfSymbolicLinkAtPath(path)
      #else
        #if os(Linux)
        let _ = try Path.fileManager.destinationOfSymbolicLinkAtPath(path)
        #else
        let _ = try Path.fileManager.destinationOfSymbolicLink(atPath: path)
        #endif
      #endif
      return true
    } catch {
      return false
    }
  }

  /// Test whether a path is readable
  ///
  /// - Returns: `true` if the current process has read privileges for the file at path;
  ///   otherwise `false` if the process does not have read privileges or the existence of the
  ///   file could not be determined.
  ///
  public var isReadable: Bool {
    #if !swift(>=3.0)
    return Path.fileManager.isReadableFileAtPath(self.path)
    #else
      #if os(Linux)
      return Path.fileManager.isReadableFileAtPath(self.path)
      #else
      return Path.fileManager.isReadableFile(atPath: self.path)
      #endif
    #endif
  }

  /// Test whether a path is writeable
  ///
  /// - Returns: `true` if the current process has write privileges for the file at path;
  ///   otherwise `false` if the process does not have write privileges or the existence of the
  ///   file could not be determined.
  ///
  public var isWritable: Bool {
    #if !swift(>=3.0)
    return Path.fileManager.isWritableFileAtPath(self.path)
    #else
      #if os(Linux)
      return Path.fileManager.isWritableFileAtPath(self.path)
      #else
      return Path.fileManager.isWritableFile(atPath: self.path)
      #endif
    #endif
  }

  /// Test whether a path is executable
  ///
  /// - Returns: `true` if the current process has execute privileges for the file at path;
  ///   otherwise `false` if the process does not have execute privileges or the existence of the
  ///   file could not be determined.
  ///
  public var isExecutable: Bool {
    #if !swift(>=3.0)
    return Path.fileManager.isExecutableFileAtPath(self.path)
    #else
      #if os(Linux)
      return Path.fileManager.isExecutableFileAtPath(self.path)
      #else
      return Path.fileManager.isExecutableFile(atPath: self.path)
      #endif
    #endif
  }

  /// Test whether a path is deletable
  ///
  /// - Returns: `true` if the current process has delete privileges for the file at path;
  ///   otherwise `false` if the process does not have delete privileges or the existence of the
  ///   file could not be determined.
  ///
  public var isDeletable: Bool {
    #if !swift(>=3.0)
    return Path.fileManager.isDeletableFileAtPath(self.path)
    #else
      #if os(Linux)
      return Path.fileManager.isDeletableFileAtPath(self.path)
      #else
      return Path.fileManager.isDeletableFile(atPath: self.path)
      #endif
    #endif
  }
}


// MARK: File Manipulation

extension Path {
  /// Create the directory.
  ///
  /// - Note: This method fails if any of the intermediate parent directories does not exist.
  ///   This method also fails if any of the intermediate path elements corresponds to a file and
  ///   not a directory.
  ///
  public func mkdir() throws -> () {
    #if !swift(>=3.0)
    try Path.fileManager.createDirectoryAtPath(self.path, withIntermediateDirectories: false, attributes: nil)
    #else
      #if os(Linux)
      try Path.fileManager.createDirectoryAtPath(self.path, withIntermediateDirectories: false, attributes: nil)
      #else
      try Path.fileManager.createDirectory(atPath: self.path, withIntermediateDirectories: false, attributes: nil)
      #endif
    #endif
  }

  /// Create the directory and any intermediate parent directories that do not exist.
  ///
  /// - Note: This method fails if any of the intermediate path elements corresponds to a file and
  ///   not a directory.
  ///
  public func mkpath() throws -> () {
    #if !swift(>=3.0)
    try Path.fileManager.createDirectoryAtPath(self.path, withIntermediateDirectories: true, attributes: nil)
    #else
      #if os(Linux)
      try Path.fileManager.createDirectoryAtPath(self.path, withIntermediateDirectories: true, attributes: nil)
      #else
      try Path.fileManager.createDirectory(atPath: self.path, withIntermediateDirectories: true, attributes: nil)
      #endif
    #endif
  }

  /// Delete the file or directory.
  ///
  /// - Note: If the path specifies a directory, the contents of that directory are recursively
  ///   removed.
  ///
  public func delete() throws -> () {
    #if !swift(>=3.0)
    try Path.fileManager.removeItemAtPath(self.path)
    #else
      #if os(Linux)
      try Path.fileManager.removeItemAtPath(self.path)
      #else
      try Path.fileManager.removeItem(atPath: self.path)
      #endif
    #endif
  }

  /// Move the file or directory to a new location synchronously.
  ///
  /// - Parameter destination: The new path. This path must include the name of the file or
  ///   directory in its new location.
  ///
  public func move(destination: Path) throws -> () {
    #if !swift(>=3.0)
    try Path.fileManager.moveItemAtPath(self.path, toPath: destination.path)
    #else
      #if os(Linux)
      try Path.fileManager.moveItemAtPath(self.path, toPath: destination.path)
      #else
      try Path.fileManager.moveItem(atPath: self.path, toPath: destination.path)
      #endif
    #endif
  }

  /// Copy the file or directory to a new location synchronously.
  ///
  /// - Parameter destination: The new path. This path must include the name of the file or
  ///   directory in its new location.
  ///
  public func copy(destination: Path) throws -> () {
    #if !swift(>=3.0)
    try Path.fileManager.copyItemAtPath(self.path, toPath: destination.path)
    #else
      #if os(Linux)
      try Path.fileManager.copyItemAtPath(self.path, toPath: destination.path)
      #else
      try Path.fileManager.copyItem(atPath: self.path, toPath: destination.path)
      #endif
    #endif
  }

  /// Creates a hard link at a new destination.
  ///
  /// - Parameter destination: The location where the link will be created.
  ///
  public func link(destination: Path) throws -> () {
    #if !swift(>=3.0)
    try Path.fileManager.linkItemAtPath(self.path, toPath: destination.path)
    #else
      #if os(Linux)
      try Path.fileManager.linkItemAtPath(self.path, toPath: destination.path)
      #else
      try Path.fileManager.linkItem(atPath: self.path, toPath: destination.path)
      #endif
    #endif
  }

  /// Creates a symbolic link at a new destination.
  ///
  /// - Parameter destintation: The location where the link will be created.
  ///
  public func symlink(destination: Path) throws -> () {
    #if !swift(>=3.0)
    try Path.fileManager.createSymbolicLinkAtPath(self.path, withDestinationPath: destination.path)
    #else
      #if os(Linux)
      try Path.fileManager.createSymbolicLinkAtPath(self.path, withDestinationPath: destination.path)
      #else
      try Path.fileManager.createSymbolicLink(atPath: self.path, withDestinationPath: destination.path)
      #endif
    #endif
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
  /// - Note: The original working directory is restored when the block returns or throws.
  /// - Parameter closure: A closure to be executed while the current directory is configured to
  ///   the path.
  ///
  public func chdir(@noescape closure: () throws -> ()) rethrows {
    let previous = Path.current
    Path.current = self
    defer { Path.current = previous }
    try closure()
  }
}


// MARK: Temporary

extension Path {
  /// - Returns: the path to either the user’s or application’s home directory,
  ///   depending on the platform.
  ///
  public static var home: Path {
#if os(Linux)
    return Path(NSProcessInfo.processInfo().environment["HOME"] ?? "/")
#else
    return Path(NSHomeDirectory())
#endif
  }

  /// - Returns: the path of the temporary directory for the current user.
  ///
  public static var temporary: Path {
#if os(Linux)
    return Path(NSProcessInfo.processInfo().environment["TMP"] ?? "/tmp")
#else
    return Path(NSTemporaryDirectory())
#endif
  }

  /// - Returns: the path of a temporary directory unique for the process.
  /// - Note: Based on `NSProcessInfo.globallyUniqueString`.
  ///
  public static func processUniqueTemporary() throws -> Path {
    let path = temporary + NSProcessInfo.processInfo().globallyUniqueString
    if !path.exists {
      try path.mkdir()
    }
    return path
  }

  /// - Returns: the path of a temporary directory unique for each call.
  /// - Note: Based on `NSUUID`.
  ///
  public static func uniqueTemporary() throws -> Path {
    #if !swift(>=3.0)
    let path = try processUniqueTemporary() + NSUUID().UUIDString
    #else
      #if os(Linux)
      let path = try processUniqueTemporary() + NSUUID().UUIDString
      #else
      let path = try processUniqueTemporary() + NSUUID().uuidString
      #endif
    #endif
    try path.mkdir()
    return path
  }
}


// MARK: Contents

extension Path {
  /// Reads the file.
  ///
  /// - Returns: the contents of the file at the specified path.
  ///
  public func read() throws -> NSData {
    return try NSData(contentsOfFile: path, options: NSDataReadingOptions(rawValue: 0))
  }

  /// Reads the file contents and encoded its bytes to string applying the given encoding.
  ///
  /// - Parameter encoding: the encoding which should be used to decode the data.
  ///   (by default: `NSUTF8StringEncoding`)
  ///
  /// - Returns: the contents of the file at the specified path as string.
  ///
  public func read(encoding: NSStringEncoding = NSUTF8StringEncoding) throws -> String {
    #if !swift(>=3.0)
    return try NSString(contentsOfFile: path, encoding: encoding).substringFromIndex(0) as String
    #else
      #if os(Linux)
      return try NSString(contentsOfFile: path, encoding: encoding).substringFromIndex(0) as String
      #else
      return try NSString(contentsOfFile: path, encoding: encoding).substring(from:0) as String
      #endif
    #endif
  }

  /// Write a file.
  ///
  /// - Note: Works atomically: the data is written to a backup file, and then — assuming no
  ///   errors occur — the backup file is renamed to the name specified by path.
  ///
  /// - Parameter data: the contents to write to file.
  ///
  public func write(data: NSData) throws {
    #if !swift(>=3.0)
    try data.writeToFile(normalize().path, options: .DataWritingAtomic)
    #else
      #if os(Linux)
      try data.writeToFile(normalize().path, options: .DataWritingAtomic)
      #else
      try data.write(toFile:normalize().path, options: .dataWritingAtomic)
      #endif
    #endif
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
  public func write(string: String, encoding: NSStringEncoding = NSUTF8StringEncoding) throws {
    #if !swift(>=3.0)
    try NSString(string: string).writeToFile(normalize().path, atomically: true, encoding: encoding)
    #else
      #if os(Linux)
      try NSString(string: string).writeToFile(normalize().path, atomically: true, encoding: encoding)
      #else
      try NSString(string: string).write(toFile:normalize().path, atomically: true, encoding: encoding)
      #endif
    #endif
  }
}


// MARK: Traversing

extension Path {
  /// Get the parent directory
  ///
  /// - Returns: the normalized path of the parent directory
  ///
  public func parent() -> Path {
    return self + ".."
  }

  /// Performs a shallow enumeration in a directory
  ///
  /// - Returns: paths to all files, directories and symbolic links contained in the directory
  ///
  public func children() throws -> [Path] {
    #if !swift(>=3.0)
    return try Path.fileManager.contentsOfDirectoryAtPath(path).map {
      self + Path($0)
    }
    #else
      #if os(Linux)
      return try Path.fileManager.contentsOfDirectoryAtPath(path).map {
        self + Path($0)
      }
      #else
      return try Path.fileManager.contentsOfDirectory(atPath:path).map {
        self + Path($0)
      }
      #endif
    #endif

  }

  /// Performs a deep enumeration in a directory
  ///
  /// - Returns: paths to all files, directories and symbolic links contained in the directory or
  ///   any subdirectory.
  ///
  public func recursiveChildren() throws -> [Path] {
    #if !swift(>=3.0)
    return try Path.fileManager.subpathsOfDirectoryAtPath(path).map {
      self + Path($0)
    }
    #else
      #if os(Linux)
      return try Path.fileManager.subpathsOfDirectoryAtPath(path).map {
        self + Path($0)
      }
      #else
      return try Path.fileManager.subpathsOfDirectory(atPath:path).map {
        self + Path($0)
      }
      #endif
    #endif
  }
}


// MARK: Globbing

extension Path {
  public static func glob(pattern: String) -> [Path] {
    var gt = glob_t()
    let cPattern = strdup(pattern)
    defer {
      globfree(&gt)
      free(cPattern)
    }

    let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
    if system_glob(cPattern, flags, nil, &gt) == 0 {
#if os(Linux)
      let matchc = gt.gl_pathc
#else
      let matchc = gt.gl_matchc
#endif
      #if !swift(>=3.0)
      return (0..<Int(matchc)).flatMap { index in
        if let path = String.fromCString(gt.gl_pathv[index]) {
          return Path(path)
        }

        return nil
      }
      #else
        return (0..<Int(matchc)).flatMap { index in
          if let path = String(validatingUTF8: gt.gl_pathv[index]) {
            return Path(path)
          }

        return nil
      }
    #endif
    }

    // GLOB_NOMATCH
    return []
  }

  public func glob(pattern: String) -> [Path] {
    return Path.glob((self + pattern).description)
  }
}


// MARK: SequenceType

extension Path : Sequence {
  /// Enumerates the contents of a directory, returning the paths of all files and directories
  /// contained within that directory. These paths are relative to the directory.
  public struct DirectoryEnumerator : IteratorProtocol {
    public typealias Element = Path

    let path: Path
    let directoryEnumerator: NSDirectoryEnumerator

    init(path: Path) {
      self.path = path
      #if !swift(>=3.0)
      self.directoryEnumerator = Path.fileManager.enumeratorAtPath(path.path)!
      #else
        #if os(Linux)
        self.directoryEnumerator = Path.fileManager.enumeratorAtPath(path.path)!
        #else
        self.directoryEnumerator = Path.fileManager.enumerator(atPath:path.path)!
        #endif
      #endif
    }

    public func next() -> Path? {
      if let next = directoryEnumerator.nextObject() as! String? {
        return path + next
      }
      return nil
    }

    /// Skip recursion into the most recently obtained subdirectory.
    public func skipDescendants() {
      directoryEnumerator.skipDescendants()
    }
  }

  /// Perform a deep enumeration of a directory.
  ///
  /// - Returns: a directory enumerator that can be used to perform a deep enumeration of the
  ///   directory.
  ///
  #if !swift(>=3.0)
  public func generate() -> DirectoryEnumerator {
    return DirectoryEnumerator(path: self)
  }
  #else
  public func makeIterator() -> DirectoryEnumerator {
    return DirectoryEnumerator(path: self)
  }
  #endif
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
  return lhs.path + rhs.path
}

/// Appends a String fragment to another Path to produce a new Path
public func +(lhs: Path, rhs: String) -> Path {
  return lhs.path + rhs
}

/// Appends a String fragment to another String to produce a new Path
internal func +(lhs: String, rhs: String) -> Path {
  if rhs.hasPrefix(Path.separator) {
    // Absolute paths replace relative paths
    return Path(rhs)
  } else {
    var lSlice = NSString(string: lhs).pathComponents.fullSlice
    var rSlice = NSString(string: rhs).pathComponents.fullSlice

    // Get rid of trailing "/" at the left side
    if lSlice.count > 1 && lSlice.last == Path.separator {
      lSlice.removeLast()
    }

    // Advance after the first relevant "."
    lSlice = lSlice.filter { $0 != "." }.fullSlice
    rSlice = rSlice.filter { $0 != "." }.fullSlice

    // Eats up trailing components of the left and leading ".." of the right side
    while lSlice.last != ".." && rSlice.first == ".." {
      if (lSlice.count > 1 || lSlice.first != Path.separator) && !lSlice.isEmpty {
        // A leading "/" is never popped
        lSlice.removeLast()
      }
      if !rSlice.isEmpty {
        rSlice.removeFirst()
      }

      switch (lSlice.isEmpty, rSlice.isEmpty) {
      case (true, _):
        break
      case (_, true):
        break
      default:
        continue
      }
    }

    return Path(components: lSlice + rSlice)
  }
}

extension Array {
  var fullSlice: ArraySlice<Element> {
    return self[0..<self.endIndex]
  }
}
