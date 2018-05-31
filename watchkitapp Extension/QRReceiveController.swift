//
//  QRReceiveController.swift
//  watchkitapp Extension
//
//  Created by Иван Алексеев on 31.05.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import WatchKit
import Foundation
import CoreData

class QRReceiveController: WKInterfaceController, ApplicationContextDelegate {
	
	@IBOutlet var imgQR: WKInterfaceImage!
	@IBOutlet var imgBack: WKInterfaceImage!
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		// Configure interface objects here.
		self.imgBack.setImage(UIImage(named: "WKBackground"))
		self.setTitle(NSLocalizedString("AppTitleReceive", comment: "main title"))
	}
	
	override func willActivate() {
		// This method is called when watch view controller is about to be visible to user
		super.willActivate()
		self.imgBack.setImage(UIImage(named: "WKBackground"))
		self.setTitle(NSLocalizedString("AppTitleReceive", comment: "main title"))
		let extDelegate = WKExtension.shared().delegate as! ExtensionDelegate
		if extDelegate.qrReceive != nil {
			imgQR.setImage(extDelegate.qrReceive)
		}
		extDelegate.delegate = self
		extDelegate.requestQR()
	}
	
	override func didDeactivate() {
		// This method is called when watch view controller is no longer visible
		super.didDeactivate()
	}
	
	//ApplicationContextDelegate
	func contextUpdated() {
	}
	
	func qrUpdated() {
	}
	
}
