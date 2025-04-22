
/* Copyright (C) 1991-2022 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <https://www.gnu.org/licenses/>.  */




/* This header is separate from features.h so that the compiler can
   include it implicitly at the start of every compilation.  It must
   not itself include <features.h> or any other header that includes
   <features.h> because the implicit include comes before any feature
   test macros that may be defined in a source file before it first
   explicitly includes a system header.  GCC knows the name of this
   header in order to preinclude it.  */

/* glibc's intent is to support the IEC 559 math functionality, real
   and complex.  If the GCC (4.9 and later) predefined macros
   specifying compiler intent are available, use them to determine
   whether the overall intent is to support these features; otherwise,
   presume an older compiler has intent to support these features and
   define these macros by default.  */
/* wchar_t uses Unicode 10.0.0.  Version 10.0 of the Unicode Standard is
   synchronized with ISO/IEC 10646:2017, fifth edition, plus
   the following additions from Amendment 1 to the fifth edition:
   - 56 emoji characters
   - 285 hentaigana
   - 3 additional Zanabazar Square characters */

module jdiutil.memory;


        import core.stdc.config;
        import core.stdc.stdarg: va_list;
        static import core.simd;
        static import std.conv;

        struct Int128 { long lower; long upper; }
        struct UInt128 { ulong lower; ulong upper; }

        struct __locale_data { int dummy; } // FIXME



alias _Bool = bool;
struct dpp {
    static struct Opaque(int N) {
        void[N] bytes;
    }
    // Replacement for the gcc/clang intrinsic
    static bool isEmpty(T)() {
        return T.tupleof.length == 0;
    }
    static struct Move(T) {
        T* ptr;
    }
    // dmd bug causes a crash if T is passed by value.
    // Works fine with ldc.
    static auto move(T)(ref T value) {
        return Move!T(&value);
    }
    mixin template EnumD(string name, T, string prefix) if(is(T == enum)) {
        private static string _memberMixinStr(string member) {
            import std.conv: text;
            import std.array: replace;
            return text(` `, member.replace(prefix, ""), ` = `, T.stringof, `.`, member, `,`);
        }
        private static string _enumMixinStr() {
            import std.array: join;
            string[] ret;
            ret ~= "enum " ~ name ~ "{";
            static foreach(member; __traits(allMembers, T)) {
                ret ~= _memberMixinStr(member);
            }
            ret ~= "}";
            return ret.join("\n");
        }
        mixin(_enumMixinStr());
    }
}

extern(C++)
{

    interface SharedCArrayI(T)
    {
    @nogc:
            public:

        abstract ref T at(c_long) @nogc nothrow;

        abstract c_long size() @nogc nothrow;

        abstract c_long length() @nogc nothrow;
    }
}



import core.memory;

import std.exception;
import std.experimental.logger;
import std.stdio;
import std.traits;

import containers.hashmap; // emsi_containers

version (unittest) {
public import fluent.asserts;
}

public import jdiutil.jdiutil;

alias logger = std.experimental.logger;

/* ========================================================================== *   GC-heap free
e
\* ========================================================================== */
// Deprecation: The `delete` keyword has been deprecated.  Use `object.destroy()` (and `core.memory.GC.free()` if applicable) instead.            
// usually deepDelete=false to be safe, i.e shallow delete only the containers itself, (the containees are not recursively gcDelete-d)
// if the user is sure that `obj` has neither cycle nor shared sub-object, then deepDelete=true will recursively gcDelete every thing from the root
void gcDelete(T)(ref T obj, bool deepDelete=false) {

  // TODO: for array|aa type T, shall we deep delete all the containees (of std containers array & aa) here?
  // for user defined class types, user need to define the dtor to delete each field

  // static if (is(T == class)) {  // TODO: also for pointer type
  destroy!true(obj); // although we are going to GC.free it, we want to initialize, so e.g. remove reference counter for sub-objects
  // }

  static if (is(T == class) || std.traits.isArray!T) { // TODO: also for pointer type
    core.memory.GC.free(cast(void*)obj);
    obj = null;
  }

}



