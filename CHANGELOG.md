# PathKit Changelog

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
