//
//  SettingsViewController.swift
//  bio
//
//  Created by Иван Алексеев on 27.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import MessageUI

class SettingsViewController : BaseViewController, UIDocumentPickerDelegate, MFMailComposeViewControllerDelegate {
	
	var keysAction = false
	var app = UIApplication.shared.delegate as! AppDelegate
	var fileUrl: URL?
	
	@IBOutlet var vWait: UIView!
	@IBOutlet var scCurrency: UISegmentedControl!
	@IBOutlet var pvProgress: UIProgressView!
	@IBOutlet var lblVersion: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let dictionary = Bundle.main.infoDictionary!
		let appversion = dictionary["CFBundleShortVersionString"] as! String
		lblVersion.text = "v\(appversion)"
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		vWait.isHidden = !keysAction
		self.pvProgress.isHidden = !keysAction
		
		switch app.model!.currency {
		case .RUB:
			scCurrency.selectedSegmentIndex = 0
			break
		case .USD:
			scCurrency.selectedSegmentIndex = 1
			break
		case .EUR:
			scCurrency.selectedSegmentIndex = 2
			break
		default:
			break
		}
		
		if fileUrl != nil {
			loadKeysFromUrl(fileUrl!)
			fileUrl = nil
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func scCurrencyValueChanged(_ sender: Any?) {
		switch scCurrency.selectedSegmentIndex {
		case 0:
			app.model!.setCurrency(.RUB)
			break
		case 1:
			app.model!.setCurrency(.USD)
			break
		case 2:
			app.model!.setCurrency(.EUR)
			break
		default:
			app.model!.setCurrency(.RUB)
			break
		}
	}
	
	@IBAction func closeClick(_ sender: Any?) -> Void {
		performSegue(withIdentifier: unwindIdentifiers["settings-bio"]!, sender: self)
	}
	
	@IBAction func supportClick(_ sender: Any?) -> Void {
		if !MFMailComposeViewController.canSendMail() {
			let alert = UIAlertController.init(title: NSLocalizedString("MailTitle", comment: "MailTitle"), message: NSLocalizedString("MailServicesAreNotAvailable", comment: "MailServicesAreNotAvailable"), preferredStyle: UIAlertController.Style.alert)
			alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertAction.Style.cancel, handler: { _ in
				alert.dismiss(animated: true, completion: nil)
			}))
			self.present(alert, animated: true, completion: nil)
			return
		}
		
		let composeVC = MFMailComposeViewController()
		composeVC.mailComposeDelegate = self
		
		// Configure the fields of the interface.
		composeVC.setToRecipients(["support@bitwallet.ge"])
		composeVC.setSubject(NSLocalizedString("SupportSubject", comment: "SupportSubject"))
		composeVC.setMessageBody("", isHTML: true)
		
