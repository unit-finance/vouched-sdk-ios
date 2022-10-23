//
//  ViewController.swift
//  UnitVouchSampleApp
//
//  Created by Oren Dinur on 24/07/2022.
//

import UIKit
import TensorFlowLite
import VouchedCore

/// Handle UI changes and holds a reference to a `UNVouchedService` that is using the Vouched SDK
/// This controller demonstrates the following flow:
///   - Capture an id
///   - Capture a selfie
///   - Print the result of the captures that was returned from Vouched

class ViewController: UIViewController {
    
    // Container for capturing pictures
    @IBOutlet weak var previewContainer: UIView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    // Holds a captured picture and `OK` and `Retry` buttons
    @IBOutlet weak var confirmPanel: UIView!
    
    @IBOutlet weak var continueButton: UIButton!
    
    // A mode to capture, starts with id capturing
    var mode: VouchedDetectionMode = .id
    
    @IBAction func continueButtonPressed(_ sender: UIButton) {
        continueButton.isHidden = true
        if self.mode == .id {
            // Finished capturing an id
            self.mode = .selfie
            self.service.start(mode: .selfie, in: previewContainer)
        } else if self.mode == .selfie {
            // Finished capturing id and selfie
            service.postConfirm { result in
                switch result {
                case .success(let job):
                    print(job.result)
                case .failure(let error):
                    print("postConfirm failure: \(error.localizedDescription)")
                }
            }
        }
    }
    var service: UNVouchedService!
    
    @IBAction func onRetryIDButton(_ sender: Any) {
        showConfirmOverlay(shouldShowOverlay: false)
        service.retryCapture()
    }
    @IBAction func onConfirmIDButton(_ sender: Any) {
        showConfirmOverlay(shouldShowOverlay: false)
        service.startConfirmId()
    }
    
    // Initializes a service that uses Vouched SDK
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        service = UNVouchedService(delegate: self)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        service = UNVouchedService(delegate: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Choose  a mode to capture
        let mode: VouchedDetectionMode = .id
        
        // Start the service and provide it with a UIView to show camera captures
        self.service.start(mode: mode, in: previewContainer)
        
        // UI
        loadingIndicator.isHidden = true
        confirmPanel.isHidden = true
        continueButton.isHidden = true
    }
}
// Delegate Methods
extension ViewController: UNVouchedServiceDelegate{
    
    /// Showing the result captured and `OK` and `Retry` buttons
    func showConfirmOverlay(shouldShowOverlay: Bool) {
        UIView.transition(with: self.confirmPanel, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.confirmPanel.isHidden = !shouldShowOverlay
        })
        instructionLabel.isHidden = shouldShowOverlay
    }
    
    /// Gets access to the Job when it is returned from Vouched
    func onCaptureComplete(with result: OnResult) {
        switch result {
        case .success(let job):
            print(job)
            print("Job ID: \(job.id)")
            switch self.mode {
            case .id:
                continueButton.isHidden = false
                continueButton.setTitle("Continue to Selfie capture", for: .normal)
            case .barcode:
                break
            case .selfie:
                continueButton.isHidden = false
                continueButton.setTitle("Continue to results", for: .normal)
            case .backId:
                break
            @unknown default:
                break
            }
        case .failure(let error):
            print("onCaptureComplete failure: \(error.localizedDescription)")
        }
    }
    
    /// Show a loading indicator
    func changeLoadingStatus(_ shouldHideIndicator: Bool) {
        loadingIndicator.isHidden = shouldHideIndicator
    }
    
    /// Obtain messages on different stages of the service and show them on screen
    func onProgressUpdate(_ instruction: String) {
        instructionLabel.text = instruction
    }
}
