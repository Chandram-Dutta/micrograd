import XCTest

@testable import micrograd

final class microgradTests: XCTestCase {
	func testValuePrint() throws {
		let b = Value(8.0)
		XCTAssertEqual("Value(data=8.0)", b.description)
		XCTAssertEqual([], b._prev)
		XCTAssertEqual("", b._op)
	}
	
	func testValueAdd() throws {
		let c = Value(8.0)
		let d = Value(2.0)
		XCTAssertEqual("Value(data=10.0)", (c + d).description)
		XCTAssertEqual([Value(8.0), Value(2.0)], (c + d)._prev)
		XCTAssertEqual("+", (c + d)._op)
	}
	
	func testValueMul() throws {
		let c = Value(8.0)
		let d = Value(-2.0)
		XCTAssertEqual("Value(data=-16.0)", (c * d).description)
		XCTAssertEqual([Value(8.0), Value(-2.0)], (c * d)._prev)
		XCTAssertEqual("*", (c * d)._op)
	}
	
	func testBackPropogation() throws {
		let a = Value(3.0)
		let b = a + a
		b.backward()
		XCTAssertEqual(
			"Value(data=6.0, grad=1.0, _op=+, _prev=Value(data=3.0, grad=2.0, _op=, _prev=",
			(b).debugDescription)
	}
}
