//
//  ClassifiedObservation.swift
//  Splitter
//
//  Created by Simon Bohnen on 16.07.21.
//

import Foundation
import Vision

struct ClassifiedObservation {
    let observation: VNRecognizedTextObservation
    let classification = ObservationClassification.unclassified
    let bestString: String?
}

enum ObservationClassification {
    case price, position, summeEUR, eur, unclassified
}
