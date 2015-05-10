module dau.util.content;

import std.file;
import std.path;
import std.format : format;
import std.exception : enforce;

/**
 * Loads, caches, and provides access to instances of some type T loaded from files.
 *
 * Params:
 *  T = type of data to load
 *  load = function that loads an instance of T from a given file path
 */
struct ContentCache(T, alias load) if (is(typeof(load(string.init)) : T)) {
  private {
    string    _root;
    string[]  _extensions;
    T[string] _cache;
  }

  /**
   * Construct a content cache that loads files under the given root with the given extensions.
   *
   * Params:
   *  root = directory from which to start searching for files
   *  extensions = allowed extensions for loaded files
   */
  this(string root, string[] extensions) {
    _root = root;
    _extensions = extensions;
  }

  T get(string key) {
    auto obj = key in _cache;

    // already in cache
    if (obj !is null) return *obj;

    auto path = buildNormalizedPath(_root, key);
    foreach(ext ; _extensions) {
      string file = path.setExtension(ext);
      if (file.exists) {
        auto found = load(file);
        _cache[key] = found;
        return found;
      }
    }

    enforce(0, format("Failed loading %s '%s' from %s.%s", T.stringof, key, path, _extensions));
    return T.init;
  }
}

///
unittest {
  import std.path      : buildNormalizedPath;
  import std.uuid      : randomUUID;
  import std.file      : tempDir, write, mkdirRecurse, rmdirRecurse;
  import std.exception : assertThrown;

  // test path setup
  auto dir = buildPath(tempDir(), "dau_test", randomUUID().toString);
  mkdirRecurse(dir);
  scope(exit) rmdirRecurse(dir);

  auto testData = [
    "fileOne.txt"  : "first file",
    "fileTwo.qqq"  : "second file",
    "dir/file.txt" : "nested",
  ];

  foreach(key, val ; testData) {
    auto path = buildNormalizedPath(dir, key);
    mkdirRecurse(path.dirName);
    path.write(val);
  }

  // define a struct, and a loading function
  struct Data { string s; }
  int counter = 0;  // track number of calls to load
  Data load(string path) {
    ++counter;
    return Data(path.readText);
  }

  // create a cache based on that struct and function
  auto cache = ContentCache!(Data, load)(dir, ["txt", "qqq"]);

  // try loading some data
  assert(cache.get("fileOne").s  == "first file");
  assert(cache.get("fileTwo").s  == "second file");
  assert(cache.get("dir/file").s == "nested");
  assertThrown(cache.get("nope"));

  assert(counter == 3); // loaded 3 Data so far

  assert(cache.get("fileOne").s);
  assert(cache.get("fileTwo").s);
  assert(cache.get("dir/file").s);

  assert(counter == 3); // no more load calls -- already cached
}
