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

    func testSymlinkDestination() {
        let path = Path("/tmp")
        AssertNoThrow {
            let resolvedPath = try path.symlinkDestination()
            XCTAssertEqual(resolvedPath, Path("/private/tmp"))
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
        let path = Path("/")
        XCTAssertTrue(path.exists)
    }

    func testNonExistingPathDoesntExist() {
        let path = Path("/pathkit/test")
        XCTAssertFalse(path.exists)
    }

    // MARK: Modifications

    func testMkdir() {
        let path = Path.temporary
        let testDir = path + "test_mkdir"
        do { try testDir.delete() } catch {}
        AssertNoThrow { try testDir.mkdir() }
        XCTAssertTrue(testDir.isDirectory)
        AssertNoThrow { try testDir.delete() }
    }

    func testMkdirWithNonExistingImmediateDirFails() {
        let path = Path.temporary
        let testDir = path + "test_mkdir/test"
        do { try testDir.delete() } catch {}
        AssertThrows(NSCocoaError.FileNoSuchFileError) { try testDir.mkdir() }
        XCTAssertFalse(testDir.isDirectory)
    }

    func testMkdirWithExistingDirFails() {
        let path = Path.temporary
        let testDir = path + "test_mkdir"
        do { try testDir.delete() } catch {}
        AssertNoThrow {
            try testDir.mkdir()
            XCTAssertTrue(testDir.isDirectory)
            AssertThrows(NSCocoaError.FileWriteFileExistsError) { try testDir.mkdir() }
            try testDir.delete()
        }
    }

    func testMkpath() {
        let path = Path.temporary
        let testDir = path + "test_mkpath/test"
        AssertNoThrow {
            try testDir.mkpath()
            XCTAssertTrue(testDir.isDirectory)
            try testDir.delete()
        }
    }

    func testMkpathWithExistingDir() {
        let path = Path.temporary
        let testDir = path + "test_mkdir"
        do { try testDir.delete() } catch {}
        AssertNoThrow {
            try testDir.mkdir()
            XCTAssertTrue(testDir.isDirectory)
            try testDir.mkpath()
            try testDir.delete()
        }
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
        let path = Path(__FILE__)
        XCTAssertEqual(path.parent().lastComponent, "PathKitTests")
    }

    // MARK: Children

    func testChildren() {
        let path = Path(__FILE__).parent()
        AssertNoThrow {
            let children = try path.children()
            XCTAssertEqual(children, [path + "Fixtures", path + "Info.plist", Path(__FILE__)])
        }
    }

    func testChildrenWithoutDirectories() {
        let path = Path(__FILE__).parent()
        AssertNoThrow {
            let children = try path.children().filter { $0.isFile }
            XCTAssertEqual(children, [path + "Info.plist", Path(__FILE__)])
        }
    }

    // MARK: Recursive Children

    func testRecursiveChildren() {
        let path = Path(__FILE__).parent()
        AssertNoThrow {
            let children = try path.recursiveChildren()
            XCTAssertEqual(children, [path + "Fixtures", path + "Fixtures/.git-keep", path + "Info.plist", Path(__FILE__)])
        }
    }

    // MARK: SequenceType

    func testSequenceType() {
        let path = Path(__FILE__).parent()
        var children = ["Fixtures", "Info.plist", Path(__FILE__).lastComponent]
        XCTAssertTrue(path.contains(Path(__FILE__)))
        let generator = path.generate()
        while let child = generator.next() {
            generator.skipDescendants()
            if let index = children.indexOf(child.lastComponent) {
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
    
    func testAppendPathWithoutFollowingSlashToPathWithoutLeadingSlash() {
        let path = Path("/usr") + "var"
        XCTAssertEqual(path, "/usr/var")
    }
    
    func testAppendPathWithoutFollowingSlashToPathWithLeadingSlash() {
        let path = Path("/usr") + "/var"
        XCTAssertEqual(path, "/usr/var")
    }
    
    func testAppendPathWithFollowingSlashToPathWithoutLeadingSlash() {
        let path = Path("/usr/") + "var"
        XCTAssertEqual(path, "/usr/var")
    }
    
    func testAppendPathWithFollowingSlashToPathWithLeadingSlash() {
        let path = Path("/usr/") + "/var"
        XCTAssertEqual(path, "/usr/var")
    }
}
