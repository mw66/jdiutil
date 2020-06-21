# jdiutil: Just-Do-It util mixin

## Some small util mixin to make (debug) life easier:

* string interpolation for easy debug print: `_S` with var name; `_s` without var name
* `ToString` will generate string with class fields content, instead of just plain pointer.
* `ReadOnly`, `ReadWrite` declare fields without boilerplate code
* `Singleton`, Low-Lock Singleton Pattern <https://wiki.dlang.org/Low-Lock_Singleton_Pattern>
* `AtomicCounted`, atomic counter


## Examples:
```
class Point {
  // declare fields
  mixin ReadOnly! (int,     "x");
  mixin ReadWrite!(double,  "y");
  mixin ReadWrite!(string,  "label", "default value");

  // atomic counter
  mixin AtomicCounted;

  // this is a Singleton class!
  mixin Singleton!Point;

  // debug print string helper
  mixin ToString!Point;
}


void main()
{
        int i = 100;
        double d = 1.23456789;
        Point thePoint = Point.getSingleton();

        // multiple vars separated by ';'
        // _S with var name; _s without var name
        writeln(mixin(_S!"print with    var name: {i; d; thePoint}"));
        writeln(mixin(_s!"print without var name: {i; d; thePoint}"));

        thePoint.incCount();
        logger.info(mixin(_S!"works in logger too: {i; d; thePoint}"));

        thePoint.incCount();
        string str = mixin(_S!"assign to string with custom format: {i; d%06.2f; thePoint}");
        writeln(str);
}
```

# Output:
```
print with    var name: i=100 d=1.23457 thePoint=app.Point(_x=0 _y=nan _label=default value _counter=0)
print without var name: 100 1.23457 app.Point(_x=0 _y=nan _label=default value _counter=0)
2020-06-20T22:31:29.053 [info] app.d:38:main works in logger too: i=100 d=1.23457 thePoint=app.Point(_x=0 _y=nan _label=default value _counter=1)
assign to string with custom format: i=100 d=001.23 thePoint=app.Point(_x=0 _y=nan _label=default value _counter=2)
```
