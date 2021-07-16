//
//  ReceiptViewController.swift
//  Splitter
//
//  Created by Simon Bohnen on 15.07.21.
//

import Foundation
import UIKit
import Vision
import StringMetric

class ReceiptViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var positionTableView: UITableView!
    
    var sum: Double?
    var prices: [Double] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        positionTableView.delegate = self
        positionTableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section > 0 {
            return 0
        }
        return prices.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "positionCell", for: indexPath) as! PositionCell
        
        let index = indexPath.row
        
        if index == prices.count {
            //Sum row
            cell.position.text = "Summe"
            cell.price.text = "\(sum ?? 666)€"
        } else {
            cell.position.text = "Position \(index + 1)"
            cell.price.text = "\(prices[index])€"
        }
        
        return cell
    }
    
    func addPositions(fromObservations observations: [VNRecognizedTextObservation]) {
        /* Find EUR observation on right side of bill
         *   get x coord of prices
         * Find SUMME EUR label, get y coord
         *   find total price to the right of that
         * look for positions in between that and match prices and positions
         */
        
        let bestTexts = observations
            .compactMap {
                return $0.topCandidates(1).first?.string
            }
        
        let eurIndex = findIndexOfBestMatch(for: "EUR", in: bestTexts)
        let eurObs = observations[eurIndex]
        let pricesX = eurObs.boundingBox.midX
        //print(bestTexts[eurIndex])
        //print(eurObs.topLeft)
        
        let summeEurIndex = findIndexOfBestMatch(for: "SUMME EUR", in: bestTexts)
        let summeEurObs = observations[summeEurIndex]
        let sumY = summeEurObs.boundingBox.midY
        
        let totalSumObs = observations.filter { obs in
            obs !== summeEurObs && obs.surrounds(y: sumY)
        }.first
        guard let totalSumObservation = totalSumObs else {
            print("Could not find total sum on correct height")
            return
        }
        
        // let totalSumX = totalSumObservation.boundingBox.midX
        // TODO test if is convertible to number
        
        let sumString = totalSumObservation.bestString().replacingOccurrences(of: " ", with: "")
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "de_DE")
        nf.numberStyle = NumberFormatter.Style.decimal
        if let number = nf.number(from: sumString) {
            sum = number.doubleValue
        } else {
            print("Could not convert sum string to number")
        }
        
        // Find prices
        self.prices = observations
            .filter { obs in
                obs !== totalSumObservation &&
                obs !== eurObs &&
                totalSumObservation.surrounds(x: obs.boundingBox.midX) &&
                obs.surrounds(x: pricesX) &&
                obs.isAbove(totalSumObservation) &&
                !obs.bestString().contains("EUR")
            }
            .map { obs -> String in
                let str = obs.bestString()
                let firstSpace = str.lastIndex(where: { chr in
                    chr.isNumber
                })!
                return String(str[...firstSpace])
            }
            .map { priceStr in
                let germanString = priceStr.replacingOccurrences(of: ".", with: ",")
                if let price = nf.number(from: germanString) {
                    return price.doubleValue
                } else {
                    print("Could not convert string \(germanString) to number")
                    return 0
                }
            }
        
        print("Diff: \(self.prices.reduce(0, +) - (self.sum ?? 0))")
        if self.prices.reduce(0, +).isCloseTo(self.sum ?? 0) {
            print("Fucking party hard!")
        } else {
            print("F")
        }
    }
    
    private func findIndexOfBestMatch(for str: String, in arr: [String]) -> Int {
        var minDistance = Int.max
        var minIndex = -1
        for i in 0 ..< arr.count {
            let dist = str.distanceLevenshtein(between: arr[i])
            if dist < minDistance {
                minDistance = dist
                minIndex = i
            }
        }
        return minIndex
    }
}

extension VNDetectedObjectObservation {
    func surrounds(x: CGFloat) -> Bool {
        return self.boundingBox.minX <= x && x <= self.boundingBox.maxX
    }
    
    func surrounds(y: CGFloat) -> Bool {
        return self.boundingBox.minY <= y && y <= self.boundingBox.maxY
    }
    
    func isBelow(_ otherObservation: VNDetectedObjectObservation) -> Bool {
        return self.boundingBox.maxY < otherObservation.boundingBox.minY
    }
    
    func isAbove(_ otherObservation: VNDetectedObjectObservation) -> Bool {
        return self.boundingBox.minY > otherObservation.boundingBox.maxY
    }
}

extension VNRecognizedTextObservation {
    func bestString() -> String {
        self.topCandidates(1).first!.string
    }
}

extension Double {
    func isCloseTo(_ b: Double) -> Bool {
        return fabs(self - b) < 0.0001
   }
}
