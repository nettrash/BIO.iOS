//
//  Rates.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

public class Rates: NSObject {

	var Items: [RateInfo] = []

	func load(_ rates: [Any]) {
		Items = rates.map({ (_ r: Any) -> RateInfo in
			
			let rate = r as? [String: Any]
			let rateValue: Double = rate?["Rate"] as! Double
			let currency: String = rate?["Currency"] as! String
			
			return RateInfo(currency: currency, rate: rateValue)
		})
	}

}
