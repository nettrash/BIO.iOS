//
//  Barret.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

public class Barret : NSObject {
	
	var r2: BigInteger
	var q3: BigInteger
	var mu: BigInteger
	var m: BigInteger
	
	init(_ biQ: BigInteger) {
		r2 = BigInteger(1).dlShift(2 * biQ.t)
		q3 = BigInteger()
		mu = try! r2.divide(biQ)
		m = biQ
		super.init()
	}
	
	public func reduce(_ v: BigInteger) -> BigInteger {
		var x: BigInteger = v
		r2 = x.drShift(m.t-1)
		if x.t > m.t+1 {
			x.t = m.t + 1
			x.clamp()
		}
		q3 = mu.multiplyUpper(r2, m.t+1)
		r2 = m.multiplyLower(q3, m.t+1)
		while x.compareTo(r2) < 0 {
			x.dAddOffset(1, m.t+1)
		}
		x = x.subtract(r2)
		while x.compareTo(m) >= 0 {
			x = x.subtract(m)
		}
		return x
	}
}
