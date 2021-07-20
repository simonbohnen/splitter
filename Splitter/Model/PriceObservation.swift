//
//  PriceObservation.swift
//  Splitter
//
//  Created by Simon Bohnen on 18.07.21.
//

import Foundation

class PriceObservation: Observation {
    var price: Double
    var positionObservation: PositionObservation?
    
    init(_ obs: Observation, _ price: Double) {
        self.price = price
        super.init(obs)
    }
}
