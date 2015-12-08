//
//  CoreAudioDevice.swift
//  OSX
//
//  Created by Kota Nakano on 12/8/15.
//
import CoreAudio
public class CoreAudioDevice: CustomStringConvertible
{
	let device: AudioDeviceID
	var ioproc: AudioDeviceIOProcID?
	
	// MARK: Stop
	
	private init(let device: AudioDeviceID) {
		self.device = device
	}
	deinit {
		if running {
			stop()
		}
	}
	
	// MARK: Start
	
	public func start<T> (let task:(UnsafeMutableBufferPointer<T>, UnsafeBufferPointer<T>)->Void) -> Bool {
		stop()
		return noErr == AudioDeviceCreateIOProcIDWithBlock(&ioproc, device, CoreAudioDevice.dispatch, { (
			let iats: UnsafePointer<AudioTimeStamp>, let iabl: UnsafePointer<AudioBufferList>,
			let oats: UnsafePointer<AudioTimeStamp>, let oabl: UnsafeMutablePointer<AudioBufferList>,
			let ats: UnsafePointer<AudioTimeStamp>) -> Void in
			let ibuf: UnsafeBufferPointer<T> = UnsafeBufferPointer<T>(iabl.memory.mBuffers)
			let obuf: UnsafeMutableBufferPointer<T> = UnsafeMutableBufferPointer<T>(oabl.memory.mBuffers)
			task(obuf, ibuf)
		}) && noErr == AudioDeviceStart(device, ioproc)
	}
	
	// MARK: Stop
	
	public func stop () {
		if running {
			AudioDeviceStop(device, ioproc)
		}
		if let ioproc = ioproc {
			AudioDeviceDestroyIOProcID(device, ioproc)
		}
	}
	
	// MARK: Dump
	
	public var description: String {
		return "\(name) by \(manufacture) @ \(sampleRate) Hz, \(bytePerChannel*8) bits, input: \(iChannel), output: \(oChannel)"
	}
	
	
	// MARK: Status
	
	public var name: String {
		var result: String = ""
		let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyDeviceName)
		let name: [CChar] = CoreAudioDevice.get(device, property: property)
		if let string: String = String.fromCString(name) {
			result = string
		}
		return result
	}
	public var manufacture: String {
		var result: String = ""
		let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyDeviceManufacturer)
		let name: [CChar] = CoreAudioDevice.get(device, property: property)
		if let string: String = String.fromCString(name) {
			result = string
		}
		return result
	}
	public var alive: Bool {
		var result: Bool = false
		let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyDeviceIsAlive)
		if let value: Bool = CoreAudioDevice.get(device, property: property) {
			result = value
		}
		return result
	}
	public var running: Bool {
		var result: Bool = false
		let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyDeviceIsRunning)
		if let value: Bool = CoreAudioDevice.get(device, property: property) {
			result = value
		}
		return result
	}
	public var hidden: Bool {
		var result: Bool = false
		let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyIsHidden)
		if let value: Bool = CoreAudioDevice.get(device, property: property) {
			result = value
		}
		return result
	}
	
	// MARK: SampleRate
	
	public var sampleRate: Double {
		get {
			var result: Double = 0
			let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyNominalSampleRate)
			if let value: Double = CoreAudioDevice.get(device, property: property).first {
				result = value
			}
			return result
		}
		set {
			let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyNominalSampleRate)
			let value: [Double] = [newValue]
			CoreAudioDevice.set(device, property: property, value: value)
		}
	}
	public var sampleRates: [(Double, Double)] {
		let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyAvailableNominalSampleRates)
		let values: [AudioValueRange] = CoreAudioDevice.get(device, property: property)
		return values.map{($0.mMinimum, $0.mMaximum)}
	}
	
	// MARK: BufferSize
	
	public var bufferSize: Int {
		get {
			let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyBufferSize)
			var result: Int = 0
			if let value: UInt32 = CoreAudioDevice.get(device, property: property) {
				result = Int(value)
			}
			return result
		}
		set {
			let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyBufferSize)
			CoreAudioDevice.set(device, property: property, value: UInt32(newValue))
		}
	}
	public var bufferSizes: [(Int, Int)] {
		let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyBufferSizeRange)
		let values: [AudioValueRange] = CoreAudioDevice.get(device, property: property)
		return values.map{(Int($0.mMinimum), Int($0.mMaximum))}
	}
	
	// MARK: FrameSize
	
	public var frameLength: Int {
		get {
			var result: Int = 0
			let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyBufferFrameSize)
			if let value: UInt32 = CoreAudioDevice.get(device, property: property) {
				result = Int(value)
			}
			return result
		}
		set {
			let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyBufferFrameSize)
			CoreAudioDevice.set(device, property: property, value: UInt32(newValue))
		}
	}
	public var frameLengths: [(Int, Int)] {
		let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyBufferFrameSizeRange)
		let values: [AudioValueRange] = CoreAudioDevice.get(device, property: property)
		return values.map{(Int($0.mMinimum), Int($0.mMaximum))}
	}
	
	// MARK: BytePerChannel
	
	public var bytePerChannel: Int {
		get {
			var result: Int = 0
			let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyStreamFormat)
			if let value: AudioStreamBasicDescription = CoreAudioDevice.get(device, property: property) {
				result = Int(value.mBitsPerChannel)/8
			}
			return result
		}
		set {
			let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyStreamFormat)
			if var value: AudioStreamBasicDescription = CoreAudioDevice.get(device, property: property) {
				value.mBitsPerChannel = UInt32(newValue*8)
				value.mBytesPerFrame = value.mBitsPerChannel * value.mChannelsPerFrame / 8
				value.mBytesPerPacket = value.mBytesPerFrame / value.mFramesPerPacket
				CoreAudioDevice.set(device, property: property, value: value)
			}
		}
	}
	public var bytePerChannels: [Int] {
		let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyStreamFormats)
		let values: [AudioStreamBasicDescription] = CoreAudioDevice.get(device, property: property)
		return values.map{Int($0.mBitsPerChannel)/8}
	}
	
	// MARK: IntputChannels
	
	public var iChannel: Int {
		get {
			var result: Int = 0
			let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyStreamFormat, scope: kAudioDevicePropertyScopeInput)
			if let value: AudioStreamBasicDescription = CoreAudioDevice.get(device, property: property) {
				result = Int(value.mChannelsPerFrame)
			}
			return result
		}
		set {
			let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyStreamFormat, scope: kAudioDevicePropertyScopeInput)
			if var value: AudioStreamBasicDescription = CoreAudioDevice.get(device, property: property) {
				value.mChannelsPerFrame = UInt32(newValue)
				value.mBytesPerFrame = value.mBitsPerChannel * value.mChannelsPerFrame / 8
				value.mBytesPerPacket = value.mBytesPerFrame / value.mFramesPerPacket
				CoreAudioDevice.set(device, property: property, value: value)
			}
		}
	}
	public var iChannels: [Int] {
		let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyStreamFormats, scope: kAudioDevicePropertyScopeInput)
		let values: [AudioStreamBasicDescription] = CoreAudioDevice.get(device, property: property)
		return values.map{Int($0.mChannelsPerFrame)}
	}
	
	// MARK: OutputChannels
	
	public var oChannel: Int {
		get {
			var result: Int = 0
			let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyStreamFormat, scope: kAudioDevicePropertyScopeOutput)
			if let value: AudioStreamBasicDescription = CoreAudioDevice.get(device, property: property) {
				result = Int(value.mChannelsPerFrame)
			}
			return result
		}
		set {
			let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyStreamFormat, scope: kAudioDevicePropertyScopeOutput)
			if var value: AudioStreamBasicDescription = CoreAudioDevice.get(device, property: property) {
				value.mChannelsPerFrame = UInt32(newValue)
				value.mBytesPerFrame = value.mBitsPerChannel * value.mChannelsPerFrame / 8
				value.mBytesPerPacket = value.mBytesPerFrame / value.mFramesPerPacket
				CoreAudioDevice.set(device, property: property, value: value)
			}
		}
	}
	public var oChannels: [Int] {
		let property: AudioObjectPropertyAddress = CoreAudioDevice.property(kAudioDevicePropertyStreamFormats, scope: kAudioDevicePropertyScopeOutput)
		let values: [AudioStreamBasicDescription] = CoreAudioDevice.get(device, property: property)
		return values.map{Int($0.mChannelsPerFrame)}
	}
	
}

