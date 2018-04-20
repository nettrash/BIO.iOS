//
//  EllipticCurve.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

public class EllipticCurve : NSObject {
	
	public var curve: CurveFP?
	public var N: BigInteger?
	public var H: BigInteger?
	public var G: PointFP?
	
	override init() {
		super.init()
		
		let p: BigInteger = BigInteger(Data("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F".hexa2Bytes))
		let a: BigInteger = BigInteger(0)
		let b: BigInteger = BigInteger(7)
		N = BigInteger(Data("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141".hexa2Bytes))
		H = BigInteger(1)
		curve = CurveFP(p, a, b)
		G = curve?.decodePoint(("04" +
						   "79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798" +
						   "483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8").hexa2Bytes)
	}
	
	public static func integerToBytes(_ i: BigInteger, _ len: Int) -> [UInt8] {
		var bytes: [UInt8] = i.toByteArrayUnsigned()
		if len < bytes.count {
			bytes = [UInt8](bytes[(bytes.count-len)...])
		} else {
			while len > bytes.count {
				bytes = bytes.shifted(by: 0)
			}
		}
		return bytes
	}
}
