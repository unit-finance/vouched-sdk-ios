//
//  DetectionCallbacks.swift
//  UnitVouchSampleApp
//
//  Created by Oren Dinur on 11/08/2022.
//
import Foundation
import VouchedCore


/// A class to configure closures to be used to interact with the detection process
class DetectionCallbacks: VouchedDetectionManagerCallbacks {
    var onStartDetection: ((VouchedDetectionMode) -> Void)?
    var onStopDetection: ((VouchedDetectionMode) -> Void)?
    var onResultProcessing: ((VouchedResultProcessingOptions) -> Void)?
    var onModeChange: ((VouchedModeChange) -> Void) = { _ in}
    var validateSubmission: ((DetectionResult) -> Bool)?
    var detectionComplete: ((Result<Job, Error>) -> Void)?
}
