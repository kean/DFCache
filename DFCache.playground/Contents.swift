import DFCache
import XCPlayground

let cache = DFCache(name: "playground")
/*: 
Store, retrieve and remove object
*/
cache.storeObject("TestString", forKey: "Key1")
cache.cachedObjectForKey("Key1") {
    let obj = $0
}
cache.removeObjectForKey("Key1")
/*: 
Set and read metadata
*/
cache.storeObject("Object", forKey: "Key2")
cache.setMetadata(["key1" : "value1"], forKey: "Key2")
let meta = cache.metadataForKey("Key2")

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