/* ========================================================================== *   non-GC-heap alloc and free
e
\* ========================================================================== */
// https://wiki.dlang.org/Memory_Management#Explicit_Class_Instance_Allocation
// https://forum.dlang.org/post/pqykojxbmjaiwzxcdxnh@forum.dlang.org
// I recommend using libc's malloc and free instead of GC.malloc and GC.free.
// Reason: you avoid increasing the GC's heap size.
// Note that you only need to use GC.addRange if the objects you allocate themselves point to other objects.
// NOTE: the return type has to be auto, for struct, will return T*, for class will return T 
auto heapAlloc(T, bool notifyGC, Args...) (Args args) {
    import std.conv : emplace;
    import core.stdc.stdlib : malloc;
    import core.memory : GC;

    static if (is(T == struct)) {
      auto size = T.sizeof;
    } else {
      // get class size of class instance in bytes
      auto size = __traits(classInstanceSize, T);
    }

    // allocate memory for the object
    auto memory = malloc(size)[0..size];
    if(!memory)
    {
        import core.exception : onOutOfMemoryError;
        onOutOfMemoryError();
    }

    // writeln("Memory allocated");

    // notify garbage collector that it should scan this memory
    static if (notifyGC) {
      GC.addRange(memory.ptr, size);
    }

    // call T's constructor and emplace instance on
    // newly allocated memory
    return emplace!(T, Args)(memory, args);
}

// NOTE: the return type has to be auto, for struct, will return T*, for class will return T 
auto heapAlloc(T, Args...) (Args args) {
  return heapAlloc!(T, false, Args)(args);
}

void heapFree(T, bool notifyGC)(T obj) {
    import core.stdc.stdlib : free;
    import core.memory : GC;

    // calls obj's destructor
    destroy(obj);

    // garbage collector should no longer scan this memory
    static if (notifyGC) {
      GC.removeRange(cast(void*)obj);
    }

    // free memory occupied by object
    free(cast(void*)obj);

    // writeln("Memory deallocated");
}

void heapFree(T)(T obj) {
  heapFree!(T, false)(obj);
}


unittest {
  class TestClass {
    int x;

    this(int x)
    {
        writeln("TestClass's constructor called");
        this.x = x;
    }

    ~this()
    {
        writeln("TestClass's destructor called");
    }
  }

  void main() {
    // allocate new instance of TestClass on the heap
    auto test = heapAlloc!TestClass(42);
    scope(exit)
    {
        heapFree(test);
    }

    writefln("test.x = %s", test.x);
  }

  main();

}

/* ========================================================================== *  object pool
l
\* ========================================================================== */
const int EACH_WAIT_MILLISECONDS = 100;

// allocate an array of T at init, and recycle the object to reduce memory usage
// TODO: add linked-list for size unbounded pool
template Recyclable(T) {
  static if (is(T == struct)) {
    alias RefT = T*;
  } else {
    alias RefT = T;
  }

  // https://issues.dlang.org/show_bug.cgi?id=20838#c12
  // manually take care of required 16-bytes alignment: for cas(CMPXCHG16B)
  public align(16) shared bool taken; // core.atomic.cas to select free one to use

  static __gshared T[] pool;

  static void initObjectPool(long size) {
    pool = new T[size]; // why in actual run, we need more than numWorkerThreads?

    static if (is(T == class)) { // TODO: heapAllocN
      foreach (i; 0 .. size) {
        pool[i] = new T();
      }
    }
  }

  static RefT make(int wait=int.max) { // how many times should wait, by default will wait
    enforce(pool.length > 0);
    for (;;) {
      foreach (ref nd; pool) { // loop on the pool array
        if (core.atomic.cas(&(nd.taken), false, true)) { // atomic op!
          enforce(nd.taken);
          static if (is(T == struct)) {
            return &nd;
          } else {
            return nd;
          }
        }
      }

      if (wait-- > 0) {
        Thread.sleep(dur!("msecs")(EACH_WAIT_MILLISECONDS));
      } else {
        return null;
      }
    }
    return null;
  }

}

