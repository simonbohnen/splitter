//
//  PositionObservation.swift
//  Splitter
//
//  Created by Simon Bohnen on 18.07.21.
//

import Foundation

class PositionObservation: Observation {
    var priceObservation: PriceObservation
    
    init(_ obs: Observation, _ priceObservation: PriceObservation) {
        self.priceObservation = priceObservation
        super.init(obs)
    }
}
