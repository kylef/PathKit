import Foundation
import Spectre
@testable import PathKit


struct ThrowError: Error, Equatable {}
func == (lhs:ThrowError, rhs:ThrowError) -> Bool { return true }


public func testPathKit() {
describe("PathKit") {
  let fixtures = Path(#file).parent() + "Fixtures"

  $0.before {
    Path.current = Path(#file).parent()
  }

  $0.it("provides the system separator") {
    try expect(Path.separator) == "/"
  }

  $0.it("returns the current working directory") {
    try expect(Path.current.description) == FileManager().currentDirectoryPath
  }

  $0.describe("initialisation") {
    $0.it("can be initialised with no arguments") {
      try expect(Path().description) == ""
    }

    $0.it("can be initialised with a string") {
      let path = Path("/usr/bin/swift")
      try expect(path.description) == "/usr/bin/swift"
    }

    $0.it("can be initialised with path components") {
      let path = Path(components: ["/usr", "bin", "swift"])
      try expect(path.description) == "/usr/bin/swift"
    }
  }

  $0.describe("convertable") {
    $0.it("can be converted from a string literal") {
      let path: Path = "/usr/bin/swift"
      try expect(path.description) == "/usr/bin/swift"
    }

    $0.it("can be converted to a string description") {
      try expect(Path("/usr/bin/swift").description) == "/usr/bin/swift"
    }
    
    $0.it("can be converted to a string") {
      try expect(Path("/usr/bin/swift").string) == "/usr/bin/swift"
    }
    
    $0.it("can be converted to a url") {
      try expect(Path("/usr/bin/swift").url) == URL(fileURLWithPath: "/usr/bin/swift")
    }
  }

  $0.describe("Equatable") {
    $0.it("equates to an equal path") {
      try expect(Path("/usr")) == Path("/usr")
    }

    $0.it("doesn't equate to a non-equal path") {
      try expect(Path("/usr")) != Path("/bin")
    }
  }

  $0.describe("Hashable") {
    $0.it("exposes a hash value identical to an identical path") {
      try expect(Path("/usr").hashValue) == Path("/usr").hashValue
    }
  }

  $0.context("Absolute") {
    $0.describe("a relative path") {
      let path = Path("swift")

      $0.it("can be converted to an absolute path") {
        try expect(path.absolute()) == (Path.current + Path("swift"))
      }

      $0.it("is not absolute") {
        try expect(path.isAbsolute) == false
      }

      $0.it("is relative") {
        try expect(path.isRelative) == true
      }
    }

    $0.describe("a relative path with tilde") {
      let path = Path("~")

      $0.it("can be converted to an absolute path") {
        #if os(Linux)
          if NSUserName() == "root" {
            try expect(path.absolute()) == "/root"		
          }
          else {
            try expect(path.absolute()) == "/home/" + NSUserName()
          }
        #else
          try expect(path.absolute()) == "/Users/" + NSUserName()
        #endif
      }

      $0.it("is not absolute") {
        try expect(path.isAbsolute) == false
      }

      $0.it("is relative") {
        try expect(path.isRelative) == true
      }

    }

    $0.describe("an absolute path") {
      let path = Path("/usr/bin/swift")

      $0.it("can be converted to an absolute path") {
        try expect(path.absolute()) == path
      }

      $0.it("is absolute") {
        try expect(path.isAbsolute) == true
      }

      $0.it("is not relative") {
        try expect(path.isRelative) == false
      }
    }
  }

  $0.it("can be normalized") {
    let path = Path("/usr/./local/../bin/swift")
    try expect(path.normalize()) == Path("/usr/bin/swift")
  }

  $0.it("can be abbreviated") {
    let home = Path.home.string
    
    try expect(Path("\(home)/foo/bar").abbreviate()) == Path("~/foo/bar")
    try expect(Path("\(home)").abbreviate()) == Path("~")
    try expect(Path("\(home)/").abbreviate()) == Path("~")
    try expect(Path("\(home)/backups\(home)").abbreviate()) == Path("~/backups\(home)")
    try expect(Path("\(home)/backups\(home)/foo/bar").abbreviate()) == Path("~/backups\(home)/foo/bar")
    
    #if os(Linux)
        try expect(Path("\(home.uppercased())").abbreviate()) == Path("\(home.uppercased())")
    #else
        try expect(Path("\(home.uppercased())").abbreviate()) == Path("~")
    #endif
  }
  
  struct FakeFSInfo: FileSystemInfo {
    let caseSensitive: Bool
    
    func isFSCaseSensitiveAt(path: Path) -> Bool {
      return caseSensitive
    }
  }

  $0.it("can abbreviate paths on a case sensitive fs") {
    let home = Path.home.string
    let fakeFSInfo = FakeFSInfo(caseSensitive: true)
    var path = Path("\(home.uppercased())")
    path.fileSystemInfo = fakeFSInfo
    
    try expect(path.abbreviate().string) == home.uppercased()
  }
  
  $0.it("can abbreviate paths on a case insensitive fs") {
    let home = Path.home.string
    let fakeFSInfo = FakeFSInfo(caseSensitive: false)
    var path = Path("\(home.uppercased())")
    path.fileSystemInfo = fakeFSInfo
    
    try expect(path.abbreviate()) == Path("~")
  }

  $0.describe("symlinking") {
    $0.it("can create a symlink with a relative destination") {
      let path = fixtures + "symlinks/file"
      let resolvedPath = try path.symlinkDestination()
      try expect(resolvedPath.normalize()) == fixtures + "file"
    }

    $0.it("can create a symlink with an absolute destination") {
      let path = fixtures + "symlinks/swift"
      let resolvedPath = try path.symlinkDestination()
      try expect(resolvedPath) == Path("/usr/bin/swift")
    }

    $0.it("can create a relative symlink in the same directory") {
      #if os(Linux)
        throw skip()
      #else
        let path = fixtures + "symlinks/same-dir"
        let resolvedPath = try path.symlinkDestination()
        try expect(resolvedPath.normalize()) == fixtures + "symlinks/file"
      #endif
    }
  }

  $0.it("can return the last component") {
    try expect(Path("a/b/c.d").lastComponent) == "c.d"
    try expect(Path("a/..").lastComponent) == ".."
  }

  $0.it("can return the last component without extension") {
    try expect(Path("a/b/c.d").lastComponentWithoutExtension) == "c"
    #if !os(Linux) || swift(>=4.1)
        try expect(Path("a/..").lastComponentWithoutExtension) == ".."
    #else
        try expect(Path("a/..").lastComponentWithoutExtension) == "."
    #endif
  }

  $0.it("can be split into components") {
    try expect(Path("a/b/c.d").components) == ["a", "b", "c.d"]
    try expect(Path("/a/b/c.d").components) == ["/", "a", "b", "c.d"]
    try expect(Path("~/a/b/c.d").components) == ["~", "a", "b", "c.d"]
  }

  $0.it("can return the extension") {
    try expect(Path("a/b/c.d").`extension`) == "d"
    try expect(Path("a/b.c.d").`extension`) == "d"
    try expect(Path("a/b").`extension`).to.beNil()
  }

  $0.describe("exists") {
    $0.it("can check if the path exists") {
      try expect(fixtures.exists).to.beTrue()
    }

    $0.it("can check if a path does not exist") {
      let path = Path("/pathkit/test")
      try expect(path.exists).to.beFalse()
    }
  }

  $0.describe("file info") {
    $0.it("can test if a path is a directory") {
      try expect((fixtures + "directory").isDirectory).to.beTrue()
      try expect((fixtures + "symlinks/directory").isDirectory).to.beTrue()
    }

    $0.it("can test if a path is a symlink") {
      try expect((fixtures + "file/file").isSymlink).to.beFalse()
      try expect((fixtures + "symlinks/file").isSymlink).to.beTrue()
    }

    $0.it("can test if a path is a file") {
      try expect((fixtures + "file").isFile).to.beTrue()
      try expect((fixtures + "symlinks/file").isFile).to.beTrue()
    }

    $0.it("can test if a path is executable") {
      try expect((fixtures + "permissions/executable").isExecutable).to.beTrue()
    }

    $0.it("can test if a path is readable") {
      try expect((fixtures + "permissions/readable").isReadable).to.beTrue()
    }

    $0.it("can test if a path is writable") {
      try expect((fixtures + "permissions/writable").isWritable).to.beTrue()
    }

    // fatal error: isDeletableFile(atPath:) is not yet implemented
    $0.it("can test if a path is deletable") {
      #if os(Linux)
        throw skip()
      #else
        try expect((fixtures + "permissions/deletable").isDeletable).to.beTrue()
      #endif
    }
  }

  $0.describe("changing directory") {
    $0.it("can change directory") {
      let current = Path.current

      try Path("/usr/bin").chdir {
        try expect(Path.current) == Path("/usr/bin")
      }

      try expect(Path.current) == current
    }

    $0.it("can change directory with a throwing closure") {
      let current = Path.current
      let error = ThrowError()

      try expect {
        try Path("/usr/bin").chdir {
          try expect(Path.current) == Path("/usr/bin")
          throw error
        }
      }.toThrow(error)

      try expect(Path.current) == current
    }
  }

  $0.describe("special paths") {
    $0.it("can provide the home directory") {
      try expect(Path.home) == Path("~").normalize()
    }

    $0.it("can provide the tempoary directory") {
      try expect(Path.temporary) == Path(NSTemporaryDirectory())
      try expect(Path.temporary.exists).to.beTrue()
    }
  }

  $0.describe("reading") {
    $0.it("can read Data from a file") {
      let path = fixtures + "hello"
      let contents: Data? = try path.read()
      let string = NSString(data:contents! as Data, encoding: String.Encoding.utf8.rawValue)!

      try expect(string) == "Hello World\n"
    }

    $0.it("errors when you read from a non-existing file as NSData") {
      let path = Path("/tmp/pathkit-testing")

      try expect {
        try path.read() as Data
      }.toThrow()
    }

    $0.it("can read a String from a file") {
      let path = fixtures + "hello"
      let contents: String? = try path.read()

      try expect(contents) == "Hello World\n"
    }

    $0.it("errors when you read from a non-existing file as a String") {
      let path = Path("/tmp/pathkit-testing")

      try expect {
        try path.read() as String
      }.toThrow()
    }
  }

  $0.describe("writing") {
    $0.it("can write NSData to a file") {
      let path = Path("/tmp/pathkit-testing")
      let data = "Hi".data(using: String.Encoding.utf8, allowLossyConversion: true)

      try expect(path.exists).to.beFalse()

      try path.write(data!)
      try expect(try? path.read()) == "Hi"
      try path.delete()
    }

    $0.it("throws an error on failure writing data") {
      #if os(Linux)
      throw skip()
      #else
      let path = Path("/")
      let data = "Hi".data(using: String.Encoding.utf8, allowLossyConversion: true)

      try expect {
        try path.write(data!)
      }.toThrow()
      #endif
    }

    $0.it("can write a String to a file") {
      let path = Path("/tmp/pathkit-testing")

      try path.write("Hi")
      try expect(try path.read()) == "Hi"
      try path.delete()
    }

    $0.it("throws an error on failure writing a String") {
      #if os(Linux)
      throw skip()
      #else
      let path = Path("/")

      try expect {
        try path.write("hi")
      }.toThrow()
      #endif
    }
  }

  $0.it("can return the parent directory of a path") {
    try expect((fixtures + "directory/child").parent()) == fixtures + "directory"
    try expect((fixtures + "symlinks/directory").parent()) == fixtures + "symlinks"
    try expect((fixtures + "directory/..").parent()) == fixtures + "directory/../.."
    try expect(Path("/").parent()) == "/"
  }

  $0.it("can return the children") {
    let children = try fixtures.children().sorted(by: <)
    let expected = ["hello", "directory", "file", "permissions", "symlinks"].map { fixtures + $0 }.sorted(by: <)
    try expect(children) == expected
  }

  $0.it("can return the recursive children") {
    let parent = fixtures + "directory"
    let children = try parent.recursiveChildren().sorted(by: <)
    let expected = [".hiddenFile", "child", "subdirectory", "subdirectory/child"].map { parent + $0 }.sorted(by: <)
    try expect(children) == expected
  }

  $0.describe("conforms to SequenceType") {
    $0.it("without options") {
      #if !os(Darwin) && !swift(>=4.1)
      throw skip()
      #else
      let path = fixtures + "directory"
      var children = ["child", "subdirectory", ".hiddenFile"].map { path + $0 }
      let generator = path.makeIterator()
      while let child = generator.next() {
        generator.skipDescendants()
        if let index = children.index(of: child) {
          children.remove(at: index)
        } else {
          throw failure("Generated unexpected element: <\(child)>")
        }
      }

      try expect(children.isEmpty).to.beTrue()
      try expect(Path("/non/existing/directory/path").makeIterator().next()).to.beNil()
      #endif
    }
  
    $0.it("with options") {
      #if os(Linux)
      throw skip()
      #else
      let path = fixtures + "directory"
      var children = ["child", "subdirectory"].map { path + $0 }
      let generator = path.iterateChildren(options: .skipsHiddenFiles).makeIterator()
      while let child = generator.next() {
        generator.skipDescendants()
        if let index = children.index(of: child) {
          children.remove(at: index)
        } else {
          throw failure("Generated unexpected element: <\(child)>")
        }
      }

      try expect(children.isEmpty).to.beTrue()
      try expect(Path("/non/existing/directory/path").makeIterator().next()).to.beNil()
      #endif
    }
  }

  $0.it("can be pattern matched") {
    try expect(Path("/var") ~= "~").to.beFalse()
    try expect(Path("/Users") ~= "/Users").to.beTrue()
    try expect((Path.home + "..") ~= "~/..").to.beTrue()
  }

  $0.it("can be compared") {
    try expect(Path("a")) < Path("b")
  }

  $0.it("can be appended to") {
    // Trivial cases.
    try expect(Path("a/b")) == "a" + "b"
    try expect(Path("a/b")) == "a/" + "b"

    // Appending (to) absolute paths
    try expect(Path("/")) == "/" + "/"
    try expect(Path("/")) == "/" + ".."
    try expect(Path("/a")) == "/" + "../a"
    try expect(Path("/b")) == "a" + "/b"

    // Appending (to) '.'
    try expect(Path("a")) == "a" + "."
    try expect(Path("a")) == "a" + "./."
    try expect(Path("a")) == "." + "a"
    try expect(Path("a")) == "./." + "a"
    try expect(Path(".")) == "." + "."
    try expect(Path(".")) == "./." + "./."
    try expect(Path("../a")) == "." + "./../a"
    try expect(Path("../a")) == "." + "../a"

    // Appending (to) '..'
    try expect(Path(".")) == "a" + ".."
    try expect(Path("a")) == "a/b" + ".."
    try expect(Path("../..")) == ".." + ".."
    try expect(Path("b")) == "a" + "../b"
    try expect(Path("a/c")) == "a/b" + "../c"
    try expect(Path("a/b/d/e")) == "a/b/c" + "../d/e"
    try expect(Path("../../a")) == ".." + "../a"
  }

  $0.describe("glob") {
    $0.it("Path static glob") {
      let pattern = (fixtures + "permissions/*able").description
      let paths = Path.glob(pattern)

      let results = try (fixtures + "permissions").children().map { $0.absolute() }.sorted(by: <)
      try expect(paths) == results.sorted(by: <)
    }

    $0.it("can glob inside a directory") {
      let paths = fixtures.glob("permissions/*able")

      let results = try (fixtures + "permissions").children().map { $0.absolute() }.sorted(by: <)
      try expect(paths) == results.sorted(by: <)
    }
  }
}
}
