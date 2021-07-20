//
//  Util.swift
//  Splitter
//
//  Created by Simon Bohnen on 18.07.21.
//

import Foundation

extension Array where Element: AnyObject {
    mutating func remove(_ element: Element) {
        return self.removeAll {
            $0 === element
        }
    }
}

extension Double {
    func isCloseTo(_ b: Double) -> Bool {
        return fabs(self - b) < 0.0001
    }
    
    mutating func makeNegative() {
        if self > 0 {
            self *= -1
        }
    }
    
    mutating func makePositive() {
        if self < 0 {
            self *= -1
        }
    }
}

extension Array {
    func max<T: Comparable>(metric: (Element) -> T) -> Element? {
        return self.max {
            metric($0) < metric($1)
        }
    }
}

extension Array where Element: AnyObject {
    mutating func subtract(_ other: [Element]) {
        self.removeAll { s in
            other.contains { o in
                s === o
            }
        }
    }
}

extension String {
    static let nf: NumberFormatter = {
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "de_DE")
        nf.numberStyle = NumberFormatter.Style.decimal
        return nf
    }()
    
    func findNumberInMiddle() -> Double? {
        let firstIndex = self.firstIndex {
            $0.isNumber ||
            $0 == "-"
        }!
        let restString = String(self[firstIndex...])
        let germanRestString = restString.replacingOccurrences(of: ".", with: ",")
        
        let endIndex = germanRestString.index(germanRestString.firstIndex(of: ",")!, offsetBy: 2)
        var germanNumber = String(germanRestString[...endIndex])
        
        germanNumber = germanNumber.replacingOccurrences(of: " ", with: "")
        
        return Self.nf.number(from: germanNumber)?.doubleValue
    }
}