// release the object, and put back into the recycle bin
void recycle(T)(T needleDev) {
  if (needleDev is null) {
    return;
  }
  bool released = (core.atomic.cas(&(needleDev.taken), true, false)); // atomic op!
  enforce(released);
}



/* ========================================================================== *\* ========================================================================== */

// from: https://forum.dlang.org/post/acafsosotrjdswwuklob@forum.dlang.org
// use the same name as array.dup https://dlang.org/spec/arrays.html
// https://dlang.org/library/rt/lifetime/_d_newclass.html
extern (C) Object _d_newclass(TypeInfo_Class ci);

T dup(T)(T obj) if (is(T == class)) { // shallowClone
    if (obj is null)
        return null;
    ClassInfo ci = obj.classinfo;
    size_t start = Object.classinfo.m_init.length;
    size_t end = ci.m_init.length;
    T clone = cast(T)_d_newclass(ci);
    (cast(void*)clone)[start .. end] = (cast(void*)obj)[start .. end];
    return clone;
}


/* ========================================================================== *   shared array or AA, can be `new`-ed on the heap, and shared between multi-threads
s

   https://forum.dlang.org/post/xfjrizobwiidaiwylheq@forum.dlang.org
\* ========================================================================== */
class SharedAA(KeyT, ValT) { // wrapper class to make the inner `aa` acts like a class object
  // https://forum.dlang.org/thread/vkkwysusmnivkooglgwd@forum.dlang.org
  // life is too short to debug dlang built-in AA to right, let's just use HashMap from emsi_containers
  public HashMap!(KeyT, ValT) aa;
  alias aa this; // make the associative arrays syntax on SharedAA object to work

  ~this() {
    foreach (ref kv; aa.byKeyValue) { // deep delete all the containee
      gcDelete(kv.key);
      gcDelete(kv.value);
    }
  }
}


// array is passed by value (e.g. as func param), to pass by reference, let's use class
class SharedArray(T) { // pure D class
 public:
  T[] array;
  alias array this; // make the array syntax on SharedArray object to work

  ~this() {
    foreach (ref item; array) { // deep delete all the containee
      gcDelete(item);
    }
    gcDelete(array);
  }

  static if (std.traits.isNumeric!(T)) {
    enum T defaultInitValue = 0;
  } else {
    enum T defaultInitValue = T.init;
  }

  this(size_t n=0, T initValue=defaultInitValue) {
    array = new T[n];
    array[] = initValue;
  }


  inout ref inout(T) opIndex(ptrdiff_t i) @nogc nothrow { // can have negative index
    return (i >= 0) ?
        array[ i] :
        array[$+i];
  }

  @disable final: // bug: https://forum.dlang.org/thread/pjxwebeyiypgtgxqmcdp@forum.dlang.org
    // remove the array's range interface
    T front();
    void popFront();
    bool empty();
}


extern(C++) {

// SharedCArray with C++ linkage cannot inherit from class `SharedArray` with D linkage
class SharedCArray(T) : SharedCArrayI!(T) {
@nogc: // will allocated in the D side, and export to C++, so @nogc
 public:
  T[] array;

  override ref T at(c_long i) @nogc nothrow { // can have negative index
    return array[i];
  }

  override c_long size() @nogc nothrow {
    return array.length;
  }

  override c_long length() @nogc nothrow {
    return array.length;
  }
}

}


alias SharedDoubleArray = SharedArray!double;
alias SharedLongArray = SharedArray!long;
alias SharedCStrArray = SharedCArray!(char*); // .cstr()


unittest {
  auto signs = new SharedDoubleArray(3);
  foreach (s; -1..2) {
    signs[s] = s;
  }
  logger.info(mixin(_S!"{signs.array}"));
  Assert.equal(signs[-1], -1);
  Assert.equal(signs[ 0], 0);
  Assert.equal(signs[ 1], 1);
}

/* ========================================================================== *\* ========================================================================== */
