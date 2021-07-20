//
//  ClassifiedObservation.swift
//  Splitter
//
//  Created by Simon Bohnen on 16.07.21.
//

import Foundation
import Vision

class Observation {
    let obs: VNRecognizedTextObservation
    let bestString: String
    
    init(_ vnObservation: VNRecognizedTextObservation) {
        self.obs = vnObservation
        self.bestString = vnObservation.topCandidates(1).first!.string
    }
    
    init(_ observation: Observation) {
        self.obs = observation.obs
        self.bestString = observation.bestString
    }
    
    func surrounds(x: CGFloat) -> Bool {
        return obs.boundingBox.minX <= x && x <= obs.boundingBox.maxX
    }
    
    func surrounds(y: CGFloat) -> Bool {
        return obs.boundingBox.minY <= y && y <= obs.boundingBox.maxY
    }
    
    func isBelow(_ other: Observation) -> Bool {
        return obs.boundingBox.maxY < other.obs.boundingBox.minY
    }
    
    func isAbove(_ other: Observation) -> Bool {
        return obs.boundingBox.minY > other.obs.boundingBox.maxY
    }
    
    func isToTheRight(of other: Observation) -> Bool {
        return obs.boundingBox.minX > other.obs.boundingBox.maxX
    }
    
    func isToTheLeft(of other: Observation) -> Bool {
        return obs.boundingBox.maxX < other.obs.boundingBox.minX
    }
    
    func overlapsVertically(with other: Observation) -> Bool {
        let otherbb = other.obs.boundingBox
        let bb = self.obs.boundingBox
        return (bb.minY < otherbb.maxY && bb.maxY > otherbb.minY) ||
            (otherbb.minY < bb.maxY && otherbb.maxY > bb.minY)
    }
    
    func overlapsHorizontally(with other: Observation) -> Bool {
        let otherbb = other.obs.boundingBox
        let bb = self.obs.boundingBox
        return (bb.minX < otherbb.maxX && bb.maxX > otherbb.minX) ||
            (otherbb.minX < bb.maxX && otherbb.maxX > bb.minX)
    }
}

enum ObservationClassification {
    case price, position, summeEUR, eur, posten, totalPrice, unclassified
}
