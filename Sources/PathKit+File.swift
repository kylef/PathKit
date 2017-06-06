import Foundation

// MARK: File Info

extension Path {
    /**
     Test whether a file or directory exists at a specified path

     - Note: `false` if the path doesn't exist on disk or its existence could not be
       determined
    */
    public var exists: Bool {
        return Path.fileManager.fileExists(atPath: normalized.path)
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
        guard let _ = try? Path.fileManager.destinationOfSymbolicLink(atPath: normalized.path) else { return false }
        return true
    }

    /**
     Test whether a path is readable

     - Note: `true` if the current process has read privileges for the file at path;
       otherwise `false` if the process does not have read privileges or the existence of the
       file could not be determined.
    */
    public var isReadable: Bool {
        return Path.fileManager.isReadableFile(atPath: normalized.path)
    }

    /**
     Test whether a path is writeable

     - Note: `true` if the current process has write privileges for the file at path;
       otherwise `false` if the process does not have write privileges or the existence of the
       file could not be determined.
    */
    public var isWritable: Bool {
        return Path.fileManager.isWritableFile(atPath: normalized.path)
    }

    /**
     Test whether a path is executable

     - Note: `true` if the current process has execute privileges for the file at path;
       otherwise `false` if the process does not have execute privileges or the existence of the
       file could not be determined.
    */
    public var isExecutable: Bool {
        return Path.fileManager.isExecutableFile(atPath: normalized.path)
    }

    /**
     Test whether a path is deletable

     - Note: `true` if the current process has delete privileges for the file at path;
       otherwise `false` if the process does not have delete privileges or the existence of the
       file could not be determined.
    */
    public var isDeletable: Bool {
        return Path.fileManager.isDeletableFile(atPath: normalized.path)
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
        try Path.fileManager.removeItem(atPath: normalized.path)
    }

    /**
     Move the file or directory to a new location synchronously.

     - Parameter destination: The new path. This path must include the name of the file or
       directory in its new location.
    */
    public func move(_ destination: Path) throws {
        try Path.fileManager.moveItem(atPath: normalized.path, toPath: destination.normalized.path)
    }

    /**
     Move the file or directory to a new location at the same parent path, but with the new file or directory name

     - Parameter newName: The new name of the file or directory
    */
    public func rename(_ newName: String) throws {
        let newPath = parent + newName
        try move(newPath)
    }

    /**
     Copy the file or directory to a new location synchronously.

     - Parameter destination: The new path. This path must include the name of the file or
       directory in its new location.
    */
    public func copy(_ destination: Path) throws {
        try Path.fileManager.copyItem(atPath: normalized.path, toPath: destination.normalized.path)
    }

    /**
     Creates a hard link at a new destination.

     - Parameter destination: The location where the link will be created.
    */
    public func link(_ destination: Path) throws {
        try Path.fileManager.linkItem(atPath: normalized.path, toPath: destination.normalized.path)
    }

    /**
     Creates a symbolic link at a new destination.

     - Parameter destintation: The location where the link will be created.
    */
    public func symlink(_ destination: Path) throws {
        try Path.fileManager.createSymbolicLink(atPath: normalized.path, withDestinationPath: destination.normalized.path)
    }
}

// MARK: Contents

extension Path {
    /**
     Reads the file.

     - Parameter options: the Data.ReadingOptions to use to read the file.
       (by default: `Data.ReadingOptions(rawValue: 0)`)

     - Returns: the contents of the file at the specified path.
    */
    public func read(options: Data.ReadingOptions = Data.ReadingOptions(rawValue: 0)) throws -> Data {
        return try Data(contentsOf: url, options: options)
    }

    /**
     Reads the file contents and encoded its bytes to string applying the given encoding.

     - Parameter encoding: the encoding which should be used to decode the data.
       (by default: `.utf8`)

     - Returns: the contents of the file at the specified path as string.
    */
    public func read(_ encoding: String.Encoding = .utf8) throws -> String {
        return try String(contentsOfFile: normalized.path, encoding: encoding)
    }

    /**
     Write a file.

     - Note: Works atomically: the data is written to a backup file, and then — assuming no
       errors occur — the backup file is renamed to the name specified by path.

     - Parameter data: the contents to write to file.

     - Parameter options: the Data.WritingOptions to use to write the file.
       (by default: `.atomic`)

     - Parameter force: whether or not to try to forcefull write the file by creating the intermediate directories.
       (by default: `true`)
    */
    public func write(_ data: Data, options: Data.WritingOptions = .atomic, force: Bool = false) throws {
        if force {
            try mkintermediatedirs()
        }
        try data.write(to: url, options: options)
    }

    /**
     Reads the file.

     - Note: Works atomically: the data is written to a backup file, and then — assuming no
       errors occur — the backup file is renamed to the name specified by path.

     - Parameter string: the string to write to file.

     - Parameter encoding: the encoding which should be used to represent the string as bytes.
       (by default: `.utf8`)

     - Parameter force: whether or not to try to forcefull write the file by creating the intermediate directories.
       (by default: `true`)
    */
    public func write(_ string: String, atomically: Bool = true, encoding: String.Encoding = .utf8, force: Bool = false) throws {
        if force {
            try mkintermediatedirs()
        }
        try string.write(toFile: normalized.path, atomically: atomically, encoding: encoding)
    }
}
