import Foundation

// MARK: File Info

extension Path {
    /**
     Test whether a file or directory exists at a specified path

     - Note: `false` if the path doesn't exist on disk or its existence could not be
       determined
    */
    public var exists: Bool {
        return Path.fileManager.fileExists(atPath: self.path)
    }

    /**
     Test whether a path is a directory.

     - Note: `true` if the path is a directory or a symbolic link that points to a directory;
       `false` if the path is not a directory or the path doesn't exist on disk or its existence
       could not be determined
    */
    public var isDirectory: Bool {
        var directory = ObjCBool(false)
        guard Path.fileManager.fileExists(atPath: normalized.path, isDirectory: &directory) else { return false }
        #if os(Linux)
            return directory
        #else
            return directory.boolValue
        #endif
    }

    /**
     Test whether a path is a regular file.

     - Note: `true` if the path is neither a directory nor a symbolic link that points to a
       directory; `false` if the path is a directory or a symbolic link that points to a
       directory or the path doesn't exist on disk or its existence
       could not be determined
    */
    public var isFile: Bool {
        var directory = ObjCBool(false)
        guard Path.fileManager.fileExists(atPath: normalized.path, isDirectory: &directory) else { return false }
        #if os(Linux)
            return !directory
        #else
            return !directory.boolValue
        #endif
    }

    /**
     Test whether a path is a symbolic link.

     - Note: `true` if the path is a symbolic link; `false` if the path doesn't exist on disk
       or its existence could not be determined
    */
    public var isSymlink: Bool {
        guard let _ = try? Path.fileManager.destinationOfSymbolicLink(atPath: path) else { return false }
        return true
    }

    /**
     Test whether a path is readable

     - Note: `true` if the current process has read privileges for the file at path;
       otherwise `false` if the process does not have read privileges or the existence of the
       file could not be determined.
    */
    public var isReadable: Bool {
        return Path.fileManager.isReadableFile(atPath: self.path)
    }

    /**
     Test whether a path is writeable

     - Note: `true` if the current process has write privileges for the file at path;
       otherwise `false` if the process does not have write privileges or the existence of the
       file could not be determined.
    */
    public var isWritable: Bool {
        return Path.fileManager.isWritableFile(atPath: self.path)
    }

    /**
     Test whether a path is executable

     - Note: `true` if the current process has execute privileges for the file at path;
       otherwise `false` if the process does not have execute privileges or the existence of the
       file could not be determined.
    */
    public var isExecutable: Bool {
        return Path.fileManager.isExecutableFile(atPath: self.path)
    }

    /**
     Test whether a path is deletable

     - Note: `true` if the current process has delete privileges for the file at path;
       otherwise `false` if the process does not have delete privileges or the existence of the
       file could not be determined.
    */
    public var isDeletable: Bool {
        return Path.fileManager.isDeletableFile(atPath: self.path)
    }
}

// MARK: File Manipulation

extension Path {
    /**
     Delete the file or directory.

     - Note: If the path specifies a directory, the contents of that directory are recursively
       removed.
    */
    public func delete() throws {
        try Path.fileManager.removeItem(atPath: self.path)
    }

    /**
     Move the file or directory to a new location synchronously.

     - Parameter destination: The new path. This path must include the name of the file or
       directory in its new location.
    */
    public func move(_ destination: Path) throws {
        try Path.fileManager.moveItem(atPath: self.path, toPath: destination.path)
    }

    /**
     Copy the file or directory to a new location synchronously.

     - Parameter destination: The new path. This path must include the name of the file or
       directory in its new location.
    */
    public func copy(_ destination: Path) throws {
        try Path.fileManager.copyItem(atPath: self.path, toPath: destination.path)
    }

    /**
     Creates a hard link at a new destination.

     - Parameter destination: The location where the link will be created.
    */
    public func link(_ destination: Path) throws {
        try Path.fileManager.linkItem(atPath: self.path, toPath: destination.path)
    }

    /**
     Creates a symbolic link at a new destination.

     - Parameter destintation: The location where the link will be created.
    */
    public func symlink(_ destination: Path) throws {
        try Path.fileManager.createSymbolicLink(atPath: self.path, withDestinationPath: destination.path)
    }
}

// MARK: Contents

extension Path {
    /**
     Reads the file.

     - Returns: the contents of the file at the specified path.
    */
    public func read() throws -> Data {
        return try Data(contentsOf: self.url, options: NSData.ReadingOptions(rawValue: 0))
    }

    /**
     Reads the file contents and encoded its bytes to string applying the given encoding.

     - Parameter encoding: the encoding which should be used to decode the data.
       (by default: `NSUTF8StringEncoding`)

     - Returns: the contents of the file at the specified path as string.
    */
    public func read(_ encoding: String.Encoding = String.Encoding.utf8) throws -> String {
        return try NSString(contentsOfFile: path, encoding: encoding.rawValue).substring(from: 0) as String
    }

    /**
     Write a file.

     - Note: Works atomically: the data is written to a backup file, and then — assuming no
       errors occur — the backup file is renamed to the name specified by path.

     - Parameter data: the contents to write to file.
    */
    public func write(_ data: Data) throws {
        try data.write(to: normalized.url, options: .atomic)
    }

    /**
     Reads the file.

     - Note: Works atomically: the data is written to a backup file, and then — assuming no
       errors occur — the backup file is renamed to the name specified by path.

     - Parameter string: the string to write to file.

     - Parameter encoding: the encoding which should be used to represent the string as bytes.
       (by default: `NSUTF8StringEncoding`)

     - Returns: the contents of the file at the specified path as string.
    */
    public func write(_ string: String, encoding: String.Encoding = String.Encoding.utf8) throws {
        try string.write(toFile: normalized.path, atomically: true, encoding: encoding)
    }
}
