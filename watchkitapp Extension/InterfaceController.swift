//
//  InterfaceController.swift
//  watchkitapp Extension
//
//  Created by Иван Алексеев on 31.05.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import WatchKit
import Foundation
import CoreData

class InterfaceController: WKInterfaceController, ApplicationContextDelegate {
	
	var balance: BalanceResponse?
	@IBOutlet var lblBalance: WKInterfaceLabel!
	@IBOutlet var imgLogo: WKInterfaceImage!
	@IBOutlet var imgBack: WKInterfaceImage!
	
	static func md5(_ string: String) -> Data {
		let messageData = string.data(using:.utf8)!
		var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
		
		_ = digestData.withUnsafeMutableBytes {digestBytes in
			messageData.withUnsafeBytes {messageBytes in
				CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
			}
		}
		
		return digestData
	}
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		// Configure interface objects here.
		self.imgBack.setImage(UIImage(named: "WKBackground"))
		self.imgLogo.setImage(UIImage(named: NSLocalizedString("BIOLogoImageName", comment: "BIOLogoImageName")))
		self.lblBalance.setText(NSLocalizedString("Refresh", comment: "refresh"))
		
		self.setTitle(NSLocalizedString("AppTitleBalance", comment: "main title"))
	}
	
	override func willActivate() {
		// This method is called when watch view controller is about to be visible to user
		super.willActivate()
		self.imgBack.setImage(UIImage(named: "WKBackground"))
		self.imgLogo.setImage(UIImage(named: NSLocalizedString("BIOLogoImageName", comment: "BIOLogoImageName")))
		self.lblBalance.setText(NSLocalizedString("Refresh", comment: "refresh"))
		_loadBalanceData()
		let extDelegate = WKExtension.shared().delegate as! ExtensionDelegate
		extDelegate.delegate = self
		extDelegate.requestContext()
	}
	
	override func didDeactivate() {
		// This method is called when watch view controller is no longer visible
		super.didDeactivate()
	}
	
	@IBAction func refreshTap(_ sender: Any?) {
		self.lblBalance.setText(NSLocalizedString("Refresh", comment: "refresh"))
		_loadBalanceData()
		let extDelegate = WKExtension.shared().delegate as! ExtensionDelegate
		extDelegate.delegate = self
		extDelegate.requestContext()
	}
	
	@IBAction func switchToQR(_ sender: Any?) {
		
	}
	
	func _loadBalanceData() -> Void {
		// prepare auth data
		let ServiceName = "BIO"
		let ServiceSecret = "DE679233-8A45-4845-AA4D-EFCA1350F0A0"
		let md5src = "\(ServiceName)\(ServiceSecret)"
		let md5digest = InterfaceController.md5(md5src)
		let ServicePassword = md5digest.map { String(format: "%02hhx", $0) }.joined()
		let base64Data = "\(ServiceName):\(ServicePassword)".data(using: String.Encoding.utf8)?.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
		
		let extDelegate = WKExtension.shared().delegate as! ExtensionDelegate
		let Addresses = extDelegate.addresses
		
		// prepare json data
		let json: [String:Any] = ["addresses": Addresses ?? ""]
		
		let jsonData = try? JSONSerialization.data(withJSONObject: json)
		
		// create post request
		let url = URL(string: "https://bioapi.sib.moe/wallet/bio.svc/balance")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("Basic \(base64Data ?? "")", forHTTPHeaderField: "Authorization")
		
		// insert json data to the request
		request.httpBody = jsonData
		
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data, error == nil else {
				self.lblBalance.setText(NSLocalizedString("Error", comment: "error"))
				return
			}
			let responseString = String(data: data, encoding: String.Encoding.utf8)
			print(responseString ?? "nil")
			let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
			if let responseJSON = responseJSON as? [String: [String: Any]] {
				print(responseJSON)
				self.balance = BalanceResponse.init(json: responseJSON["BalanceResult"]!)
				self.lblBalance.setText(String(format: "%.2f", Double(self.balance?.Value ?? 0) / Double(100000000.00)))
			}
		}
		
		task.resume()
	}
	
	//ApplicationContextDelegate
	func contextUpdated() {
		_loadBalanceData()
	}
	
	func qrUpdated() {
	}
}
