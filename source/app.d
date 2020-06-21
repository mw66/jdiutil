import std.stdio;
import std.experimental.logger;

import jdiutil;

alias logger = std.experimental.logger;


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