// MARK: class vars

extension CoreAudioDevice
{
	private class var dispatch: dispatch_queue_t {
		return dispatch_queue_create("com.organi2e.kn.kotan", nil)
	}
	private class var scope: AudioObjectPropertyScope {
		return kAudioDevicePropertyScopeOutput
	}
	private class var element: AudioObjectPropertyElement {
		return kAudioObjectPropertyElementMaster
	}
	private class func property(let selector: AudioObjectPropertySelector, let scope: AudioObjectPropertyScope = scope, let element: AudioObjectPropertyElement = element) -> AudioObjectPropertyAddress {
		return AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
	}
	private class func get<T> (let target: AudioObjectID, var property: AudioObjectPropertyAddress ) -> [T] {
		var result: [T] = []
		var dataSize: UInt32 = 0
		if noErr == AudioObjectGetPropertyDataSize(target, &property, 0, nil, &dataSize) {
			let dataCount: UInt32 = dataSize / UInt32(sizeof(T))
			let buffer: UnsafeMutablePointer<T> = UnsafeMutablePointer<T>.alloc(Int(dataCount))
			if noErr == AudioObjectGetPropertyData(target, &property, 0, nil, &dataSize, buffer) {
				result = Array<T>(UnsafeBufferPointer<T>(start: UnsafePointer<T>(buffer), count: Int(dataCount)))
			}
			buffer.dealloc(Int(dataCount))
		}
		return result
	}
	private class func get<T> (let target: AudioObjectID, let property: AudioObjectPropertyAddress ) -> T? {
		return get(target, property: property).first
	}
	private class func set<T> (let target: AudioObjectID, var property: AudioObjectPropertyAddress, var value: T ) {
		AudioObjectSetPropertyData(target, &property, 0, nil, UInt32(sizeofValue(T)), &value)
	}
	private class func set<T> (let target: AudioObjectID, var property: AudioObjectPropertyAddress, var value: [T] ) {
		AudioObjectSetPropertyData(target, &property, 0, nil, UInt32(sizeofValue(T)), &value)
	}
	public class var found: [CoreAudioDevice] {
		let devices: [AudioDeviceID] = get(AudioDeviceID(kAudioObjectSystemObject), property: AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: scope, mElement: element))
		return devices.map{CoreAudioDevice(device: $0)}
	}
	
}
