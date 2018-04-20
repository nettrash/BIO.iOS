//
//  BalanceResponse.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

struct BalanceResponse {
	
	var Received: UInt64
	var Success: UInt8
	var Value: UInt64
	
	init?(json: [String:Any]) {
		guard let received = json["Received"] as? UInt64,
			let success = json["Success"] as? UInt8,
			let value = json["Value"] as? UInt64 else {
				return nil
			}
		self.Received = received
		self.Success = success
		self.Value = value
	}
	
}
