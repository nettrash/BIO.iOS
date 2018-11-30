//
//  WebViewController.swift
//  bio
//
//  Created by Иван Алексеев on 27.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class WebViewController : BaseViewController, WKNavigationDelegate {
	
	@IBOutlet var webView: WKWebView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.webView.navigationDelegate = self
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.webView.load(URLRequest(url: URL(string: (UIApplication.shared.delegate as! AppDelegate).model!.buyRedirectUrl)!))
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	//WKNavigationDelegate
	
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		let url = webView.url?.absoluteString
		if url?.starts(with: "https://service.biocoin.pro/PaymentPortal/WS/State") ?? false {
			let c = URLComponents.init(string: url!)
			(UIApplication.shared.delegate as! AppDelegate).model!.buyOpKey = c?.queryItems?.filter { $0.name == "OpKey" }.first!.value ?? ""
			performSegue(withIdentifier: unwindIdentifiers["3ds-auth"]!, sender: self)
		}
	}
}
