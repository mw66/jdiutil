
// to make dpp, D's extern(C++) all work
// use the C++ naming, since they are intended to be used in C++
// make sure no func name conflict with the underlying D class
// C++ base class `SharedCArrayI` needs at least one virtual function

template<class T> class SharedCArrayI {
 public:
  virtual T& at(long i) = 0;  // can have negative index
  virtual long size() = 0;
};

