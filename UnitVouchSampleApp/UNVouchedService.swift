//
//  UNVouchedService.swift
//  UnitVouchSampleApp
//
//  Created by Oren Dinur on 26/07/2022.
//

import Foundation
import UIKit
import TensorFlowLite
import VouchedCore
import VouchedBarcode

/// Used to pass the result from Vouched to the ViewController that holds the service.
public enum OnResult {
    case success(job: Job)
    case failure(error: Error)
}

public protocol UNVouchedServiceDelegate: AnyObject {
    func onProgressUpdate(_ instruction: String)
    func changeLoadingStatus(_ shouldHideIndicator: Bool)
    func onCaptureComplete(with result: OnResult)
    func showConfirmOverlay(shouldShowOverlay: Bool)
}

/// A service that uses Vouched SDK and was made for Unit customers to implement the SDK in an easier way.
class UNVouchedService {
    
    private weak var delegate: UNVouchedServiceDelegate?
    
    // Container for capturing pictures
    private weak var previewContainer: UIView?
    private var shouldHideLoadingIndicator = true
    
    private var mode: VouchedDetectionMode = .id
    private var helper: VouchedCameraHelper?
    private let session = VouchedSession(apiKey: UNConstants.publicKey, sessionParameters: VouchedSessionParameters())
    private var detectionMgr: VouchedDetectionManager?
    
    // Flags related
    let firstName = "Oren"
    let lastName = "Dinur"
    var useCameraFlash = false
    var onBarcodeStep = false
    var includeBarcode = false
    
    // Manager Detection flags related
    var useDetectionManager = true
    // Use with useDetectionManager set to `true`
    var confirmID = true
    // temp storage of current ID to be confirmed
    var confirmIDDetectionResult: CardDetectResult?
    
    init(delegate: UNVouchedServiceDelegate) {
        self.delegate = delegate
    }
    
    /// Sets a mode to capture and a container to show the capturing;
    /// If `useDetectionManager` flag is set to true, the detection manager is then configured.
    func start(mode: VouchedDetectionMode, in previewContainer: UIView) {
        self.previewContainer = previewContainer
        self.mode = mode
        
        configureHelper(mode)
        if self.useDetectionManager {
            configureDetectionManager()
        }
        startCapture()
    }
    
    
    func postConfirm(onResult: (OnResult) -> Void) {
        do {
            self.onProgressUpdate("Processing")
            let job = try session.postConfirm()
            onResult(OnResult.success(job: job))
            onProgressUpdate("Job results were printed")
        } catch {
            print("Error info: \(error)")
            onResult(OnResult.failure(error: error))
        }
    }
    
    
    /// Starts capturing pictures
    private func startCapture() {
        if self.useDetectionManager && self.mode == .id  {
            detectionMgr?.startDetection()
        } else {
            helper?.startCapture()
        }
    }
    
    /// Updates the delegate with instructions,insights and custom messages.
    private func onProgressUpdate(_ str: String) {
        DispatchQueue.main.async() {
            self.delegate?.onProgressUpdate(str)
        }
    }
    
    /// Updates the delegate with an instruction that can be found in the `Vouch+DescriptiveText.swift` file.
    private func onProgressUpdate(_ instruction: Instruction) {
        guard let descriptiveText = instruction.getDescriptiveText(mode: self.mode) else { return }
        self.onProgressUpdate(descriptiveText)
    }
    
    /// Updates the delegate with an insights that can be found in the `Vouch+DescriptiveText.swift` file.
    private func onProgressUpdate(_ insight: Insight) {
        guard let descriptiveText = insight.getDescriptiveText() else { return }
        self.onProgressUpdate(descriptiveText)
    }
    
    private func changeLoadingStatus() {
        delegate?.changeLoadingStatus(!shouldHideLoadingIndicator)
    }
    
    /// Updates the delegate with the result status that was sent from Vouched to the capture picture;
    /// Attached to the result is the job or error that was obtained.
    private func updateCaptureResult(with result: OnResult) {
        switch result {
        case .success(let job):
            DispatchQueue.main.async() {
                self.delegate?.onCaptureComplete(with: .success(job: job))
            }
            self.onProgressUpdate("Success")
        case .failure(let error):
            DispatchQueue.main.async() {
                self.delegate?.onCaptureComplete(with: .failure(error: error))
            }
            self.onProgressUpdate("Error info: \(error)")
        }
    }
}

