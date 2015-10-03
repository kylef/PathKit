import Foundation
import XCTest
import PathKit
import CatchingFire


class ManipulationTests : XCTestCase {

  var fixtures: Path {
    return Path(__FILE__).parent() + "Fixtures"
  }

  var fixtureFile: Path {
    return fixtures + "file"
  }

  var copiedFile: Path {
    let path = Path("file")
    if !path.exists {
      try! fixtureFile.copy(path)
    }
    return path
  }

  override func setUp() {
    super.setUp()
    Path.current = try! Path.uniqueTemporary()
  }

  override func tearDown() {
    super.tearDown()
    try! Path.current.delete()
  }

  func testMkdir() {
    let testDir = Path("test_mkdir")
    AssertNoThrow { try testDir.mkdir() }
    XCTAssertTrue(testDir.isDirectory)
  }

  func testMkdirWithNonExistingImmediateDirFails() {
    let testDir = Path("test_mkdir/test")
    AssertThrows(NSCocoaError.FileNoSuchFileError) { try testDir.mkdir() }
  }

  func testMkdirWithExistingDirFails() {
    let testDir = Path("test_mkdir")
    AssertNoThrow {
      try testDir.mkdir()
      precondition(testDir.isDirectory)
      AssertThrows(NSCocoaError.FileWriteFileExistsError) { try testDir.mkdir() }
    }
  }

  func testMkpath() {
    let testDir = Path("test_mkpath/test")
    AssertNoThrow {
      try testDir.mkpath()
      XCTAssertTrue(testDir.isDirectory)
    }
  }

  func testMkpathWithExistingDir() {
    let testDir = Path("test_mkdir")
    AssertNoThrow {
      try testDir.mkdir()
      precondition(testDir.isDirectory)
      try testDir.mkpath()
    }
  }

  func testCopy() {
    let copiedFile = Path("file")
    AssertNoThrow {
      try fixtureFile.copy(copiedFile)
      XCTAssertTrue(copiedFile.isFile)
    }
  }

  func testMove() {
    let movedFile = Path("moved")
    AssertNoThrow {
      try copiedFile.move(movedFile)
      XCTAssertTrue(movedFile.isFile)
    }
  }

  func testLink() {
    let linkedFile = Path("linked")
    AssertNoThrow {
      try copiedFile.link(linkedFile)
      XCTAssertTrue(linkedFile.isFile)
    }
  }

  func testSymlink() {
    let symlinkedFile = Path("symlinked")
    AssertNoThrow {
      try symlinkedFile.symlink(copiedFile)
      XCTAssertTrue(symlinkedFile.isFile)
      let symlinkDestination = try symlinkedFile.symlinkDestination()
      XCTAssertEqual(symlinkDestination, copiedFile)
    }
  }
}