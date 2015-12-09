//
//  AUI.swift
//  AUI
//
//  Created by Kota Nakano on 12/8/15.
//
//

import Foundation
internal protocol AudioDeviceProtocol: CustomStringConvertible {
	func start<T> (let task:(UnsafeMutableBufferPointer<T>, UnsafeBufferPointer<T>)->Void) -> Bool
	func stop ()

	var name: String {get}
	var manufacture: String {get}
	
	var running: Bool {get}

	var iChannel: Int{get set}
	var iChannels: [Int]{get}
	var oChannel: Int{get set}
	var oChannels: [Int]{get}
	
	var sampleRate: Double{get set}
	var sampleRates: [(Double, Double)]{get}

	var bufferSize: Int{get set}
	var bufferSizes: [(Int, Int)]{get}
	
	var frameLength: Int{get set}
	var frameLengths: [(Int, Int)]{get}
	
	var bytePerChannel: Int{get set}
	var bytePerChannels: [(Int, Int)]{get}
	
}