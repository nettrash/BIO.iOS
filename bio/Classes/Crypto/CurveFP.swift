//
//  CurveFP.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

public class CurveFP : NSObject {
	
	public enum Exception : Error {
		case InvalidPointCompression
	}
	
	var q: BigInteger?
	var a: FieldElementFP?
	var b: FieldElementFP?
	public var infinity: PointFP?
	var reducer: Barret?
	
	init(_ biQ: BigInteger, _ biA: BigInteger, _ biB: BigInteger) {
		super.init()
		q = biQ
		a = FieldElementFP(biQ, biA)
		b = FieldElementFP(biQ, biB)
		infinity = PointFP(self)
		reducer = Barret(biQ)
	}
	
	public func decodePoint(_ data: [UInt8]) -> PointFP? {
		switch data[0] {
		case 0:
			return infinity
		/*case 2,3: //compressed, compressed
			let tilde = data[0] & 1
			let X1 = BigInteger(Data([UInt8](data[1...data.count - 1])))
			return try! decompressPoint(tilde, X1)*/
		case 4,6,7: //uncompressed, hybrid, hybrid
			let len = (data.count - 1) / 2
			let x = FieldElementFP(q!, BigInteger(Data([UInt8](data[1...len]))))
			let y = FieldElementFP(q!, BigInteger(Data([UInt8](data[len + 1...2 * len]))))
			return PointFP(self, x, y)
		default:
			return nil
		}
	}
	
	public func fromBigInteger(_ v: BigInteger) -> FieldElementFP {
		return FieldElementFP(q!, v)
	}
	
	public func reduce(_ r: BigInteger) -> BigInteger {
		return reducer!.reduce(r)
	}
}
