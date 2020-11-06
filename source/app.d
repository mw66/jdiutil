import std.stdio;
import std.experimental.logger;

public import jdiutil;

alias logger = std.experimental.logger;


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
        (cast(shared)thePoint).incCount();
        logger.info(mixin(_S!"works in logger too: {i; d; thePoint}"));

        thePoint.y(3.14).label("pi");  // ok
        string str = mixin(_S!"assign to string with custom format: {i; d%06.2f; thePoint}");
        writeln(str);

        Point samePoint = Point.getSingleton();
        (cast(shared)samePoint).incCount();
        writeln(mixin(_S!"it's the same point: {thePoint; samePoint}"));
}
