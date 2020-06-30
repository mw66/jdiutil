module jdiutil;

public static import core.atomic;

import std.algorithm;
import std.array;
import std.format : format;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;

alias format = std.format.format;

/* ========================================================================== *\
  string interpolation
\* ========================================================================== */
// return the replacement string
string _collectVar(ref string[] ids, string _id, bool showvar) {
  _id = std.string.strip(_id);
  if (0 == _id.length) {
    return "";  // skip empty string
  }

  auto idFmt = _id.find("%");
  auto id = _id[0 .. $-idFmt.length];
  ids ~= id; // [..., "def"]
  auto varfmt = (idFmt.empty ? "%s" : idFmt);
  if (showvar) {
      varfmt = id ~ "=" ~ varfmt;
  }
  return varfmt;
}

string _collectVars(ref string[] ids, string _id, bool showvar) {
  auto vars = _id.split(";").map!(id => _collectVar(ids, id, showvar));
  return join(vars, " ");
}


// from https://github.com/ShigekiKarita/stri/blob/master/source/stri.d
auto parse(string s, bool showvar) {

    string fmt = s;
    string[] ids;
    auto subs = s.find("{"); // "${def}gh${i}..."
    while (!subs.empty) {
        auto ends = subs.find("}"); // "}gh${i}..."

        if (ends.empty) {
            // TODO assert here
            break;
        }

        auto quote = subs[0..$+1-ends.length]; // "${def}"
        auto _id = subs[1..$-ends.length]; // "def"
        string varfmt = _collectVars(ids, _id, showvar);
        fmt = fmt.replace(quote, varfmt);

        subs = ends.find("{"); // "${i}..."
    }
    return tuple!("ids", "fmt")(ids, fmt);
}

string _interp(string sfmt, bool showvar)() {
    enum _ret = parse(sfmt, showvar);
    return format!`format!"%s"(%-(%s, %))`(_ret.fmt, _ret.ids);
}

string _S(string sfmt)() {return _interp!(sfmt, true); }
string _s(string sfmt)() {return _interp!(sfmt, false);}

unittest
{
    auto a = 1;
    struct A {
        static a = 0.123;
    }

    enum _a0 = "D-lang";
    const string fmt = "{a} is one. {_a0} is nice. {a%03d}, {A.a%.3f}";
    {
    auto str = mixin(_s!fmt);
    writeln(str);
    assert(str == "1 is one. D-lang is nice. 001, 0.123");
    }

    {
    auto str = mixin(_S!fmt);
    writeln(str);
    assert(str == "a=1 is one. _a0=D-lang is nice. a=001, A.a=0.123");
    }

    for (int j = 3; j--> 0; ) {
      writeln(mixin(_S!"{j}"));
    }
}

// T: class type
string fieldNames(T)() if (isAggregateType!T) {
  auto fields = FieldNameTuple!(T);
  alias types = Fields!T;
  string[] names;
  foreach (i, f; fields) {
    if (!(isAggregateType!(types[i]))) {  // only basic type for now
      names ~= f;
    }
  }
  string s = fullyQualifiedName!T ~"({"~ join(names, ";") ~"})";
  return s;
}


template ToString(T) {
  override string toString() {
    return mixin(_S!(fieldNames!T));
  }
}


unittest {
  class Point {
    int x, y;

    mixin ToString!Point;
  }

  class Point3D : Point {
    int z;
  }

  Point p = new Point3D();
  p.x = 3;
  p.y = 9;
  writeln(p);
  string s = p.toString();
  assert(s.endsWith(".Point(x=3 y=9)"));
}


/* ========================================================================== *\
  common mixin template:
  -- declare ReadOnly  attr
  -- declare ReadWrite attr
  -- Singleton
  -- AtomicCounted
\* ========================================================================== */
enum ReadOnly_Decl = q{
  private       mixin("T    _" ~name~ " = value;");
  public  final mixin("T     " ~name~ "() { return _" ~name~ "; }");
};

enum ReadWrite_Decl = ReadOnly_Decl ~ q{
  public  final mixin("auto  " ~name~ "(T val)   { _" ~name~ " = val; return this; }");
};

mixin template ReadOnly(T, string name, T value = T.init) {
  mixin(ReadOnly_Decl);
}

mixin template ReadWrite(T, string name, T value = T.init) {
  mixin(ReadWrite_Decl);
}


unittest {

class Point {
  mixin ReadWrite!(int,     "x");
  mixin ReadWrite!(double,  "y");
  mixin ReadWrite!(string,  "z");
}
  auto fields = FieldNameTuple!(Point);
  // string fs = join(fields);
  // assert(`_x_y_z` == fs);
  writeln(fields);
}


/* -------------------------------------------------------------------------- *\
\* -------------------------------------------------------------------------- */
template Singleton(T) {

    static if (!is(T == class)) {
        enum misUsage = `Mis-usage error: Singleton pattern is intended to be only applied to class! e.g. not struct.
Please check https://en.wikipedia.org/wiki/Singleton_pattern for usage pattern.
And check https://wiki.dlang.org/Low-Lock_Singleton_Pattern for this template implementation.
`;
        pragma(msg, misUsage);
        static assert(false, misUsage);
    }

    private this() {}  // private, so nobody can new T()!

    // Cache instantiation flag in thread-local bool
    // Thread local
    private static bool instantiated_;

    // Thread global
    private __gshared T instance_;

    static T getSingleton()
    {
        if (!instantiated_)
        {
            synchronized(T.classinfo)
            {
                if (!instance_)
                {
                    instance_ = new T();
                }

                instantiated_ = true;
            }
        }

        return instance_;
    }
}

/* -------------------------------------------------------------------------- *\
  atomic
\* -------------------------------------------------------------------------- */
template AtomicCounted(T=long) {  // better use *signed* 64 bits, easy to detect neg values
  align(size_t.sizeof) shared
    mixin ReadOnly!(T, "counter");  // TODO: make sure no writer!

 public:
  // atomicOp, is shared necessary?
  T incCount() /*shared*/ {core.atomic.atomicOp!"+="(_counter, 1); return _counter;}
  T decCount() /*shared*/ {core.atomic.atomicOp!"-="(_counter, 1); return _counter;}
}

/* -------------------------------------------------------------------------- *\
  mixin DeclImmutableString!("unit", "test");
  // expand to:
  immutable string UNIT = "unit";
  immutable string TEST = "test";
\* -------------------------------------------------------------------------- */
mixin template DeclImmutableString(T...) {
  static foreach(arg; T) {
    immutable mixin("string " ~ arg.toUpper() ~" = `"~ arg ~"`;");
  }
}

unittest {
  mixin DeclImmutableString!("unit", "test");
  assert(UNIT == "unit");
  assert(TEST == "test");
}
