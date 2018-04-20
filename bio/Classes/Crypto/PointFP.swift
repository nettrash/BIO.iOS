//
//  PointFP.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

public class PointFP : NSObject {
	
	var curve: CurveFP?
	var x: FieldElementFP?
	var y: FieldElementFP?
	var z: BigInteger?
	var zinv: BigInteger?
	var compressed: Bool?
	
	init(_ c: CurveFP, _ biX: FieldElementFP? = nil, _ biY: FieldElementFP? = nil, _ compress: Bool = false) {
		super.init()
		curve = c
		x = biX
		y = biY
		z = BigInteger(1)
		zinv = nil
		compressed = compress
	}
	
	init(_ c: CurveFP, _ biX: FieldElementFP? = nil, _ biY: FieldElementFP? = nil, _ biZ: BigInteger, _ compress: Bool = false) {
		super.init()
		curve = c
		x = biX
		y = biY
		z = biZ
		zinv = nil
		compressed = compress
	}

	private func _isInfinity() -> Bool {
		if x == nil && y == nil { return true }
		return z!.equals(BigInteger(0)) && !y!.toBigInteger().equals(BigInteger(0))
	}
	
	public func negate() -> PointFP {
		return PointFP(curve!, x!, y!.negate(), compressed!)
	}
	
	public func multiply(_ k: BigInteger) -> PointFP {
		if _isInfinity() { return self }
		if k.signum() == 0 { return curve!.infinity! }
		let e = k
		let h = e.multiply(BigInteger(3))
		let neg = negate()
		var R = self
		for i in (1...h.bitLength-2).reversed() {
			R = R.twice()
			let hBit: Bool = h.testBit(i)
			let eBit: Bool = e.testBit(i)
			
			if hBit != eBit {
				R = R.add(hBit ? self : neg)
			}
		}
		return R
	}
	
	public func twice() -> PointFP {
		if _isInfinity() { return self }
		if y!.toBigInteger().signum() == 0 { return curve!.infinity! }
		let three = BigInteger(3)
		let x1 = x!.toBigInteger()
		let y1 = y!.toBigInteger()
		let y1z1 = y1.multiply(z!)
		let y1sqz1 = y1z1.multiply(y1).mod(curve!.q!)
		let a = curve!.a!.toBigInteger()
		var w = x1.square().multiply(three)
		if !BigInteger(0).equals(a) {
			w = w.add(z!.square().multiply(a))
		}
		w = w.mod(curve!.q!)
		let x3 = w.square().subtract(x1.shiftLeft(3).multiply(y1sqz1)).shiftLeft(1).multiply(y1z1).mod(curve!.q!)
		let y3 = w.multiply(three).multiply(x1).subtract(y1sqz1.shiftLeft(1)).shiftLeft(2).multiply(y1sqz1).subtract(w.square().multiply(w)).mod(curve!.q!)
		let z3 = y1z1.square().multiply(y1z1).shiftLeft(3).mod(curve!.q!)
		return PointFP(curve!, curve!.fromBigInteger(x3), curve!.fromBigInteger(y3), z3, false)
	}
	
	public func add(_ b: PointFP) -> PointFP {
		if _isInfinity() { return b }
		if b._isInfinity() { return self }
		let u = b.y!.toBigInteger().multiply(z!).subtract(y!.toBigInteger().multiply(b.z!)).mod(curve!.q!)
		let v = b.x!.toBigInteger().multiply(z!).subtract(x!.toBigInteger().multiply(b.z!)).mod(curve!.q!)
		if BigInteger(0).equals(v) {
			if BigInteger(0).equals(u) {
				return twice()
			}
			return curve!.infinity!
		}
		let three = BigInteger(3)
		let x1 = x!.toBigInteger()
		let y1 = y!.toBigInteger()
		//let x2 = b.x!.toBigInteger()
		//let y2 = b.y!.toBigInteger()
		let v2 = v.square()
		let v3 = v2.multiply(v)
		let x1v2 = x1.multiply(v2)
		let zu2 = u.square().multiply(z!)
		
		let x3 = zu2.subtract(x1v2.shiftLeft(1)).multiply(b.z!).subtract(v3).multiply(v).mod(curve!.q!)
		let y3 = x1v2.multiply(three).multiply(u).subtract(y1.multiply(v3)).subtract(zu2.multiply(u)).multiply(b.z!).add(u.multiply(v3)).mod(curve!.q!)
		let z3 = v3.multiply(z!).multiply(b.z!).mod(curve!.q!)
		
		return PointFP(curve!, curve!.fromBigInteger(x3), curve!.fromBigInteger(y3), z3, false)
	}
	
	public func getX() -> FieldElementFP {
		if zinv == nil {
			zinv = z!.modInverse(curve!.q!)
		}
		var r = x!.toBigInteger().multiply(zinv!)
		r = curve!.reduce(r)
		return curve!.fromBigInteger(r)
	}
	
	public func getY() -> FieldElementFP {
		if zinv == nil {
			zinv = z!.modInverse(curve!.q!)
		}
		var r = y!.toBigInteger().multiply(zinv!)
		r = curve!.reduce(r)
		return curve!.fromBigInteger(r)
	}
}
