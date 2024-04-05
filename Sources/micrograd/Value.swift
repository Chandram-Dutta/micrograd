//
//  Value.swift
//
//
//  Created by Chandram Dutta on 30/03/24.
//

import Foundation

precedencegroup ExponentPrecedentGroup {
	higherThan: MultiplicationPrecedence
	associativity: right
}

infix operator ** : ExponentPrecedentGroup

class Value<T: Numeric & Comparable>: CustomStringConvertible, Hashable {
	
	var data: T
	var grad: T
	var _backward: () -> Void
	
	let _prev: Set<Value>
	let _op: String
	
	public init(_ data: T, _ children: Set<Value> = [], _ op: String = "") {
		self.data = data
		self._prev = children
		self._op = op
		self.grad = 0
		self._backward = {}
	}
	
	func copy(with zone: NSZone? = nil) -> Any {
		let copy = Value(data, _prev, _op)
		return copy
	}
	
	var description: String { return "Value(data=\(self.data))" }
	var debugDescription: String {
		let prevDescriptions = _prev.map { $0.debugDescription }.joined(separator: ", ")
		return "Value(data=\(self.data), grad=\(self.grad), _op=\(self._op), _prev=\(prevDescriptions)"
	}
	
	static func == (lhs: Value<T>, rhs: Value<T>) -> Bool {
		return lhs.data == rhs.data && lhs._prev == rhs._prev && lhs._op == rhs._op
	}
	
	public func hash(into hasher: inout Hasher) {}
	
	//MARK: Addition
	static func + (lhs: Value<T>, rhs: Value<T>) -> Value<T> {
		let out = Value(lhs.data + rhs.data, [lhs, rhs], "+")
		
		func _backward() {
			lhs.grad += 1 * out.grad
			rhs.grad += 1 * out.grad
		}
		
		out._backward = _backward
		return out
	}
	
	//MARK: Negation
	static prefix func - (self: Value<T>) -> Value<T> {
		let copy = self.copy() as! Value<T>
		copy.data = 0 - copy.data  // workaround `-copy.data`
		return copy
	}
	
	//MARK: Subtract
	static func - (lhs: Value<T>, rhs: Value<T>) -> Value<T> {
		return lhs + -rhs
	}
	
	//MARK: Multiplication
	static func * (lhs: Value<T>, rhs: Value<T>) -> Value<T> {
		let out = Value(lhs.data * rhs.data, [lhs, rhs], "*")
		func _backward() {
			lhs.grad += rhs.data * out.grad
			rhs.grad += lhs.data * out.grad
		}
		out._backward = _backward
		return out
	}
	
	//MARK: Division
	static func / (lhs: Value<T>, rhs: Value<T>) -> Value<T> {
		let d: Value<T> = (rhs as! Value<Double>) ** (Value(-1.0 as! T) as! Value<Double>)
		return lhs * d
	}
	
	//MARK: Exponent
	static func ** (lhs: Value<Double>, rhs: Value<Double>) -> Value<T> {
		let out = Value<T>(pow(lhs.data, rhs.data) as! T, [lhs as! Value<T>], "**\(rhs)")
		
		func _backward() {
			lhs.grad +=
			(((rhs.data as! T) * (pow(lhs.data, (rhs.data - 1)) as! T)) * (out.grad)) as! Double
		}
		out._backward = _backward
		return out
		
	}
	
	//MARK: ReLU
	static func relu(self: Value) -> Value<T> {
		let out = Value(self.data < (0 as! T) ? 0 : self.data, [self], "ReLU")
		func _backward() {
			self.grad += out.data > 0 ? out.grad : 0
		}
		out._backward = _backward
		return out
	}
}

extension Value {
	func backward() {
		var topo = [Value<T>]()
		var visited = Set<Value<T>>()
		func buildTopo(v: Value<T>) {
			if !visited.contains(v) {
				visited.insert(v)
				for child in v._prev {
					buildTopo(v: child)
				}
				topo.append(v)
			}
		}
		buildTopo(v: self)
		self.grad = 1
		for node in topo.reversed() {
			node._backward()
		}
	}
}
