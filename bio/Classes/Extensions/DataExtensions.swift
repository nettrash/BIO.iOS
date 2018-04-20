//
//  DataExtensions.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

extension Data {
	
	func hexEncodedString() -> String {
		return map { String(format: "%02hhx", $0) }.joined()
	}
	
	func fileUrl(withName name: String) -> URL {
		
		let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
		
		try! write(to: url, options: .atomicWrite)
		
		return url
	}
}
