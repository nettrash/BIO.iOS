//
//  IntegerExtensions.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

extension Int {
	
	var nbits: Int {
		var x = self
		var r = 1
		var t = x >> 16
		if t != 0 {
			x = t
			r = r + 16
		}
		t = x >> 8
		if t != 0 {
			x = t
			r = r + 8
		}
		t = x >> 4
		if t != 0 {
			x = t
			r = r + 4
		}
		t = x >> 2
		if t != 0 {
			x = t
			r = r + 2
		}
		t = x >> 1
		if t != 0 {
			x = t
			r = r + 1
		}
		return r
	}
	
}
