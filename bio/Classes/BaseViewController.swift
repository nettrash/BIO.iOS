//
//  BaseViewController.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import UIKit

class BaseViewController: UIViewController {
	
	public var unwindIdentifiers: [String:String] = [String:String]()
	public var flipRight = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		/*for v in view.subviews {
			if v is SIBLogoImageView {
				(v as! SIBLogoImageView).image = UIImage(named: NSLocalizedString("BIOLogoImageName", comment: "BIOLogoImageName"))
			}
		}*/
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.view.endEditing(true)
	}
	
	func roundCorners(_ v: UIView) -> Void {
		for v in v.subviews {
			if v is UITextField || v is UIButton {
				(v as UIView).layer.cornerRadius = 4.0
			}
		}
	}
	
	public func processUrlCommand() -> Void {
		/*if (UIApplication.shared.delegate as! AppDelegate).needToProcessURL {
			dismiss(animated: false, completion: nil)
			DispatchQueue.main.async {
				(self.parent as? BaseViewController)?.processUrlCommand()
			}
		}*/
	}
	
	public func showError(error: String) -> Void {
		let alert = UIAlertController.init(title: NSLocalizedString("Error", comment: "Ошибка"), message: error, preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Отмена"), style: UIAlertActionStyle.cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
		self.present(alert, animated: true, completion: nil)
	}
	
	public func shareText(_ text: String) -> Void {
		let activityViewController : UIActivityViewController = UIActivityViewController(
			activityItems: [text], applicationActivities: [])
		present(activityViewController, animated: true, completion: nil)
	}
	
	public func shareUrl(_ url: URL) -> Void {
		let activityViewController : UIActivityViewController = UIActivityViewController(
			activityItems: [url], applicationActivities: [])
		present(activityViewController, animated: true, completion: nil)
	}
	
	@objc func flip(_ firstView: UIView, _ secondView: UIView) {
		
		let transitionOptions: UIViewAnimationOptions = [flipRight ? .transitionFlipFromRight : .transitionFlipFromLeft, .showHideTransitionViews]
		
		UIView.transition(with: firstView, duration: 1.0, options: transitionOptions, animations: {
			firstView.isHidden = true
		})
		
		UIView.transition(with: secondView, duration: 1.0, options: transitionOptions, animations: {
			secondView.isHidden = false
		})
	}
}
