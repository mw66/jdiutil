use std::sync::Mutex;

use dashmap::DashMap;
use crossbeam_queue::SegQueue;

use lazy_static::lazy_static;

type HDashMap = DashMap<u64, u64>;  // DashMap that stores u64 value from D side
type HandleT = usize;

// https://github.com/rust-lang-nursery/lazy-static.rs/blob/master/examples/mutex_map.rs
lazy_static! {
  static ref HASHMAPS: Mutex<Vec<HDashMap>> = {
    let mut vec = Vec::<HDashMap>::new();
    Mutex::new(vec)
  };
}

// return a handle
#[no_mangle]
pub unsafe extern "C" fn dashmap_new() -> HandleT {
  let map = HDashMap::new();
  let handle:HandleT = HASHMAPS.lock().unwrap().len();
  HASHMAPS.lock().unwrap().push(map);

  return handle;
}

pub unsafe extern "C" fn dashmap_get(handle:HandleT, key:u64) -> u64 {
  *HASHMAPS.lock().unwrap().get(handle).unwrap().get(&key).unwrap()
}

pub unsafe extern "C" fn dashmap_insert(handle:HandleT, key:u64, val:u64) -> u64 {
  HASHMAPS.lock().unwrap().get(handle).unwrap().insert(key, val).unwrap()
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        let result = 2 + 2;
        assert_eq!(result, 4);
    }
}
