//
//  PathKitTests.swift
//  PathKitTests
//
//  Created by Kyle Fuller on 20/11/2014.
//  Copyright (c) 2014 Cocode. All rights reserved.
//

import Foundation
import XCTest
import PathKit
import CatchingFire

class PathKitTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Path.current = Path(__FILE__).parent()
    }

    var fixtures: Path {
        return Path(__FILE__).parent() + "Fixtures"
    }

    func testSeparator() {
        XCTAssertEqual(Path.separator, "/")
    }

    func testCurrent() {
        let path = Path.current
        XCTAssertEqual(path.description, NSFileManager().currentDirectoryPath)
    }

    // MARK: Initialization

    func testInitialization() {
        let path = Path()
        XCTAssertEqual(path.description, "")
    }
    
    func testInitializationWithString() {
        let path = Path("/usr/bin/swift")
        XCTAssertEqual(path.description, "/usr/bin/swift")
    }

    func testInitializationWithComponents() {
        let path = Path(components: ["/usr", "bin", "swift"])
        XCTAssertEqual(path, Path("/usr/bin/swift"))
    }

    // MARK: Convertable

    func testStringLiteralIsConvertableToPath() {
        let path: Path = "/usr/bin/swift"
        XCTAssertEqual(path, Path("/usr/bin/swift"))
    }

    // MARK: Equatable

    func testEqualPath() {
        XCTAssertEqual(Path("/usr/bin/swift"), Path("/usr/bin/swift"))
    }

    func testUnEqualPath() {
        XCTAssertNotEqual(Path("/usr/bin/swift"), Path("/usr/bin/python"))
    }

    // MARK: Hashable

    func testHashable() {
        XCTAssertEqual(Path("/usr/bin/swift").hashValue, Path("/usr/bin/swift").hashValue)
    }

    // MARK: Printable

    func testPathDescription() {
        let path = Path("/usr/bin/swift")
        XCTAssertEqual(path.description, "/usr/bin/swift")
    }

    // MARK: Absolute

    func testConvertingRelativeToAbsolute() {
        let path = Path("swift")
        XCTAssertEqual(path.absolute(), Path.current + Path("swift"))
    }

    func testConvertingAbsoluteToAbsolute() {
        let path = Path("/usr/bin/swift")
        XCTAssertEqual(path.absolute(), Path("/usr/bin/swift"))
    }

    func testAbsolutePathIsAbsolute() {
        let path = Path("/usr/bin/swift")
        XCTAssertTrue(path.isAbsolute)
    }

    func testRelativePathIsNotAbsolute() {
        let path = Path("swift")
        XCTAssertFalse(path.isAbsolute)
    }

    // MARK: Is Relative

    func testRelativePathIsRelative() {
        let path = Path("swift")
        XCTAssertTrue(path.isRelative)
    }

    func testAbsolutePathIsNotRelative() {
        let path = Path("/usr/bin/swift")
        XCTAssertFalse(path.isRelative)
    }

    // MARK: Normalization

    func testNormalize() {
        let path = Path("/usr/./local/../bin/swift")
        XCTAssertEqual(path.normalize(), Path("/usr/bin/swift"))
    }

    // MARK: Abbreviation

    func testAbbreviate() {
        let path = Path("/Users/\(NSUserName())/Library")
        XCTAssertEqual(path.abbreviate(), Path("~/Library"))
    }

    // MARK: Symlink Destination

    func testRelativeSymlinkDestination() {
        let path = fixtures + "symlinks/file"
        AssertNoThrow {
            let resolvedPath = try path.symlinkDestination()
            XCTAssertEqual(resolvedPath.normalize(), fixtures + "file")
        }
    }
    
    func testAbsoluteSymlinkDestination() {
        let path = fixtures + "symlinks/swift"
        AssertNoThrow {
            let resolvedPath = try path.symlinkDestination()
            XCTAssertEqual(resolvedPath, Path("/usr/bin/swift"))
        }
    }

    func testRelativeSymlinkDestinationInSameDirectory() {
        let path = fixtures + "symlinks/same-dir"
        AssertNoThrow {
            let resolvedPath = try path.symlinkDestination()
            XCTAssertEqual(resolvedPath.normalize(), fixtures + "symlinks/file")
        }
    }

    // MARK: Last Component
    
    func testLastComponent() {
        XCTAssertEqual(Path("a/b/c.d").lastComponent, "c.d")
        XCTAssertEqual(Path("a/..").lastComponent,    "..")
    }
    
    // MARK: Last Component Without Extension
    
    func testLastComponentWithoutExtension() {
        XCTAssertEqual(Path("a/b/c.d").lastComponentWithoutExtension, "c")
        XCTAssertEqual(Path("a/..").lastComponentWithoutExtension,    ".")
    }
    
    // MARK: Components
    
    func testComponents() {
        XCTAssertEqual(Path("a/b/c.d").components,   ["a", "b", "c.d"])
        XCTAssertEqual(Path("/a/b/c.d").components,  ["/", "a", "b", "c.d"])
        XCTAssertEqual(Path("~/a/b/c.d").components, ["~", "a", "b", "c.d"])
    }
    
    // MARK: Extension
    
    func testExtension() {
        XCTAssertEqual(Path("a/b/c.d").`extension`, "d")
        XCTAssertEqual(Path("a/b.c.d").`extension`, "d")
    }

    // MARK: Existance

    func testExistingPathExists() {
        XCTAssertTrue(fixtures.exists)
    }

    func testNonExistingPathDoesntExist() {
        let path = Path("/pathkit/test")
        XCTAssertFalse(path.exists)
    }

    // MARK: File Info

    func testIsDirectory() {
        XCTAssertTrue((fixtures + "directory").isDirectory)
        XCTAssertTrue((fixtures + "symlinks/directory").isDirectory)
    }

    func testIsSymlink() {
        XCTAssertFalse((fixtures + "file/file").isSymlink)
        XCTAssertTrue((fixtures + "symlinks/file").isSymlink)
    }

    func testIsFile() {
        XCTAssertTrue((fixtures + "file").isFile)
        XCTAssertTrue((fixtures + "symlinks/file").isFile)
    }

    func testIsExecutable() {
        XCTAssertTrue((fixtures + "permissions/executable").isExecutable)
    }

    func testIsReadable() {
        XCTAssertTrue((fixtures + "permissions/readable").isReadable)
    }

    func testIsWriteable() {
        XCTAssertTrue((fixtures + "permissions/writable").isWritable)
    }

    func testIsDeletable() {
        XCTAssertTrue((fixtures + "permissions/deletable").isDeletable)
    }

    // MARK: Change Directory

    func testChdir() {
        let current = Path.current

        Path("/usr/bin").chdir {
            XCTAssertEqual(Path.current, Path("/usr/bin"))
        }

        XCTAssertEqual(Path.current, current)
    }

    func testThrowingChdirWithThrowingClosure() {
        let current = Path.current

        let error = NSError(domain: "org.cocode.PathKit", code: 1, userInfo: nil)
        AssertThrows(error) {
            try Path("/usr/bin").chdir {
                XCTAssertEqual(Path.current, Path("/usr/bin"))
                throw error
            }
        }

        XCTAssertEqual(Path.current, current)
    }

    func testThrowingChdirWithNonThrowingClosure() {
        let current = Path.current

        let error = NSError(domain: "org.cocode.PathKit", code: 1, userInfo: nil)
        AssertNoThrow {
            try Path("/usr/bin").chdir {
                XCTAssertEqual(Path.current, Path("/usr/bin"))
                if Path.current != Path("/usr/bin") {
                    // Will never happen as long as the previous assert succeeds,
                    // but prevents a warning that the closure doesn't throw.
                    throw error
                }
            }
        }

        XCTAssertEqual(Path.current, current)
    }

    // MARK: Special Paths

    func testHomeDir() {
        XCTAssertEqual(Path.home, Path("~").normalize())
    }

    func testTemporaryDir() {
        XCTAssertEqual((Path.temporary + "../../..").normalize(), Path("/var/folders"))
        XCTAssertTrue(Path.temporary.exists)
    }

    // MARK: Reading

    func testReadData() {
        let path = Path("/etc/manpaths")
        let contents: NSData = path.read()!
        let string = NSString(data:contents, encoding: NSUTF8StringEncoding)!

        XCTAssertTrue(string.hasPrefix("/usr/share/man"))
    }

    func testReadString() {
        let path = Path("/etc/manpaths")
        let contents: String = path.read()!

        XCTAssertTrue(contents.hasPrefix("/usr/share/man"))
    }
    
    func testReadNonExistingString() {
        let path = Path("/tmp/pathkit-testing")
        let contents: String? = path.read()
        
        XCTAssertEqual(contents, nil)
    }

    // MARK: Writing

    func testWriteData() {
        let path = Path("/tmp/pathkit-testing")
        let data = "Hi".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

        XCTAssertFalse(path.exists)

        XCTAssertTrue(path.write(data!))
        XCTAssertEqual(path.read(), "Hi")
        AssertNoThrow(try path.delete())
    }

    func testWriteString() {
        let path = Path("/tmp/pathkit-testing")

        XCTAssertFalse(path.exists)

        XCTAssertTrue(path.write("Hi"))
        XCTAssertEqual(path.read(), "Hi")
        AssertNoThrow(try path.delete())
    }

    // MARK: Parent

    func testParent() {
        XCTAssertEqual((fixtures + "directory/child").parent(),    fixtures + "directory")
        XCTAssertEqual((fixtures + "symlinks/directory").parent(), fixtures + "symlinks")
        XCTAssertEqual((fixtures + "directory/..").parent(),       fixtures + "directory/../..")
        XCTAssertEqual(Path("/").parent(),                         "/")
    }

    // MARK: Children

    func testChildren() {
        AssertNoThrow {
            let children = try fixtures.children()
            XCTAssertEqual(children, ["directory", "file", "permissions", "symlinks"].map { fixtures + $0 })
        }
    }

    func testChildrenWithoutDirectories() {
        AssertNoThrow {
            let children = try fixtures.children().filter { $0.isFile }
            XCTAssertEqual(children, [fixtures + "file"])
        }
    }

    // MARK: Recursive Children

    func testRecursiveChildren() {
        AssertNoThrow {
            let parent = fixtures + "directory"
            let children = try parent.recursiveChildren()
            XCTAssertEqual(children, ["child", "subdirectory", "subdirectory/child"].map { parent + $0 })
        }
    }

    // MARK: SequenceType

    func testSequenceType() {
        let path = fixtures + "directory"
        var children = ["child", "subdirectory"].map { path + $0 }
        let generator = path.generate()
        while let child = generator.next() {
            generator.skipDescendants()
            if let index = children.indexOf(child) {
                children.removeAtIndex(index)
            } else {
                XCTFail("Generated unexpected element: <\(child)>")
            }
        }
        XCTAssertTrue(children.isEmpty)
    }
    
    // MARK: Pattern Matching
    
    func testMatches() {
        XCTAssertFalse(Path("/var")  ~= "~")
        XCTAssertTrue(Path("/Users") ~= "/Users")
        XCTAssertTrue(Path("/Users") ~= "~/..")
    }
    
    // MARK: Comparable
    
    func testCompare() {
        XCTAssertTrue(Path("a") < Path("b"))
    }
    
    // MARK: Appending
    
    func testAppendPath() {
        // Trivial cases.
        XCTAssertEqual(Path("a/b"), "a" + "b")
        XCTAssertEqual(Path("a/b"), "a/" + "b")

        // Appending (to) absolute paths
        XCTAssertEqual(Path("/"),  "/" + "/")
        XCTAssertEqual(Path("/"),  "/" + "..")
        XCTAssertEqual(Path("/a"), "/" + "../a")
        XCTAssertEqual(Path("/b"), "a" + "/b")

        // Appending (to) '.'
        XCTAssertEqual(Path("a"), "a" + ".")
        XCTAssertEqual(Path("a"), "a" + "./.")
        XCTAssertEqual(Path("a"), "." + "a")
        XCTAssertEqual(Path("a"), "./." + "a")
        XCTAssertEqual(Path("."), "." + ".")
        XCTAssertEqual(Path("."), "./." + "./.")

        // Appending (to) '..'
        XCTAssertEqual(Path("."),       "a" + "..")
        XCTAssertEqual(Path("a"),       "a/b" + "..")
        XCTAssertEqual(Path("../.."),   ".." + "..")
        XCTAssertEqual(Path("b"),       "a" + "../b")
        XCTAssertEqual(Path("a/c"),     "a/b" + "../c")
        XCTAssertEqual(Path("a/b/d/e"), "a/b/c" + "../d/e")
        XCTAssertEqual(Path("../../a"), ".." + "../a")
    }
}
