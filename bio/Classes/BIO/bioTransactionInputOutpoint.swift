//
//  bioTransactionInputOutpoint.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2017 NETTRASH. All rights reserved.
//

import Foundation

class bioTransactionInputOutpoint : NSObject {
	
	var Address: String
	var Hash: String
	var Index: UInt32
	
	init(_ address: String, _ hash: String, _ index: UInt32) {
		Address = address
		Hash = hash
		Index = index
		super.init()
	}
}
