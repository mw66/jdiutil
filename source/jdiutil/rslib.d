module jdiutil.rslib;

import core.stdc.stdint;
// link to rslib.a

alias HandleT = uintptr_t;

extern (C) {

HandleT dashmap_new();

HandleT segqueue_new();

uint64_t dashmap_get(HandleT handle, uint64_t key);

uint64_t dashmap_insert(HandleT handle, uint64_t key, uint64_t val);

uint64_t segqueue_pop(HandleT handle);

void segqueue_push(HandleT handle, uint64_t val);

} // extern "C"

// wrapper of https://docs.rs/crossbeam-queue/0.3.5/crossbeam_queue/struct.SegQueue.html
class SegQueue {
  HandleT handle;
  this() {
    handle = segqueue_new();
  }
}

unittest {
  {
  SegQueue queue = new SegQueue();
  assert(queue.handle == 0);
  }
  {
  SegQueue queue = new SegQueue();
  assert(queue.handle == 1);
  }
}
