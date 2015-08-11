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
        XCTAssertTrue(path.isAbsolute())
    }

    func testRelativePathIsNotAbsolute() {
        let path = Path("swift")
        XCTAssertFalse(path.isAbsolute())
    }

    // MARK: Is Relative

    func testRelativePathIsRelative() {
        let path = Path("swift")
        XCTAssertTrue(path.isRelative())
    }

    func testAbsolutePathIsNotRelative() {
        let path = Path("/usr/bin/swift")
        XCTAssertFalse(path.isRelative())
    }

    // MARK: Normalization

    func testNormalize() {
        let path = Path("/usr/./local/../bin/swift")
        XCTAssertEqual(path.normalize(), Path("/usr/bin/swift"))
    }

    // MARK: Test adding two path's together

    func testAddingPaths() {
        let path = Path("/usr") + Path("bin") + Path("swift")
        XCTAssertEqual(path, Path("/usr/bin/swift"))
    }

    // MARK: Existance

    func testExistingPathExists() {
        let path = Path("/")
        XCTAssertTrue(path.exists())
    }

    func testNonExistingPathDoesntExist() {
        let path = Path("/pathkit/test")
        XCTAssertFalse(path.exists())
    }

    // MARK: with

    func testWith() {
        var current: Path?

        Path("/usr/bin").chdir {
            current = Path.current
        }

        XCTAssertEqual(current!, Path("/usr/bin"))
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

    // MARK: Writing

    func testWriteData() {
        let path = Path("/tmp/pathkit-testing")
        let data = "Hi".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

        XCTAssertFalse(path.exists())

        XCTAssertTrue(path.write(data!))
        XCTAssertEqual(path.read()!, "Hi")
        AssertNoThrow(try path.delete())
    }

    func testWriteString() {
        let path = Path("/tmp/pathkit-testing")

        XCTAssertFalse(path.exists())

        XCTAssertTrue(path.write("Hi"))
        XCTAssertEqual(path.read()!, "Hi")
        AssertNoThrow(try path.delete())
    }

    // MARK: Children

    func testChildren() {
        let path = (Path(__FILE__) + "..").absolute()
        AssertNoThrow {
            let children = try path.children()
            XCTAssertEqual(children, [path + "Fixtures", path + "Info.plist", Path(__FILE__)])
        }
    }

    func testChildrenWithoutDirectories() {
        let path = (Path(__FILE__) + "..").absolute()
        AssertNoThrow {
            let children = try path.children(directories: false)
            XCTAssertEqual(children, [path + "Info.plist", Path(__FILE__)])
        }
    }
}
