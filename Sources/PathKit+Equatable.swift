import Foundation

// MARK: Equatable

extension Path : Equatable {}

/**
 Determines if two paths are identical

 - Note: The comparison is string-based. Be aware that two different paths (foo.txt and
   ./foo.txt) can refer to the same file.
*/
public func == (lhs: Path, rhs: Path) -> Bool {
    return lhs.path == rhs.path
}

// MARK: Pattern Matching

/**
 Implements pattern-matching for paths.

 - Returns: `true` if one of the following conditions is true:
     - the paths are equal (based on `Path`'s `Equatable` implementation)
     - the paths can be normalized to equal Paths.
*/
public func ~= (lhs: Path, rhs: Path) -> Bool {
    return lhs == rhs || lhs.normalized == rhs.normalized
}

// MARK: Comparable

extension Path : Comparable {}

/// Defines a strict total order over Paths based on their underlying string representation.
public func < (lhs: Path, rhs: Path) -> Bool {
    return lhs.path < rhs.path
}

// MARK: Operators

/// Appends a Path fragment to another Path to produce a new Path
public func + (lhs: Path, rhs: Path) -> Path {
    guard !lhs.path.hasSuffix(Path.separator), !rhs.path.hasPrefix(Path.separator) else {
        return Path("\(lhs.path)\(rhs.path)")
    }
    return Path("\(lhs.path)\(Path.separator)\(rhs.path)")
}

/// Appends a String fragment to another Path to produce a new Path
public func + (lhs: Path, rhs: String) -> Path {
    return lhs + Path(rhs)
}

/// Appends a String fragment to another String to produce a new Path
internal func + (lhs: String, rhs: String) -> Path {
    guard rhs.hasPrefix(Path.separator) else {
        // Absolute paths replace relative paths
        return Path(rhs)
    }
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
    while lSlice.last != ".." && !lSlice.isEmpty && rSlice.first == ".." {
        if lSlice.count > 1 || lSlice.first != Path.separator {
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

/// Inline concatenate two Paths
public func += (lhs: inout Path, rhs: Path) {
    lhs.path += rhs.path
}

/// Inline concatenate a String to a Path
public func += (lhs: inout Path, rhs: String) {
    lhs.path += rhs
}

/// Inline concatenate a Path to a String
public func += (lhs: inout String, rhs: Path) {
    lhs = (lhs + rhs.path).path
}
