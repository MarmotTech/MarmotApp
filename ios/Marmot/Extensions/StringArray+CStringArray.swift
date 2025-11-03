import Foundation

extension Array where Element == String {
    func toCStringArray() -> UnsafeMutablePointer<UnsafePointer<CChar>?> {
        let count = self.count
        let cArray = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: count)
        
        for (index, string) in self.enumerated() {
            let cString = strdup(string)
            cArray[index] = UnsafePointer(cString)
        }
        
        return cArray
    }
}

extension String {
    func stringToCString() -> UnsafePointer<CChar>? {
        return (self as NSString).utf8String
    }
}

func freeCStringArray(_ array: UnsafeMutablePointer<UnsafePointer<CChar>?>, count: Int) {
    for i in 0..<count {
        if let cString = array[i] {
            free(UnsafeMutablePointer(mutating: cString))
        }
    }
    array.deallocate()
}
