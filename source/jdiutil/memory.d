module jdiutil.memory;

import core.memory;
import std.experimental.logger;
import std.stdio;
import std.traits;

version (unittest) {
public import fluent.asserts;
}

public import jdiutil.jdiutil;

alias logger = std.experimental.logger;

/* ========================================================================== *\
   GC-heap free
\* ========================================================================== */
// Deprecation: The `delete` keyword has been deprecated.  Use `object.destroy()` (and `core.memory.GC.free()` if applicable) instead.            
// usually deepDelete=false to be safe, i.e shallow delete only the containers itself, (the containees are not recursively gcDelete-d)
// if the user is sure that `obj` has neither cycle nor shared sub-object, then deepDelete=true will recursively gcDelete every thing from the root
void gcDelete(T)(ref T obj, bool deepDelete=false) {

  // TODO: for array|aa type T, shall we deep delete all the containees (of std containers array & aa) here?
  // for user defined class types, user need to define the dtor to delete each field

  // static if (is(T == class)) {  // TODO: also for pointer type
  destroy!true(obj);  // although we are going to GC.free it, we want to initialize, so e.g. remove reference counter for sub-objects
  // }

  static if (is(T == class) || std.traits.isArray!T) {  // TODO: also for pointer type
    core.memory.GC.free(cast(void*)obj);
    obj = null;
  }

}



/* ========================================================================== *\
   non-GC-heap alloc and free
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

/* ========================================================================== *\
\* ========================================================================== */
// from: https://forum.dlang.org/post/acafsosotrjdswwuklob@forum.dlang.org
// use the same name as array.dup https://dlang.org/spec/arrays.html
extern (C) Object _d_newclass(TypeInfo_Class ci);

T dup(T)(T obj) if (is(T == class)) {  // shallowClone
    if (obj is null)
        return null;
    ClassInfo ci = obj.classinfo;
    size_t start = Object.classinfo.m_init.length;
    size_t end = ci.m_init.length;
    T clone = cast(T)_d_newclass(ci);
    (cast(void*)clone)[start .. end] = (cast(void*)obj)[start .. end];
    return clone;
}


/* ========================================================================== *\
  shared array or AA, can be `new`-ed on the heap, and shared between multi-threads
\* ========================================================================== */
class SharedAA(KeyT, ValT) {  // wrapper class to make the inner `aa` acts like a class object
  public ValT[KeyT] aa;
  alias aa this;  // make the associative arrays syntax on SharedAA object to work

  ~this() {
    foreach (ref kv; aa.byKeyValue) {  // deep delete all the containee
      gcDelete(kv.key);
      gcDelete(kv.value);
    }
  }
}

// array is passed by value (e.g. as func param), to pass by reference, let's use class
class SharedArray(T) {
  public T[] array;
  alias array this;  // make the array syntax on SharedArray object to work

  ~this() {
    foreach (ref item; array) {  // deep delete all the containee
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

  inout ref inout(T) opIndex(ptrdiff_t i) {  // can have negative index
    return (i >= 0) ?
        array[  i] :
        array[$+i];
  }

  @disable final:  // bug: https://forum.dlang.org/thread/pjxwebeyiypgtgxqmcdp@forum.dlang.org
    // remove the array's range interface
    T front();
    void popFront();
    bool empty();
}


alias SharedDoubleArray = SharedArray!double;
alias SharedLongArray   = SharedArray!long;


unittest {
  auto signs = new SharedDoubleArray(3);
  foreach (s; -1..2) {
    signs[s] = s;
  }
  logger.info(mixin(_S!"{signs.array}"));
  Assert.equal(signs[-1], -1);
  Assert.equal(signs[ 0],  0);
  Assert.equal(signs[ 1],  1);
}

/* ========================================================================== *\
\* ========================================================================== */
