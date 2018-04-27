//
//  bioTests.swift
//  bioTests
//
//  Created by Иван Алексеев on 03.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import XCTest
@testable import bio

class bioTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateWallet() {
		let w = Wallet()
		w.initialize("test")
		XCTAssert(w.Address == "SRcxum6SzkCLkgC3W8vzSeiVtdiPrbH9zB")
		XCTAssert(w.WIF == "Kz45ruVNX4YRYobW6nqjCjFnjDw67rRV2ZJoq3akysBX9qQNWHNC")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
