module jdiutil.rslib;

// link to rslib.a

alias HandleT = size_t;

extern (C) {
size_t segqueue_new();
}

// wrapper of https://docs.rs/crossbeam-queue/0.3.5/crossbeam_queue/struct.SegQueue.html
class SegQueue {
  HandleT handle;
  this() {
    handle = segqueue_new();
  }
}
