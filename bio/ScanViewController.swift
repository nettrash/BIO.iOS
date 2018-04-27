//
//  ScanViewController.swift
//  bio
//
//  Created by Иван Алексеев on 27.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import UIKit
import AVFoundation

class ScanViewController: BaseViewController, AVCaptureMetadataOutputObjectsDelegate {
	
	@IBOutlet var btnClose: UIButton!
	@IBOutlet var imgLogo: UIImageView!
	
	var captureSession: AVCaptureSession!
	var previewLayer: AVCaptureVideoPreviewLayer!
	var configured: Bool = false
	var address: String? = nil
	var amount: Decimal? = nil
	var message: String? = nil
	var instantSend: Bool = false
	var currency: Currency = .BIO
	var bitpay: bitpayInvoice? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if (!configured) {
			configure()
		}
	}
	
	func failed() {
		let ac = UIAlertController(title: NSLocalizedString("ScanNotSupport", comment: "Scanning not supported"), message: NSLocalizedString("ScanNotSupportedMsg", comment: "Message"), preferredStyle: .alert)
		ac.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default))
		present(ac, animated: true)
		captureSession = nil
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		address = nil;
		
		switch (AVCaptureDevice.authorizationStatus(for: .video)) {
		case .authorized:
			if (captureSession?.isRunning == false) {
				captureSession.startRunning()
			}
		case .notDetermined:
			AVCaptureDevice.requestAccess(for: .video, completionHandler: requestAccessResult)
		default:
			requestAccessResult(false)
		}
	}
	
	public func requestAccessResult(_ granted: Bool) -> Void {
		if (granted) {
			if (!configured) {
				configure()
			}
			if (captureSession?.isRunning == false) {
				captureSession.startRunning()
			}
		} else {
			failed()
		}
	}
	
	func configure() -> Void {
		view.backgroundColor = UIColor.black
		captureSession = AVCaptureSession()
		
		guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
		let videoInput: AVCaptureDeviceInput
		
		do {
			videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
		} catch {
			return
		}
		
		if (captureSession.canAddInput(videoInput)) {
			captureSession.addInput(videoInput)
		} else {
			failed()
			return
		}
		
		let metadataOutput = AVCaptureMetadataOutput()
		
		if (captureSession.canAddOutput(metadataOutput)) {
			captureSession.addOutput(metadataOutput)
			
			metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
			metadataOutput.metadataObjectTypes = [.qr]
		} else {
			failed()
			return
		}
		
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		previewLayer.frame = view.layer.bounds
		previewLayer.videoGravity = .resizeAspectFill
		view.layer.addSublayer(previewLayer)
		
		view.bringSubview(toFront: btnClose)
		view.bringSubview(toFront: imgLogo)
		
		configured = true;
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if (captureSession?.isRunning == true) {
			captureSession.stopRunning()
		}
	}
	
	public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
		captureSession.stopRunning()
		
		if let metadataObject = metadataObjects.first {
			guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
				captureSession.startRunning()
				return
			}
			guard let stringValue = readableObject.stringValue else {
				captureSession.startRunning()
				return
			}
			AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
			if (!found(code: stringValue)) {
				captureSession.startRunning()
				return
			}
		}
		
		//dismiss(animated: true)
		performSegue(withIdentifier: unwindIdentifiers["scan-address"]!, sender: self)
	}
	
	func parseBIOCode(code: String) -> Bool {
		//BIO Code
		if bioAddress.verify(code) {
			address = code
			currency = .BIO
			return true
		}
		if (!code.lowercased().hasPrefix("biocoin:")) { return false }
		
		let qDelIndex = code.index(of: ":")
		var qStartIndex = qDelIndex ?? code.startIndex
		if (qDelIndex != nil) {
			qStartIndex = code.index(after: qDelIndex!)
		}
		let qEndIndex = code.endIndex
		let q = code[qStartIndex..<qEndIndex]
		let query = String(q)
		
		let uri = URL(string: query)
		let uriComponents = URLComponents.init(url: uri!, resolvingAgainstBaseURL: true)
		
		address = uriComponents?.path
		if uriComponents?.queryItems != nil {
			for qi in uriComponents!.queryItems! {
				switch qi.name {
				case "amount":
					amount = Decimal(string: (qi.value ?? "").replacingOccurrences(of: ",", with: ".", options: .literal, range: nil))
					break
				case "message":
					message = qi.value
					break
				case "IS":
					instantSend = qi.value ?? "" == "1"
					break
				default:
					break
				}
			}
		}
		currency = .BIO
		
		return bioAddress.verify(address)
	}
	
	func parseBTCCode(code: String) -> Bool {
		//BTC Code
		if bioAddress.verifyBTC(code) {
			address = code
			currency = .BTC
			return true
		}
		if (!code.lowercased().hasPrefix("bitcoin:")) { return false }
		
		let qDelIndex = code.index(of: ":")
		var qStartIndex = qDelIndex ?? code.startIndex
		if (qDelIndex != nil) {
			qStartIndex = code.index(after: qDelIndex!)
		}
		let qEndIndex = code.endIndex
		let q = code[qStartIndex..<qEndIndex]
		let query = String(q)
		
		let uri = URL(string: query)
		let uriComponents = URLComponents.init(url: uri!, resolvingAgainstBaseURL: true)
		
		address = uriComponents?.path
		if uriComponents?.queryItems != nil {
			for qi in uriComponents!.queryItems! {
				switch qi.name {
				case "amount":
					amount = Decimal(string: (qi.value ?? "").replacingOccurrences(of: ",", with: ".", options: .literal, range: nil))
					break
				case "message":
					message = qi.value
					break
				case "IS":
					instantSend = qi.value ?? "" == "1"
					break
				case "r":
					let bipUrl = qi.value ?? ""
					if bitpayInvoice.canParse(url: bipUrl) {
						let semaphore = DispatchSemaphore(value: 0)
						bitpay = bitpayInvoice(url: URL(string: bipUrl.replacingOccurrences(of: "/i/", with: "/invoices/"))!, completion: {
							(_ error: Error?) -> () in
							if error != nil {
								self.showError(error: error!.localizedDescription)
							}
							semaphore.signal()
							
						})
						semaphore.wait()
					}
					break;
				default:
					break
				}
			}
		}
		currency = .BTC
		
		return bioAddress.verifyBTC(address) || bitpay != nil
	}
	
	func parseSIBCode(code: String) -> Bool {
		//SIB Code
		if bioAddress.verifySIB(code) {
			address = code
			currency = .SIB
			return true
		}
		if (!code.lowercased().hasPrefix("sibcoin:")) { return false }
		
		let qDelIndex = code.index(of: ":")
		var qStartIndex = qDelIndex ?? code.startIndex
		if (qDelIndex != nil) {
			qStartIndex = code.index(after: qDelIndex!)
		}
		let qEndIndex = code.endIndex
		let q = code[qStartIndex..<qEndIndex]
		let query = String(q)
		
		let uri = URL(string: query)
		let uriComponents = URLComponents.init(url: uri!, resolvingAgainstBaseURL: true)
		
		address = uriComponents?.path
		if uriComponents?.queryItems != nil {
			for qi in uriComponents!.queryItems! {
				switch qi.name {
				case "amount":
					amount = Decimal(string: (qi.value ?? "").replacingOccurrences(of: ",", with: ".", options: .literal, range: nil))
					break;
				case "message":
					message = qi.value
					break;
				default:
					break;
				}
			}
		}
		currency = .SIB
		
		return bioAddress.verifySIB(address)
	}
	
	func found(code: String) -> Bool {
		if (parseBIOCode(code: code)) {
			return true
		}
		
		if (parseBTCCode(code: code)) {
			return true
		}
		
		if (parseSIBCode(code: code)) {
			return true
		}
		
		return false
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}
	
	@IBAction func btnClose_Click(_ sender: Any?) {
		captureSession.stopRunning()
		performSegue(withIdentifier: unwindIdentifiers["scan-address"]!, sender: self)
	}
	
}


