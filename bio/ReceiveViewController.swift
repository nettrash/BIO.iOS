//
//  ReceiveViewController.swift
//  bio
//
//  Created by Иван Алексеев on 27.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import UIKit

class ReceiveViewController : BaseViewController, UITextFieldDelegate {
	
	@IBOutlet var tfAddress: UITextField!
	@IBOutlet var tfAmount: UITextField!
	@IBOutlet var imgQR: UIImageView!
	@IBOutlet var aiWait: UIActivityIndicatorView!
	
	var address: String = ""
	
	var queryString: String {
		var retVal = ""
		if amount ?? 0 > 0 {
			retVal += "?amount=\(amount!)"
		}
		return retVal
	}
	
	var addressUrl: String {
		let app = UIApplication.shared.delegate as! AppDelegate
		return app.model!.BIO!.URIScheme + address + queryString
	}
	
	var addressFullUrl: URL {
		let app = UIApplication.shared.delegate as! AppDelegate
		return URL(string: app.model!.BIO!.URIScheme + "//" + address + queryString)!
	}
	
	var amount: Decimal? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let app = UIApplication.shared.delegate as! AppDelegate
		if app.model!.needNewAddress {
			app.model!.BIO!.initialize(NSUUID().uuidString)
			app.model!.storeWallet(app.model!.BIO!, false, .Incoming)
			app.model!.reload(app)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		let app = UIApplication.shared.delegate as! AppDelegate
		address = app.model!.AddressesForIncoming[app.model!.AddressesForIncoming.count-1].address
		tfAddress.text = address
		DispatchQueue.main.async {
			self.refreshQR()
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func shareAddress(_ sender: Any?) -> Void {
		let png = imgQR.image!.pngData()!
		let activityViewController : UIActivityViewController = UIActivityViewController(
			activityItems: [addressFullUrl.absoluteString, UIImage.init(data: png)!], applicationActivities: [])
		
		activityViewController.popoverPresentationController?.sourceView = (sender as! UIButton)
		
		activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
		activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
		
		present(activityViewController, animated: true, completion: nil)
	}
	
	func refreshQR() -> Void {
		let data = addressUrl.data(using: String.Encoding.ascii)
		let filter = CIFilter(name: "CIQRCodeGenerator")
		
		filter!.setValue(data, forKey: "inputMessage")
		filter!.setValue("Q", forKey: "inputCorrectionLevel")
		
		let qrcodeImage = filter!.outputImage
		
		let scaleX = imgQR.frame.size.width / qrcodeImage!.extent.size.width
		let scaleY = imgQR.frame.size.height / qrcodeImage!.extent.size.height
		
		let transformedImage = qrcodeImage!.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
		
		imgQR.image = UIImage(ciImage: transformedImage)
		
		aiWait.stopAnimating()
	}
	
	@IBAction func closeClick(_ sender: Any?) -> Void {
		performSegue(withIdentifier: unwindIdentifiers["receive-bio"]!, sender: self)
	}
	
	// UITextFieldDelegate
	public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		if textField == tfAddress {
			UIPasteboard.general.string = textField.text
			let alert = UIAlertController.init(title: NSLocalizedString("CopyToClipboard", comment: "CopyToClipboard"), message: NSLocalizedString("CopyToClipboardMessage", comment: "CopyToClipboardMessage"), preferredStyle: UIAlertController.Style.alert)
			alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertAction.Style.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
			self.present(alert, animated: true, completion: nil)
		}
		return textField != tfAddress
	}
	
	public func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
		return true;
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
		
	}
	
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let textFieldText: NSString = (textField.text ?? "") as NSString
		let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
		if textField == tfAmount {
			amount = Decimal(string: txtAfterUpdate)
			DispatchQueue.main.async {
				self.refreshQR()
			}
		}
		return textField != tfAddress
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
	}
	
	public func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return textField != tfAddress
	}
	
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		return textField != tfAddress
	}
	
}
