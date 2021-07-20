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
    @IBOutlet weak var sumLabel: UILabel!
    
    var sum: Double?
    var positions: [String] = []
    var prices: [Double] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        positionTableView.delegate = self
        positionTableView.dataSource = self
        i
        sumLabel.text = String(format: "%.2f€", sum ?? 666.0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section > 0 {
            return 0
        }
        return prices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "positionCell", for: indexPath) as! PositionCell
        
        let index = indexPath.row
        cell.position.text = positions[index]
        cell.price.text = String(format: "%.2f€", prices[index])
        
        return cell
    }
    
    func addPositions(fromObservations vnObservations: [VNRecognizedTextObservation]) {
        /* Find EUR observation on right side of bill
         *   get x coord of prices
         * Find SUMME EUR label, get y coord
         *   find total price to the right of that
         * look for positions in between that and match prices and positions
         */
        
        // TODO bei 7A6EFAA1-9DD4-4CB0-85DA-3A28DD42695F.jpg erkennt der einen Preis nicht richtig
        var observations = vnObservations.map {
            Observation($0)
        }
        
        let eurObservation = findBestMatch(for: "EUR", in: observations)
        observations.remove(eurObservation)
        //let pricesX = eurObservation.obs.boundingBox.midX
        //print(bestTexts[eurIndex])
        //print(eurObs.topLeft)
        
        let summeEurObservation = findBestMatch(for: "SUMME EUR", in: observations)
        observations.remove(summeEurObservation)
        //let sumY = summeEurObservation.obs.boundingBox.midY
        
        let totalPriceObsCandidates = observations.filter { obs in
            obs.overlapsVertically(with: summeEurObservation) &&
            obs.isToTheRight(of: summeEurObservation) &&
            obs.isBelow(eurObservation) &&
            obs.overlapsHorizontally(with: eurObservation)
        }
        let totalPriceObs = totalPriceObsCandidates.first
        guard let totalPriceObservation = totalPriceObs else {
            print("Could not find total sum on correct height")
            return
        }
        
        observations.remove(totalPriceObservation)
        // let totalSumX = totalSumObservation.boundingBox.midX
        // TODO test if is convertible to number
        if let number = totalPriceObservation.bestString.findNumberInMiddle() {
            sum = number
        } else {
            print("Could not convert sum string to number")
        }
        
        // Find Posten text
        let postenObservation = findBestMatch(for: "Posten: ", in: observations)
        observations.remove(postenObservation)
        let postenString = postenObservation.bestString
        let firstNumberIndex = postenString.firstIndex {
            $0.isNumber
        }!
        let postenCount = Int(postenString[firstNumberIndex...])
        
        // Find prices
        let priceObservationCandidates = observations
            .filter { obs in
                obs.overlapsHorizontally(with: totalPriceObservation) &&
                obs.overlapsHorizontally(with: eurObservation) &&
                obs.isAbove(totalPriceObservation) &&
                obs.isBelow(eurObservation) &&
                !obs.bestString.contains("EUR") // To exclude prices for weight
            }
        
        observations.subtract(priceObservationCandidates)
        
        let priceObservations = priceObservationCandidates.map { obs -> PriceObservation in
            let price = obs.bestString.findNumberInMiddle() ?? 0
            return PriceObservation(obs, price)
        }
        
        // Find position names
        var positionObservationCandidates = observations.filter {
            !$0.isBelow(summeEurObservation) &&
            $0.isToTheLeft(of: eurObservation)
        }
        
        var positionObservations = [PositionObservation]()
        
        for priceObs in priceObservations {
            // Try to find the position for this price
            let positionCandidates = positionObservationCandidates.filter {
                $0.overlapsVertically(with: priceObs)
            }
            let position = positionCandidates.max(metric: { posObservation -> CGFloat in
                let bbpos = posObservation.obs.boundingBox
                let bbprice = priceObs.obs.boundingBox
                return min(bbpos.maxY - bbprice.minY, bbprice.maxY - bbpos.minY)
            })!
            
            let positionObservation = PositionObservation(position, priceObs)
            positionObservations.append(positionObservation)
            priceObs.positionObservation = positionObservation
            
            positionObservationCandidates.remove(position)
            observations.remove(position)
        }
        
        for posObs in positionObservations {
            let lowerPos = posObs.bestString.lowercased()
            let containsLeergut = lowerPos.contains("leergut entl") || lowerPos.contains("leergut einweg")
            let priceIsPositive = posObs.priceObservation.price > 0
            if containsLeergut && priceIsPositive {
                posObs.priceObservation.price.makeNegative()
            } else if !containsLeergut && !priceIsPositive {
                // Must be a positive price
                posObs.priceObservation.price.makePositive()
            }
        }
        
        self.positions = positionObservations.map {
            $0.bestString
        }
        
        self.prices = priceObservations.map {
            $0.price
        }
        
        print("Diff: \(self.prices.reduce(0, +) - (self.sum ?? 0))")
        if self.prices.reduce(0, +).isCloseTo(self.sum ?? 0) {
            print("Sum matches!")
        } else {
            print("Sum does not match!")
        }
        
        if postenCount == priceObservations.count {
            // Doesn't work yet because of multiplicities!
            print("Found all posten probably!")
        }
    }
    
    private func findBestMatch(for str: String, in observations: [Observation]) -> Observation {
        var minDistance = Int.max
        var bestMatch = observations.first!
        for o in observations {
            let dist = str.distanceLevenshtein(between: o.bestString)
            if dist < minDistance {
                minDistance = dist
                bestMatch = o
            }
        }
        return bestMatch
    }
}
