### D array is just a fat-pointer, passed by value in function calls.

### D range, e.g. `File.byLine()` will reuse memory buffer, if you need save any (sub)string during iteration, you must use `byLineCopy()`.

### In D, if you (tail-)init a class instance variable when declare it, it is a constant, and shared among all the objects of that class

https://forum.dlang.org/post/dwdyrbaxeoxmgjidqlzj@forum.dlang.org
