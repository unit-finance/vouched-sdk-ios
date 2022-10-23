//
//  Vouch+DescriptiveText.swift
//  UnitVouchSampleApp
//
//  Created by Oren Dinur on 31/07/2022.
//
import Foundation
import VouchedCore

/// This class is responsible for most of the messages that will be seen on screen by the user;
/// Extension for the `Insight` and `Instruction` String Enums
extension Insight {
    func getDescriptiveText() -> String? {
        switch self {
        case .nonGlare:
            return "image has glare"
        case .quality:
            return "image is blurry"
        case .brightness:
            return "image needs to be brighter"
        case .face:
            return "image is missing required visual markers"
        case .glasses:
            return "please take off your glasses"
        case .idPhoto:
            return "ID needs a valid photo"
        case .unknown:
            return nil
        @unknown default:
            return nil
        }
    }
}

extension Instruction {
    func getDescriptiveText(mode: VouchedDetectionMode) -> String? {
        switch self {
            
            // ID Detection instructions
        case .moveAway:
            return "Move Away"
        case .holdSteady:
            return "Hold Steady"
            
            // FACE Detection instructions
        case .openMouth:
            return "Open Mouth"
        case .closeMouth:
            return "Close Mouth"
        case .lookForward:
            return "Look Forward"
        case .blinkEyes:
            return "Slowly Blink"
            
            // Common Detection instructions
        case .onlyOne:
            switch mode {
            case .id:
                return "Multiple IDs"
            case .selfie:
                return "Multiple Faces"
            case .barcode:
                return nil
            case .backId:
                return nil
            @unknown default:
                return nil
            }
        case .moveCloser:
            switch mode {
            case .id:
                return "Move Closer"
            case .selfie:
                return "Come Closer to Camera"
            case .barcode:
                return nil
            case .backId:
                return nil
            @unknown default:
                return nil
            }
        case .none:
            return nil
        default:
            switch mode {
            case .id:
                return "Show ID"
            case .selfie:
                return "Look Forward"
            case .barcode:
                return nil
            case .backId:
                return nil
            @unknown default:
                return nil
            }
        }
    }
}