// `VouchedCameraHelper`
// This extension is introduced to make it easier for developers to integrate VouchedSDK and provide the optimal photography.
extension UNVouchedService {
    /// The helper takes care of configuring the capture session, input, and output;
    /// The mode will affect the type of detector that will be used.
    private func configureHelper(_ mode: VouchedDetectionMode) {
        guard let previewContainer = self.previewContainer else { return }
        var options = VouchedCameraHelperOptions.defaultOptions
        if useCameraFlash {
            options += .useCameraFlash
        }
        var detectionOptions = [VouchedDetectionOptions]()
        switch mode {
        case .id, .barcode:
            detectionOptions = [VouchedDetectionOptions.cardDetect(CardDetectOptionsBuilder().withEnhanceInfoExtraction(true).build())]
        case .selfie:
            detectionOptions = [VouchedDetectionOptions.faceDetect(FaceDetectOptionsBuilder().withLivenessMode(.mouthMovement).build())]
        case .backId: break
        @unknown default: break
        }
        
        helper = VouchedCameraHelper(with: mode, helperOptions: options, detectionOptions: detectionOptions, in: previewContainer)?.withCapture(delegate: { self.handleResult($0) })
    }
    
    /// Handle results that were captured by the `helper`
    private func handleResult(_ result: CaptureResult) {
        switch result {
        case .empty:
            handleEmptyResult(result: result)
            
        case .id(let result):
            guard let result = result as? CardDetectResult else { return }
            handleIdResult(result: result)
            
        case .selfie(let result):
            guard let result = result as? FaceDetectResult else { return }
            handleSelfieResult(result: result)
            
        case .barcode(let result):
            handleBarcodeResult(result: result)
            
        case .error(let error):
            if let error = error as? VouchedError, let description = error.errorDescription {
                print("Error processing: \(description)")
            } else {
                print("Error processing: \(error.localizedDescription)")
            }
        @unknown default:
            print("Unknown Error")
        }
    }
    
    /// Sending custom messages using the delegate method
    private func handleEmptyResult(result: CaptureResult) {
        switch self.mode {
        case .id:
            self.onProgressUpdate("Show ID Card")
        case .barcode:
            self.onProgressUpdate("Focus camera on barcode")
        case .selfie:
            self.onProgressUpdate("Look into the Camera")
        case .backId: break
        @unknown default: break
        }
    }
    
    /// Making sure the id result is ready to process before a job is created
    private func handleIdResult(result: CardDetectResult) {
        switch result.step {
        case .preDetected:
            self.onProgressUpdate("Show ID Card")
        case .detected:
            self.onProgressUpdate(result.instruction)
        case .postable:
            helper?.stopCapture()
            onConfirmIdResult(result as CardDetectResult)
        @unknown default:
            self.onProgressUpdate(onBarcodeStep ? "Focus camera on barcode" : "Show ID Card")
        }
    }
    
    /// Making sure the selfie result is ready to process and then a job is created;
    /// In case insights about the capture exist, the capture is retried;
    /// Otherwise the job is returned to the delegate with success.
    private func handleSelfieResult(result: FaceDetectResult) {
        switch result.step {
        case .preDetected:
            self.onProgressUpdate("Look into the Camera")
        case .detected:
            self.onProgressUpdate(result.instruction)
        case .postable:
            helper?.stopCapture()
            self.changeLoadingStatus()
            self.onProgressUpdate("Processing Image")
            DispatchQueue.global().async {
                do {
                    let job = try self.session.postFace(detectedFace: result)
                    
                    // if there are job insights, update label and retry card detection
                    if self.hasInsights(for: job) {
                        let insights = VouchedUtils.extractInsights(job)
                        self.updateAndRetryDetection(with: insights, shouldResetHelper: true)
                        return
                    }
                    self.updateCaptureResult(with: OnResult.success(job: job))
                } catch {
                    self.updateCaptureResult(with: OnResult.failure(error: error))
                    print("Error Selfie: \(error.localizedDescription)")
                }
            }
        @unknown default:
            break
        }
    }
    
    /// Making sure the barcode result is ready to process and then a job is created;
    /// In case insights about the capture exist, the capture is retried;
    /// Otherwise the job is returned to the delegate with success.
    private func handleBarcodeResult(result: DetectionResult) {
        helper?.stopCapture()
        self.changeLoadingStatus()
        self.onProgressUpdate("Processing")
        
        do {
            let job = try session.postBackId(detectedBarcode: result)
            
            // if there are job insights, update label and retry card detection
            if hasInsights(for: job) {
                let insights = VouchedUtils.extractInsights(job)
                updateAndRetryDetection(with: insights, shouldResetHelper: false)
                return
            }
            self.updateCaptureResult(with: .success(job: job))
            
        } catch {
            self.updateCaptureResult(with: .failure(error: error))
            print("Error Barcode: \(error.localizedDescription)")
        }
    }
    
