//
//  TodayViewController.swift
//  todayExtension
//
//  Created by Иван Алексеев on 31.05.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreData

class TodayViewController: UIViewController, NCWidgetProviding {
	
	static var persistentContainer: PersistentContainer = {
		let container = PersistentContainer(name: "bio")
		container.loadPersistentStores(completionHandler: { (storeDescription:NSPersistentStoreDescription, error:Error?) in
			if let error = error as NSError?{
				fatalError("UnResolved error \(error), \(error.userInfo)")
			}
		})
		
		return container
	}()
	
	var balance: BalanceResponse?
	@IBOutlet var lblBalance: UILabel!
	@IBOutlet var lblBalanceLabel: UILabel!
	@IBOutlet var lblQRLabel: UILabel!
	@IBOutlet var lblQRInfo: UILabel!
	@IBOutlet var aiWait: UIActivityIndicatorView!
	@IBOutlet var imgQR: UIImageView!
	@IBOutlet var imgLogo: UIImageView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view from its nib.
		updateVisibleInfo()
		self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize)
	{
		updateVisibleInfo()
		if activeDisplayMode == .expanded
		{
			preferredContentSize = CGSize(width: 0.0, height: 280.0)
			self.imgQR.isHidden = false
			self.lblQRInfo.isHidden = self.imgQR.isHidden
			self.lblQRLabel.isHidden = self.imgQR.isHidden
			//self.lblBalance.textAlignment = NSTextAlignment.center
			//self.lblBalanceLabel.textAlignment = NSTextAlignment.center
			DispatchQueue.main.async { self.qrIncoming() }
		}
		else
		{
			preferredContentSize = CGSize(width: 0.0, height: 110.0)
			self.imgQR.isHidden = true
			self.lblQRInfo.isHidden = self.imgQR.isHidden
			self.lblQRLabel.isHidden = self.imgQR.isHidden
			//self.lblBalance.textAlignment = NSTextAlignment.right
			//self.lblBalanceLabel.textAlignment = NSTextAlignment.right
		}
	}
	
	/*override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
	super.touchesBegan(touches, with: event)
	let url: NSURL = NSURL(string: "sibcoin://")!
	self.extensionContext?.open(url as URL, completionHandler: nil)
	}*/
	
	func updateVisibleInfo() {
		self.imgLogo.image = UIImage(named: NSLocalizedString("BIOLogoImageName", comment: "BIOLogoImageName"))
		self.lblBalanceLabel.text = NSLocalizedString("BalanceLabel", comment: "balance info label")
		self.lblBalance.text = self.balance != nil ? String(format: "%.2f", Double(self.balance?.Value ?? 0) / Double(100000000.00)) : ""
		self.lblQRInfo.text = NSLocalizedString("QRInfo", comment: "qr info")
		self.lblQRLabel.text = NSLocalizedString("QRLabel", comment: "qr label")
	}
	
	@IBAction func sendClick(_ sender: Any?) {
		let url: NSURL = NSURL(string: "BioCoin://")!
		self.extensionContext?.open(url as URL, completionHandler: nil)
	}
	
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		// Perform any setup necessary in order to update the view.
		
		// If an error is encountered, use NCUpdateResult.Failed
		// If there's no update required, use NCUpdateResult.NoData
		// If there's an update, use NCUpdateResult.NewData
		updateVisibleInfo()
		aiWait.startAnimating()
		_loadBalanceData(completionHandler: completionHandler)
	}
	
	func _loadBalanceData(completionHandler: (@escaping (NCUpdateResult) -> Void)) -> Void {
		// prepare auth data
		let ServiceName = "BIO"
		let ServiceSecret = "DE679233-8A45-4845-AA4D-EFCA1350F0A0"
		let md5src = "\(ServiceName)\(ServiceSecret)"
		let md5digest = Crypto.md5(md5src)
		let ServicePassword = md5digest.map { String(format: "%02hhx", $0) }.joined()
		let base64Data = "\(ServiceName):\(ServicePassword)".data(using: String.Encoding.utf8)?.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
		
		let moc = TodayViewController.persistentContainer.viewContext
		let Addresses = try! moc.fetch(Address.fetchRequest()) as! [Address]
		
		// prepare json data
		let json: [String:Any] = ["addresses": Addresses.map { (_ a: Address) -> String in
			a.address
			}]
		
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
				self.lblBalance.text = "-"
				self.aiWait.stopAnimating()
				completionHandler(NCUpdateResult.failed)
				return
			}
			let responseString = String(data: data, encoding: String.Encoding.utf8)
			print(responseString ?? "nil")
			let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
			if let responseJSON = responseJSON as? [String: [String: Any]] {
				print(responseJSON)
				self.balance = BalanceResponse.init(json: responseJSON["BalanceResult"]!)
				self.lblBalance.text = String(format: "%.2f", Double(self.balance?.Value ?? 0) / Double(100000000.00))
				completionHandler(NCUpdateResult.newData)
			}
			self.aiWait.stopAnimating()
		}
		
		task.resume()
	}
	
	func qrIncoming() {
		let moc = TodayViewController.persistentContainer.viewContext
		let Addresses = try! moc.fetch(Address.fetchRequest()) as! [Address]
		let AddressesForIncoming = Addresses.filter { $0.type == bioWalletType.Incoming.rawValue }
		let address = AddressesForIncoming[AddressesForIncoming.count-1].address
		
		let data = "BioCoin://\(address)".data(using: String.Encoding.ascii)
		let filter = CIFilter(name: "CIQRCodeGenerator")
		
		filter!.setValue(data, forKey: "inputMessage")
		filter!.setValue("Q", forKey: "inputCorrectionLevel")
		
		let qrcodeImage = filter!.outputImage
		
		let scaleX = imgQR.frame.size.width / qrcodeImage!.extent.size.width
		let scaleY = imgQR.frame.size.height / qrcodeImage!.extent.size.height
		
		let transformedImage = qrcodeImage!.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
		
		imgQR.image = UIImage(ciImage: transformedImage)
	}
}
