
use dashmap::DashMap;
use crossbeam_queue::SegQueue;
use once_cell::unsync::OnceCell;  // shall we use sync/unsync?

// use lazy_static::lazy_static;

type HDashMap = DashMap<u64, u64>;  // DashMap that stores u64 value from D side
type HashMapsT = Vec<HDashMap>;
type HandleT = usize;

// https://github.com/rust-lang-nursery/lazy-static.rs/blob/master/examples/mutex_map.rs
/*
lazy_static! {
  static ref HASHMAPS: HashMapsT = {
    let mut vec = Vec::<HDashMap>::new();
    vec
  };
}
*/

static mut HASHMAPS: OnceCell<HashMapsT> = OnceCell::with_value(HashMapsT::new());

// NOTE: `dashmap_new` is NOT thread-safe, since it will modify the underlying container Vec
// so in the most called function dashmap_get, dashmap_insert, the HASHMAPS.get() no need to be sync-ed
// othewise, it will be very slow
// return a handle
#[no_mangle]
pub unsafe extern "C" fn dashmap_new() -> HandleT {
  let map = HDashMap::new();
  let handle:HandleT = HASHMAPS.get().unwrap().len();
  HASHMAPS.get_mut().unwrap().push(map);

  return handle;
}

#[no_mangle]
pub unsafe extern "C" fn dashmap_get(handle:HandleT, key:u64) -> u64 {
  *(HASHMAPS.get().unwrap().get(handle).unwrap().get(&key).unwrap())
}

// return the old val
#[no_mangle]
pub unsafe extern "C" fn dashmap_insert(handle:HandleT, key:u64, val:u64) -> u64 {
  HASHMAPS.get().unwrap().get(handle).unwrap().insert(key, val).unwrap()
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        let result = 2 + 2;
        assert_eq!(result, 4);
    }
}