    /// A job is created;
    /// In case insights about the capture exist, the capture is retried;
    /// Otherwise the job is returned to the delegate with success;
    /// If includeBarCode flag is set to true, a barcode scan will start.
    fileprivate func onConfirmIdResult(_ result: CardDetectResult) {
        self.changeLoadingStatus()
        self.onProgressUpdate("Processing Image")
        DispatchQueue.global().async {
            do {
                let job: Job
                if self.firstName.isEmpty && self.lastName.isEmpty {
                    job = try self.session.postCardId(detectedCard: result)
                } else {
                    let details = Params(firstName: self.firstName, lastName: self.lastName)
                    job = try self.session.postCardId(detectedCard: result, details: details)
                }
                
                // if there are job insights, update label and retry card detection
                if self.hasInsights(for: job) {
                    let insights = VouchedUtils.extractInsights(job)
                    self.updateAndRetryDetection(with: insights, shouldResetHelper: true)
                    return
                }
                
                if self.includeBarcode {
                    self.onBarcodeStep = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.changeLoadingStatus()
                        self.configureHelper(.barcode)
                        self.helper?.startCapture()
                    }
                    return
                }
                self.updateCaptureResult(with: .success(job: job))
            } catch {
                self.updateCaptureResult(with: .failure(error: error))
                print("Error FrontId: \(error.localizedDescription)")
            }
        }
    }
    
    private func hasInsights(for job: Job) -> Bool {
        let insights = VouchedUtils.extractInsights(job)
        return !insights.isEmpty
    }
    
    private func updateAndRetryDetection(with insights: [Insight], shouldResetHelper: Bool) {
        self.onProgressUpdate(insights.first!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if (shouldResetHelper) {
                self.helper?.resetDetection()
            }
            self.changeLoadingStatus()
            self.helper?.startCapture()
        }
        return
    }
}


// `VouchedDetectionManager`
// This extension is introduced to help guide the ID verification modes by processing job results returned by the Vouched API service, and generating the appropriate modes that are needed to complete ID verification.
extension UNVouchedService {
    /// Configure a detection manager containing helper, session and callbacks.
    private func configureDetectionManager() {
        guard let helper = helper else { return }
        guard let config = VouchedDetectionManagerConfig(session: session) else { return }
        // Callbacks that let's us do different things in different stages of the detection.
        let callbacks = DetectionCallbacks()
        configureManagerCallbacks(for: callbacks)
        config.callbacks = callbacks
        detectionMgr = VouchedDetectionManager(helper: helper, config: config)
    }
    
    /// Optional configuration for some of the callback methods that are found in the DetectionCallbacks class.
    private func configureManagerCallbacks(for callbacks: DetectionCallbacks) {
        callbacks.onModeChange = { change in
            self.onProgressUpdate("Turn ID card over to backside")
            change.completion(true)
        }
        
        callbacks.detectionComplete = { result in
            switch result {
            case .success(let job):
                DispatchQueue.main.async {
                    // Barcode scan detection was set to true and the detection hasn't started already
                    if self.includeBarcode && !self.onBarcodeStep {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.onBarcodeStep = true
                            self.detectionMgr?.startDetection(.barcode)
                        }
                    } else {
                        self.updateCaptureResult(with: .success(job: job))
                    }
                }
            case .failure(let err):
                self.updateCaptureResult(with: .failure(error: err))
                print("Error Card ID: \(err.localizedDescription)")
            }
        }
        
        callbacks.onResultProcessing = { self.onResultProcessing($0) }
        
        callbacks.validateSubmission = { [self] result in
            self.onProgressUpdate("Processing")
            if self.confirmID {
                if self.useDetectionManager {
                    detectionMgr?.stopDetection()
                } else {
                    helper?.stopCapture()
                }
                if let result = result as? CardDetectResult {
                    confirmIDCaptureIsGood(isVisible: true, result: result)
                    return false
                }
            }
            return true
        }
    }
    
    private func confirmIDCaptureIsGood(isVisible: Bool, result: CardDetectResult) {
        self.confirmIDDetectionResult = result
        delegate?.showConfirmOverlay(shouldShowOverlay: isVisible)
    }
    
    private func onResultProcessing(_ options: VouchedResultProcessingOptions) {
        let genericMessage = onBarcodeStep ? "Focus camera on barcode" : "Show ID Card"
        guard options.step != nil else {
            self.onProgressUpdate(genericMessage)
            return
        }
        if let step = options.step {
            switch step {
            case .preDetected:
                self.onProgressUpdate("Show ID Card")
            case .detected:
                if let instruction = options.instruction {
                    self.onProgressUpdate(instruction)
                }
            case .postable:
                if let insight = options.insight {
                    self.onProgressUpdate(insight)
                } else {
                    self.onProgressUpdate("Processing")
                }
            @unknown default:
                self.onProgressUpdate(genericMessage)
                
            }
        }
    }
    
    /// Triggered when a retry button is clicked
    func retryCapture() {
        startCapture()
    }
    
    /// Decides how to confirm the id
    func startConfirmId () {
        guard let confirmedResult = self.confirmIDDetectionResult else {
            print("no confirmed result to post")
            return
        }
        if useDetectionManager {
            detectionMgr?.onConfirmIdResult(result: confirmedResult)
        } else {
            onConfirmIdResult(confirmedResult)
        }
    }
}
