# PathKit Changelog

## 1.0.0 (2019-03-27)

### Enhancements

- Fix warnings for Swift 5

### Breaking

- Drop support for Swift < 4.2

## 0.9.2 (2018-09-10)

### Enhancements

- Adds support for Swift 4.2.

## 0.9.1

### Bug Fixes

* Fix warning with Swift 4, support 4.1
  [Keith Smiley](https://github.com/keith)

## 0.9.0

### Enhancements

* Support for Swift 4.

### Bug Fixes

* Appending to (.) slice started with (..) will return correct path.  
  [Antondomashnev](https://github.com/Antondomashnev)


## 0.8.0

### Enhancements

* New string (`path.string`) and URL (`path.url`) accessors on a path.  
  [David Jennes](https://github.com/djbe)

* Additional method for creating an iterator with options.  
  [#25](https://github.com/kylef/PathKit/pull/23)
  [David Jennes](https://github.com/djbe)

* Abbreviate is now supported on Linux.  
  [Ben Snider](https://github.com/stupergenius)

### Bug Fixes

* Enumerating a path will now return an `Optional.none` when a directory does
  not exist.  
  [Leon Breedt](https://github.com/leonbreedt)


## 0.7.0

* Adds support for Swift 3.0
