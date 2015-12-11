//
//  AudioDevice.swift
//  iOS
//
//  Created by Kota Nakano on 12/9/15.
//
//
import Foundation
import CoreAudioKit
import CoreAudio
import AudioToolbox

public class AudioDevice {
	let unit: AudioUnit
	private init(let unit: AudioUnit) {
		self.unit = unit
		AudioUnitInitialize(self.unit)
	}
	deinit {
		AudioUnitUninitialize(self.unit)
	}
	
	public func start<T> (let task:(UnsafeMutableBufferPointer<T>, UnsafeBufferPointer<T>)->Void) -> Bool {		
/*
		let callback: ((UnsafeMutablePointer<Void>, UnsafeMutablePointer<AudioUnitRenderActionFlags>, UnsafePointer<AudioTimeStamp>, UInt32, UInt32, UnsafeMutablePointer<AudioBufferList>) -> OSStatus) = { (opt, auraf, ats, bus, frame, abl) -> OSStatus in
			return noErr
		}
		print(callback)
		*/
//		let aurcbs = AURenderCallbackStruct(inputProc: c, inputProcRefCon: nil)
//		print(aurcbs)
		
		let ok = AURenderCallbackStruct(inputProc: { (a: UnsafeMutablePointer<Void>, b: UnsafeMutablePointer<AudioUnitRenderActionFlags>, c: UnsafePointer<AudioTimeStamp>, d: UInt32, e: UInt32, f: UnsafeMutablePointer<AudioBufferList>) -> OSStatus in
			return noErr
			}, inputProcRefCon: nil)
		print(ok)
		return true
	}
	
	public var name: String {
		var name: String = ""
		let result: [CChar] = AudioDevice.get(unit, property: kAudioUnitProperty_NickName)
		if let result = String.fromCString(result) {
			name = result
		}
		return name
	}
	
	public var sampleRate: Double {
		get {
			var sampleRate: Double = 0
			if let value: Double = AudioDevice.get(unit, property: kAudioUnitProperty_SampleRate) {
				sampleRate = value
			}
			return sampleRate
		}
		set {
			AudioDevice.set(unit, property: kAudioUnitProperty_SampleRate, value: newValue)
		}
	}
	
	public var iChannel: Int {
		var iChannel: Int = 0
		if let value: AudioStreamBasicDescription = AudioDevice.get(unit, property: kAudioUnitProperty_StreamFormat, scope: kAudioUnitScope_Input) {
			iChannel = Int(value.mChannelsPerFrame)
		}
		return iChannel
	}
	
	public var oChannel: Int {
		var oChannel: Int = 0
		if let value: AudioStreamBasicDescription = AudioDevice.get(unit, property: kAudioUnitProperty_StreamFormat, scope: kAudioUnitScope_Output) {
			oChannel = Int(value.mChannelsPerFrame)
		}
		return oChannel
	}
	
	public var quantize: Int {
		get {
			var quantize: Int = 0
			if let value: AudioStreamBasicDescription = AudioDevice.get(unit, property: kAudioUnitProperty_StreamFormat, scope: kAudioUnitScope_Output) {
				quantize = Int(value.mBitsPerChannel/8)
			}
			return quantize
		}
	}
	
	public var bufferSize: Int {
		get {
			var bufferSize: Int = 0
			if let value: AudioStreamBasicDescription = AudioDevice.get(unit, property: kAudioUnitProperty_StreamFormat, scope: kAudioUnitScope_Output) {
				bufferSize = Int(value.mBytesPerFrame)
			}
			return bufferSize
		}
	}
	
	
}

extension AudioDevice {
	public class var found: [AudioDevice] {
		var found: [AudioDevice] = []
		var desc: AudioComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_RemoteIO, componentManufacturer: 0, componentFlags: 0, componentFlagsMask: 0)
		var component: AudioComponent = AudioComponentFindNext(nil, &desc)
		while nil != component {
			var unit: AudioUnit = nil
			AudioComponentInstanceNew(component, &unit)
			found.append(AudioDevice(unit: unit))
			component = AudioComponentFindNext(component, &desc)
		}
		return found
	}
	
	private class var scope: AudioUnitScope {
		return kAudioUnitScope_Global
	}
	private class var element: AudioUnitElement {
		return 0
	}
	
	private class func get<T> (let target: AudioUnit, let property: AudioUnitPropertyID, let scope: AudioUnitScope = AudioDevice.scope, let element: AudioUnitElement = AudioDevice.element ) -> [T] {
		var result: [T] = []
		var dataSize: UInt32 = 0
		if noErr == AudioUnitGetProperty(target, property, scope, element, nil, &dataSize) {
			let dataCount: UInt32 = dataSize / UInt32(sizeof(T))
			let buffer: UnsafeMutablePointer<T> = UnsafeMutablePointer<T>.alloc(Int(dataCount))
			if noErr == AudioUnitGetProperty(target, property, scope, element, buffer, &dataSize) {
				result = Array<T>(UnsafeBufferPointer<T>(start: UnsafePointer<T>(buffer), count: Int(dataCount)))
			}
		}
		return result
	}
	private class func get<T> (let target: AudioUnit, let property: AudioUnitPropertyID, let scope: AudioUnitScope = AudioDevice.scope, let element: AudioUnitElement = AudioDevice.element ) -> T? {
		return get(target, property: property, scope: scope, element: element).first
	}
	private class func set<T> (let target: AudioUnit, let property: AudioUnitPropertyID, var value: T, let scope: AudioUnitScope = AudioDevice.scope, let element: AudioUnitElement = AudioDevice.element ) {
		AudioUnitSetProperty(target, property, scope, element, &value, UInt32(sizeof(T)))
	}
	private class func set<T> (let target: AudioUnit, let property: AudioUnitPropertyID, var value: [T], let scope: AudioUnitScope = AudioDevice.scope, let element: AudioUnitElement = AudioDevice.element ) {
		AudioUnitSetProperty(target, property, scope, element, &value, UInt32(sizeofValue(value)))
	}
}