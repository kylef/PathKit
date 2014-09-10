PathKit
=======

Effortless path operations in Swift.

## Usage

```swift
let path = Path("/usr/bin/swift")
```

#### Joining paths

```swift
let path = Path("/usr/bin") + Path("swift")
```

#### Determine if a path is absolute

```swift
path.isAbsolute()
```

#### Determine if a path is relative

```swift
path.isRelative()
```

#### Determine if a file or directory exists at the path

```swift
path.exists()
```

#### Determine if a path is a directory

```swift
path.isDirectory()
```

#### Get an absolute path

```swift
let absolutePath = path.absolute()
```

#### Normalize a path

This cleans up any redundant `..` or `.` and double slashes in paths.

```swift
let normalizedPath = path.normalize()
```

#### Deleting a path

```swift
path.delete()
```

#### Moving a path

```swift
path.move(newPath)
```

### Contact

Kyle Fuller

- http://kylefuller.co.uk
- https://twitter.com/kylefuller

### License

PathKit is licensed under the [BSD License](LICENSE).