		// Present the view controller modally.
		self.present(composeVC, animated: true, completion: nil)
	}
	
	@IBAction func shareKeys(_ sender: Any?) -> Void {
		
		self.keysAction = true
		self.pvProgress.progress = 0
		self.pvProgress.isHidden = false
		self.vWait.isHidden = false
		
		let alert = UIAlertController.init(title: NSLocalizedString("EncryptTitle", comment: "Шифрование"), message: NSLocalizedString("EncryptMessage", comment: "Шифрование"), preferredStyle: UIAlertController.Style.alert)
		alert.addTextField(configurationHandler: configurationTextField)
		alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertAction.Style.default, handler: { _ in
			
			let psw = alert.textFields![0].text ?? ""
			
			if psw != "" {
				DispatchQueue.global().async {
					var json: [String: Any] = [:]
					let v = self.app.model!.Addresses.map { "\($0.type)" + ($0.privateKey as Data).base64EncodedString().aesEncrypt(key: Crypto.md5(psw), iv: Crypto.md5("00000020219510518024419136177230"))! }
					var hs = ""
					var idx = 0
					for s in v { hs = hs + s; idx += 1; DispatchQueue.main.async { self.pvProgress.setProgress(Float(idx) / Float(v.count), animated: true) } }
					hs = hs + psw
					let hash = Crypto.sha256(hs.data(using: String.Encoding.utf8)!).base64EncodedString()
					json["version"] = "1.1"
					json["hash"] = hash
					json["keys"] = v
					let jsonData = try? JSONSerialization.data(withJSONObject: json)
					let urlToShare = jsonData?.fileUrl(withName: "keys.bio")
					
					DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
						self.vWait.isHidden = true
						self.keysAction = false
						if urlToShare != nil {
							self.shareUrl(urlToShare!)
						}
					})
				}
			} else {
				self.vWait.isHidden = true
				self.keysAction = false
				alert.dismiss(animated: true, completion: nil)
			}
		}))
		alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertAction.Style.cancel, handler: { _ in
			self.vWait.isHidden = true
			alert.dismiss(animated: true, completion: nil)
		}))
		self.present(alert, animated: true, completion: nil)
		
	}
	
	func configurationTextField(textField: UITextField!) {
		textField.placeholder = NSLocalizedString("Key", comment: "Key")
		textField.isSecureTextEntry = true
	}
	
	@IBAction func loadKeys(_ sender: Any?) -> Void {
		self.vWait.isHidden = false
		self.keysAction = true
		self.pvProgress.progress = 0
		self.pvProgress.isHidden = false
		
		let dpvc = UIDocumentPickerViewController(documentTypes: [String(kUTTypeData)], in: .import)
		dpvc.allowsMultipleSelection = false
		dpvc.delegate = self
		self.present(dpvc, animated: true, completion: nil)
	}
	
	//UIDocumentPickerDelegateb
	
	public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		let file: Data? = try? Data.init(contentsOf: urls[0], options: .uncachedRead)
		if file != nil {
			let jsonData = try? JSONSerialization.jsonObject(with: file!, options: JSONSerialization.ReadingOptions.mutableContainers)
			
			if jsonData != nil {
				let alert = UIAlertController.init(title: NSLocalizedString("EncryptTitle", comment: "Шифрование"), message: NSLocalizedString("EncryptMessage", comment: "Шифрование"), preferredStyle: UIAlertController.Style.alert)
				alert.addTextField(configurationHandler: configurationTextField)
				alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertAction.Style.default, handler: { _ in
					
					let psw = alert.textFields![0].text ?? ""
					
					if psw != "" {
						let json = jsonData as? [String:Any]
						if json!["version"] as? String ?? "" == "1.0" ||
							json!["version"] as? String ?? "" == "1.1" {
							let version = json!["version"] as? String ?? ""
							let hash = json!["hash"] as! String
							let v = json!["keys"] as! [String]
							
							var hs = ""
							for s in v { hs = hs + s }
							hs = hs + psw
							let hashFile = Crypto.sha256(hs.data(using: String.Encoding.utf8)!).base64EncodedString()
							
							if hashFile == hash {
								DispatchQueue.global().async {
									var idx = 0
									for sKey in v {
										let keyType = Int16(String(sKey[String.Index(encodedOffset: 0)]))
										let keyData = String(sKey[String.Index(encodedOffset: 1)..<String.Index(encodedOffset: sKey.count)])
										let privKey = version == "1.0" ? Data(base64Encoded: keyData.aesDecrypt(key: psw, iv: "20219510518024419136177230")!)! : Data(base64Encoded: keyData.aesDecrypt(key: Crypto.md5(psw), iv: Crypto.md5("00000020219510518024419136177230"))!)!
										let w: Wallet = Wallet.init(privateKey: privKey)
										self.app.model!.storeWallet(w, false, keyType! == 0 ? .Incoming : .Change)
										idx += 1
										DispatchQueue.main.async { self.pvProgress.setProgress(Float(idx) / Float(v.count), animated: true) }
									}
									self.app.model!.save(self.app)
									self.app.model!.reload(self.app)
									
									DispatchQueue.main.async {
										self.vWait.isHidden = true
										self.keysAction = false
										
										let alert = UIAlertController.init(title: NSLocalizedString("KeyStoreImportTitle", comment: "Ключи"), message: NSLocalizedString("KeyStoreImportMessage", comment: "Ключи"), preferredStyle: UIAlertController.Style.alert)
										alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertAction.Style.cancel, handler: nil))
										self.present(alert, animated: true, completion: nil)
									}
								}
							} else {
								let alert = UIAlertController.init(title: NSLocalizedString("EncryptTitle", comment: "Шифрование"), message: NSLocalizedString("EncryptPasswordErrorMessage", comment: "Шифрование"), preferredStyle: UIAlertController.Style.alert)
								alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertAction.Style.cancel, handler: nil))
								self.present(alert, animated: true, completion: nil)
								
								self.vWait.isHidden = true
								self.keysAction = false
							}
						}
					}
				}))
				alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertAction.Style.cancel, handler: { _ in
					DispatchQueue.main.sync {
						self.vWait.isHidden = true
						self.keysAction = false
					}
					alert.dismiss(animated: true, completion: nil)
				}))
				present(alert, animated: true, completion: nil)
			}
		}
	}
	
	func loadKeysFromUrl(_ url: URL) {
		self.vWait.isHidden = false
		self.keysAction = true
		self.pvProgress.progress = 0
		self.pvProgress.isHidden = false
		
		DispatchQueue.main.async {
			self.documentPicker(UIDocumentPickerViewController(documentTypes: [String(kUTTypeData)], in: .import), didPickDocumentsAt: [url])
		}
	}
	
	override func processUrlCommand() {
		let app = UIApplication.shared.delegate as! AppDelegate
		if app.needToProcessURL {
			if (app.openUrl != nil) {
				let components = URLComponents(url: app.openUrl!, resolvingAgainstBaseURL: true)
				if components?.scheme?.lowercased() == "file" {
					app.needToProcessURL = false
					loadKeysFromUrl(app.openUrl!)
				} else {
					super.processUrlCommand()
				}
			}
		}
	}
	
	//MFMailComposeViewControllerDelegate
	
	func mailComposeController(_ controller: MFMailComposeViewController,
							   didFinishWith result: MFMailComposeResult, error: Error?) {
		controller.dismiss(animated: true, completion: nil)
	}
}
