import Foundation

// MARK: SequenceType

extension Path : Sequence {
    /// Represents a path sequence with specific enumeration options
    public struct PathSequence: Sequence {
        private var path: Path
        private var options: FileManager.DirectoryEnumerationOptions
        init(path: Path, options: FileManager.DirectoryEnumerationOptions) {
            self.path = path
            self.options = options
        }

        public func makeIterator() -> DirectoryEnumerator {
            return DirectoryEnumerator(path: path, options: options)
        }
    }

    /**
     Enumerates the contents of a directory, returning the paths of all files and directories
     contained within that directory. These paths are relative to the directory.
    */
    public struct DirectoryEnumerator: IteratorProtocol {
        public typealias Element = Path

        let path: Path
        let directoryEnumerator: FileManager.DirectoryEnumerator?

        init(path: Path, options mask: FileManager.DirectoryEnumerationOptions = []) {
            let options = FileManager.DirectoryEnumerationOptions(rawValue: mask.rawValue)
            self.path = path
            self.directoryEnumerator = Path.fileManager.enumerator(at: path.url, includingPropertiesForKeys: nil, options: options)
        }

        public func next() -> Path? {
            guard let next = directoryEnumerator?.nextObject(), let nextURL = next as? URL else { return nil }
            return Path(nextURL.path)
        }

        /// Skip recursion into the most recently obtained subdirectory.
        public func skipDescendants() {
            directoryEnumerator?.skipDescendants()
        }
    }

    /**
     Perform a deep enumeration of a directory.

     - Returns: a directory enumerator that can be used to perform a deep enumeration of the
       directory.
    */
    public func makeIterator() -> DirectoryEnumerator {
        return DirectoryEnumerator(path: self)
    }

    /**
     Perform a deep enumeration of a directory.

     - Parameter options: FileManager directory enumerator options.

     - Returns: a path sequence that can be used to perform a deep enumeration of the
       directory.
    */
    public func iterateChildren(options: FileManager.DirectoryEnumerationOptions = []) -> PathSequence {
        return PathSequence(path: self, options: options)
    }
}

extension Array {
    var fullSlice: ArraySlice<Element> {
        return self[self.indices.suffix(from: 0)]
    }
}
