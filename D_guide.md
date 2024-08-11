### D array is just a fat-pointer, passed by value in function calls.

### D range, e.g. `File.byLine()` will reuse memory buffer (i.e. old buffer contents will be overwritten), if you need save any (sub)string during iteration, you must use `byLineCopy()`.

### In D, if you (tail-)init a class instance variable when declare it, it is a constant, and shared among all the objects of that class. This behavior is different from C++/Java, although the syntax is the same.

https://forum.dlang.org/post/dwdyrbaxeoxmgjidqlzj@forum.dlang.org

### D has two options for mixins, and both of them require complete statements: Template mixin and string mixin

https://forum.dlang.org/post/mailman.2080.1719938801.3719.digitalmars-d-learn@puremagic.com

### aa.remove(key) array.remove(index) in-consistence

https://forum.dlang.org/post/warxdyxbpnbxwixgrxwm@forum.dlang.org

```
  import std.algorithm.mutation.remove;  // (*keyword*: mutation)

  array = array.remove(index);  // return a new container

  // v.s.
  aa.remove(key);  // return bool (if it's removed)
```
