#include <cstdarg>
#include <cstdint>
#include <cstdlib>
#include <ostream>
#include <new>

using HandleT = uintptr_t;

extern "C" {

HandleT dashmap_new();

HandleT segqueue_new();

uint64_t dashmap_get(HandleT handle, uint64_t key);

uint64_t dashmap_insert(HandleT handle, uint64_t key, uint64_t val);

uint64_t segqueue_pop(HandleT handle);

void segqueue_push(HandleT handle, uint64_t val);

} // extern "C"
