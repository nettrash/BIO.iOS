//
//  ArrayExtensions.swift
//  bio
//
//  Created by Иван Алексеев on 20.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation

extension Array {
	
	func shifted(by shiftAmount: Int) -> Array<Element> {
		
		guard self.count > 0, (shiftAmount % self.count) != 0 else { return self }
		
		let moduloShiftAmount = shiftAmount % self.count
		let negativeShift = shiftAmount < 0
		let effectiveShiftAmount = negativeShift ? moduloShiftAmount + self.count : moduloShiftAmount
		
		let shift: (Int) -> Int = { return $0 + effectiveShiftAmount >= self.count ? $0 + effectiveShiftAmount - self.count : $0 + effectiveShiftAmount }
		
		return self.enumerated().sorted(by: { shift($0.offset) < shift($1.offset) }).map { $0.element }
		
	}
	
}
