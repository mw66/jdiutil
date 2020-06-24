# jdiutil: Just-Do-It util mixin

### Some small util mixin to make (debug) life easier:

Each of these mixins can be used **individually** or together in any combination:

* string interpolation for easy debug print: `_S` with var name; `_s` without var name
* `ToString` will generate string with class fields content, instead of just plain pointer.
* `ReadOnly`, `ReadWrite` declare fields without boilerplate code
* `Singleton`, Low-Lock Singleton Pattern <https://wiki.dlang.org/Low-Lock_Singleton_Pattern>
* `AtomicCounted`, atomic counter


### Examples, check [app.d](https://github.com/mingwugmail/jdiutil/blob/master/source/app.d):
```
public import jdiutil;

class Point {
  // declare fields
  mixin ReadOnly! (int,     "x", 3);
  mixin ReadWrite!(double,  "y");
  mixin ReadWrite!(string,  "label", "default value");

  // atomic counter
  mixin AtomicCounted;

  // this is a Singleton class!
  mixin Singleton!Point;

  // debug print string helper
  mixin ToString!Point;

  // the Singleton only has empty {} ctor, customInit(...) can be done like this
  Point customInit(double whatever) {
    _y = whatever;
    return this;
  }
}

/* Mis-usage error: Singleton pattern is intended to be only applied to class! e.g. not struct.
struct Foo {
  mixin Singleton!Foo;
}
*/

void main() {
        int i = 100;
        double d = 1.23456789;
        Point thePoint = Point.getSingleton().customInit(0.456);  // customInit(...)!

        // multiple vars separated by ';'
        // _S with var name; _s without var name
        writeln(mixin(_S!"with    var name: {i; d; thePoint}"));
        writeln(mixin(_s!"without var name: {i; d; thePoint}"));

      //thePoint.x = 4;  // compile Error: x is ReadOnly
        thePoint.y = 4;  // ok
        thePoint.incCount();
        logger.info(mixin(_S!"works in logger too: {i; d; thePoint}"));

        thePoint.y(3.14).label("pi");  // ok
        string str = mixin(_S!"assign to string with custom format: {i; d%06.2f; thePoint}");
        writeln(str);

        Point samePoint = Point.getSingleton();
        samePoint.incCount();
        writeln(mixin(_S!"it's the same point: {thePoint; samePoint}"));
}
```

### Output:
```
with    var name: i=100 d=1.23457 thePoint=app.Point(_x=3 _y=0.456 _label=default value _counter=0)
without var name: 100 1.23457 app.Point(_x=3 _y=0.456 _label=default value _counter=0)
2020-06-24T15:59:04.245 [info] app.d:50:main works in logger too: i=100 d=1.23457 thePoint=app.Point(_x=3 _y=4 _label=default value _counter=1)
assign to string with custom format: i=100 d=001.23 thePoint=app.Point(_x=3 _y=3.14 _label=pi _counter=1)
it's the same point: thePoint=app.Point(_x=3 _y=3.14 _label=pi _counter=2) samePoint=app.Point(_x=3 _y=3.14 _label=pi _counter=2)
```

