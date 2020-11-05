import std.stdio;

// https://wiki.dlang.org/Memory_Management#Explicit_Class_Instance_Allocation
 
class TestClass 
{
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
 
T heapAllocate(T, Args...) (Args args) 
{
    import std.conv : emplace;
    import core.stdc.stdlib : malloc;
    import core.memory : GC;
    
    // get class size of class instance in bytes
    auto size = __traits(classInstanceSize, T);
    
    // allocate memory for the object
    auto memory = malloc(size)[0..size];
    if(!memory)
    {
        import core.exception : onOutOfMemoryError;
        onOutOfMemoryError();
    }                    
    
    writeln("Memory allocated");

    // notify garbage collector that it should scan this memory
    GC.addRange(memory.ptr, size);
    
    // call T's constructor and emplace instance on
    // newly allocated memory
    return emplace!(T, Args)(memory, args);                                    
}
 
void heapDeallocate(T)(T obj) 
{
    import core.stdc.stdlib : free;
    import core.memory : GC;
    
    // calls obj's destructor
    destroy(obj); 

    // garbage collector should no longer scan this memory
    GC.removeRange(cast(void*)obj);
    
    // free memory occupied by object
    free(cast(void*)obj);
    
    writeln("Memory deallocated");
}
       
void main() 
{
    // allocate new instance of TestClass on the heap
    auto test = heapAllocate!TestClass(42);
    scope(exit)
    {
        heapDeallocate(test);    
    }
    
    writefln("test.x = %s", test.x);
}
