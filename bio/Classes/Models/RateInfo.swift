//
//  RateInfo.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

public class RateInfo : NSObject {
	
	var Currency: String?
	var Rate: Double?
	
	public init(currency: String, rate: Double) {
		Currency = currency
		Rate = rate
	}
}
