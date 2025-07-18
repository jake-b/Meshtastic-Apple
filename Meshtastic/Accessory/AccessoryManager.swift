//
//  AccessoryManager.swift
//  Created by Jake Bordens on 7/10/25.
//

import Foundation
import SwiftUI
import MeshtasticProtobufs
import OSLog
import CocoaMQTT

enum AccessoryError: Error {
	case discoveryFailed(String)
	case connectionFailed(String)
	case ioFailed(String)
	// Transport-specific sub-errors can be nested
}

enum AccessoryManagerState {
	case uninitialized
	case idle
	case discovering
	case connecting
	case retrying(attempt: Int)
	case communicating
	case subscribed
}

class AccessoryManager: ObservableObject, PacketDelegate {
	let NONCE_ONLY_CONFIG = 69420
	let NONCE_ONLY_DB = 69421

	static let shared = AccessoryManager()
	let context = PersistenceController.shared.container.viewContext

	@Published var devices: [Device] = []
	@Published var status: AccessoryManagerState

	private let transports: [any Transport]
	private var activeConnection: (device: Device, connection: any Connection)?
	private var discoveryTask: Task<Void, Never>?
	private var didReadConifg: Bool = false
	private var didReadDatabase: Bool = false

	private var wantConfigContinuations: [UInt32: CheckedContinuation<Void, Error>] = [:]

	init(transports: [any Transport] = [BLETransport()]) {
		self.transports = transports
		self.status = .uninitialized
	}

	func startDiscovery() {
		stopDiscovery()
		status = .discovering
		for transport in transports {
			if var wirelessTransport = transport as? any WirelessTransport {
				wirelessTransport.rssiDelegate = self
			}
		}
		discoveryTask = Task {
			var allDevices: [Device] = []
			for await newDevice in self.discoverAllDevices() {
				// Update existing device or add new
				if let index = allDevices.firstIndex(where: { $0.id == newDevice.id }) {
					let existing = allDevices[index]
					let updatedDevice = Device(id: existing.id,
											   name: newDevice.name,
											   transportType: existing.transportType,
											   identifier: existing.identifier,
											   connectionState: existing.connectionState,
											   rssi: newDevice.rssi)
					allDevices[index] = updatedDevice
				} else {
					allDevices.append(newDevice)
				}
				self.devices = allDevices.sorted { $0.name < $1.name }
			}
		}
	}

	func stopDiscovery() {
		discoveryTask?.cancel()
		status = .idle
		discoveryTask = nil
		for transport in transports {
			if var wirelessTransport = transport as? any WirelessTransport {
				wirelessTransport.rssiDelegate = nil
			}
		}
	}

	private func discoverAllDevices() -> AsyncStream<Device> {
		AsyncStream { continuation in
			let tasks = transports.map { transport in
				Task {
					for await device in transport.discoverDevices() {
						continuation.yield(device)
					}
				}
			}
			continuation.onTermination = { _ in tasks.forEach { $0.cancel() } }
		}
	}

	func connect(to device: Device) async throws {
		// Prevent new connection if one is active
		if activeConnection != nil {
			throw AccessoryError.connectionFailed("Already connected to a device")
		}

		// Update device state to connecting
		Task { @MainActor in
			status = .connecting
			updateDeviceState(deviceId: device.id, state: .connecting)
		}

		self.didReadConifg = false
		self.didReadDatabase = false

		// Find the transport that handles this device
		guard let transport = transports.first(where: { $0.type == device.transportType }) else {
			Task { @MainActor in
				updateDeviceState(deviceId: device.id, state: .disconnected)
			}
			throw AccessoryError.connectionFailed("No transport for type")
		}

		// Prepare to connect, 10 retries, 1 second in between each
		let maxRetries = 10
		let retryDelay: Duration = .seconds(1)

		// Start trying to connect
		var lastError: Error?
		for attempt in 1...maxRetries {
			if attempt > 1 {
				Logger.services.info("Retrying connection to \(device.name) (\(attempt)/\(maxRetries))")
				Task { @MainActor in
					status = .retrying(attempt: attempt)
				}
			} else {
				Task { @MainActor in
					status = .connecting
				}
			}

			do {
				// Ask the transport to connect to the device and return a connection
				var connection = try await transport.connect(to: device)

				// If this is a wireless connection, have it report the RSSI to the AccessoryManager
				if var wirelessConnection = connection as? any WirelessConnection {
					wirelessConnection.rssiDelegate = self
				}

				// Tell the connection to report its packets to the AccessoryManager
				connection.packetDelegate = self

				// We have an active connection
				Task { @MainActor in
					activeConnection = (device: device, connection: connection)
					updateDeviceState(deviceId: device.id, state: .connected)
				}

				await didConnect()

				return
			} catch {
				lastError = error
				if attempt < maxRetries {
					try? await Task.sleep(for: retryDelay)
				}
			}
		}
		updateDeviceState(deviceId: device.id, state: .disconnected)
		throw lastError ?? AccessoryError.connectionFailed("Connection failed after retries")
	}

	private func sendNonceRequest(nonce: UInt32) async throws {
		var toRadio: ToRadio = ToRadio()
		toRadio.wantConfigID = nonce
		try await self.send(data: toRadio)
		Task {
			try await activeConnection?.connection.drainPendingPackets()
		}
		try await withCheckedThrowingContinuation { cont in
			wantConfigContinuations[nonce] = cont
		}
	}

	private func didConnect() async {
		Logger.services.info("✅ [Accessory] Begin Handshake")
		status = .communicating

		// Send Heartbeat before wantConfig
		var heartbeatToRadio: ToRadio = ToRadio()
		heartbeatToRadio.payloadVariant = .heartbeat(Heartbeat())
		try? await self.send(data: heartbeatToRadio)

		try? await sendNonceRequest(nonce: UInt32(NONCE_ONLY_CONFIG))
		Logger.services.info("✅ [Accessory] NONCE_ONLY_CONFIG Done")
		try? await sendNonceRequest(nonce: UInt32(NONCE_ONLY_DB))
		Logger.services.info("✅ [Accessory] NONCE_ONLY_DB Done")
	}

	func didDisconnect() {
		startDiscovery()
	}

	func disconnect() async throws {
		guard let active = activeConnection else {
			return // No connection to disconnect
		}
		activeConnection = nil
		try await active.connection.disconnect()
		updateDeviceState(deviceId: active.device.id, state: .disconnected)
		didDisconnect()
	}

	private func updateDevice<T>(deviceId: UUID, key: WritableKeyPath<Device, T>, value: T) {
		if let index = devices.firstIndex(where: { $0.id == deviceId }) {
			var device = devices[index]
			device[keyPath: key] = value
			devices[index] = device
		} else {
			Logger.services.error("Device with ID \(deviceId) not found in devices list.")
		}
	}
	private func updateDeviceState(deviceId: UUID, state: ConnectionState) {
		if let index = devices.firstIndex(where: { $0.id == deviceId }) {
			let oldDevice = devices[index]
			devices[index] = Device(id: oldDevice.id,
								   name: oldDevice.name,
								   transportType: oldDevice.transportType,
								   identifier: oldDevice.identifier,
								   connectionState: state,
								   rssi: oldDevice.rssi)
		}
	}

	private func updateDeviceRSSI(deviceId: UUID, rssi: Int) {
		if let index = devices.firstIndex(where: { $0.id == deviceId }) {
			let oldDevice = devices[index]
			devices[index] = Device(id: oldDevice.id,
								   name: oldDevice.name,
								   transportType: oldDevice.transportType,
								   identifier: oldDevice.identifier,
								   connectionState: oldDevice.connectionState,
								   rssi: rssi)
		}
	}

	func send(data: ToRadio) async throws {
		Logger.services.info("✅ [Accessory] Sending \(data.debugDescription)")
		guard let active = activeConnection,
			  active.connection.isConnected else {
			throw AccessoryError.connectionFailed("Not connected to any device")
		}
		try await active.connection.send(data)
	}

	func didReceive(result: Result<FromRadio, Error>) {
			Logger.services.info("✅ [Accessory] Received packet")
			switch result {
			case .success(let fromRadio):
				self.processFromRadio(fromRadio)

			case .failure(let error):
				// Handle error, perhaps log and disconnect
				print("Error receiving packet: \(error)")
				// try? await self.disconnect()
			}
		}

	private func processFromRadio(_ decodedInfo: FromRadio) {
		guard let activeDevice = activeConnection?.device else {
			Logger.services.error("No active device to process packet for")
			return
		}

		switch decodedInfo.payloadVariant {
		case .mqttClientProxyMessage(let mqttClientProxyMessage):
			let message = CocoaMQTTMessage(topic: mqttClientProxyMessage.topic,
										 payload: [UInt8](mqttClientProxyMessage.data),
										retained: mqttClientProxyMessage.retained)
			MqttClientProxyManager.shared.mqttClientProxy?.publish(message)

		case .clientNotification(let clientNotification):
			var path = "meshtastic:///settings/debugLogs"
			if clientNotification.hasReplyID {
				/// Set Sent bool on TraceRouteEntity to false if we got rate limited
				if clientNotification.message.starts(with: "TraceRoute") {
					let traceRoute = getTraceRoute(id: Int64(clientNotification.replyID), context: context)
					traceRoute?.sent = false
					do {
						try context.save()
						Logger.data.info("💾 [TraceRouteEntity] Trace Route Rate Limited")
					} catch {
						context.rollback()
						let nsError = error as NSError
						Logger.data.error("💥 [TraceRouteEntity] Error Updating Core Data: \(nsError, privacy: .public)")
					}
				}

				switch clientNotification.payloadVariant {
				case .lowEntropyKey, .duplicatedPublicKey:
					path = "meshtastic:///settings/security"
				default:
					break
				}
			}

			let manager = LocalNotificationManager()
			manager.notifications = [
				Notification(
					id: UUID().uuidString,
					title: "Firmware Notification".localized,
					subtitle: "\(clientNotification.level)".capitalized,
					content: clientNotification.message,
					target: "settings",
					path: path
				)
			]
			manager.schedule()
			Logger.data.error("⚠️ Client Notification: \(clientNotification.message, privacy: .public)")

		default:
			switch decodedInfo.packet.decoded.portnum {
// Handle Any local only packets we get over BLE
			case .unknownApp:
				let haveConnectedPeripheral = self.activeConnection?.device.num != 0
				var nowKnown = false
				if decodedInfo.myInfo.isInitialized && decodedInfo.myInfo.myNodeNum > 0 {
					let myInfo = myInfoPacket(myInfo: decodedInfo.myInfo, peripheralId: activeDevice.id.uuidString, context: context)

					if let myInfo {
						UserDefaults.preferredPeripheralNum = Int(myInfo.myNodeNum)
						updateDevice(deviceId: activeDevice.id, key: \.num, value: myInfo.myNodeNum)
						updateDevice(deviceId: activeDevice.id, key: \.name, value: myInfo.bleName ?? "Unknown".localized)
						updateDevice(deviceId: activeDevice.id, key: \.longName, value: myInfo.bleName ?? "Unknown".localized)
						let newConnection = Int64(UserDefaults.preferredPeripheralNum) != Int64(decodedInfo.myInfo.myNodeNum)
						if newConnection {
							// Onboard a new device connection here
						}
					}
					// TODO: tryClearExistingChannels()
				}

				if decodedInfo.nodeInfo.num > 0 {
					self.didReadDatabase = true
					nowKnown = true
					if let nodeInfo = nodeInfoPacket(nodeInfo: decodedInfo.nodeInfo, channel: decodedInfo.packet.channel, context: context) {
						if activeDevice.num == nodeInfo.num {
							if let user = nodeInfo.user {
								updateDevice(deviceId: activeDevice.id, key: \.shortName, value: user.shortName ?? "?")
								updateDevice(deviceId: activeDevice.id, key: \.longName, value: user.longName ?? "Unknown".localized)
							}
						}
					}
				}

			case .textMessageApp, .detectionSensorApp:
				break
			case .alertApp:
				break
			case .remoteHardwareApp:
				Logger.mesh.info("🕸️ MESH PACKET received for Remote Hardware App UNHANDLED \((try? decodedInfo.packet.jsonString()) ?? "JSON Decode Failure", privacy: .public)")
			case .positionApp:
				upsertPositionPacket(packet: decodedInfo.packet, context: context)
			case .waypointApp:
				waypointPacket(packet: decodedInfo.packet, context: context)
			case .nodeinfoApp:
				// TODO: invalidVersion
				upsertNodeInfoPacket(packet: decodedInfo.packet, context: context)
			case .routingApp:
				// TODO: invalidVersion
				if let connectedNum = activeDevice.num {
					routingPacket(packet: decodedInfo.packet, connectedNodeNum: connectedNum, context: context)
				}
			case .adminApp:
				adminAppPacket(packet: decodedInfo.packet, context: context)
			case .replyApp:
				Logger.mesh.info("🕸️ MESH PACKET received for Reply App handling as a text message")
				// TODO: textMessageAppPacket(packet: decodedInfo.packet, wantRangeTestPackets: wantRangeTestPackets, connectedNode: (self.connectedPeripheral != nil ? connectedPeripheral.num : 0), context: context, appState: appState)
			case .ipTunnelApp:
				Logger.mesh.info("🕸️ MESH PACKET received for IP Tunnel App UNHANDLED UNHANDLED")
			case .serialApp:
				Logger.mesh.info("🕸️ MESH PACKET received for Serial App UNHANDLED UNHANDLED")
			case .storeForwardApp:
				// TODO: storeAndForwardPacket(packet: decodedInfo.packet, connectedNodeNum: (self.connectedPeripheral != nil ? connectedPeripheral.num : 0), context: context)
				break
			case .rangeTestApp:
				// TODO: RangeTest
				break
//				if wantRangeTestPackets {
//					textMessageAppPacket(
//						packet: decodedInfo.packet,
//						wantRangeTestPackets: true,
//						connectedNode: (self.connectedPeripheral != nil ? connectedPeripheral.num : 0),
//						context: context,
//						appState: appState
//					)
//				} else {
//					Logger.mesh.info("🕸️ MESH PACKET received for Range Test App Range testing is disabled.")
//				}
			case .telemetryApp:
				// TODO: Invalid Version?
				telemetryPacket(packet: decodedInfo.packet, connectedNode: activeDevice.num ?? 0, context: context)
			case .textMessageCompressedApp:
				Logger.mesh.info("🕸️ MESH PACKET received for Text Message Compressed App UNHANDLED")
			case .zpsApp:
				Logger.mesh.info("🕸️ MESH PACKET received for Zero Positioning System App UNHANDLED")
			case .privateApp:
				Logger.mesh.info("🕸️ MESH PACKET received for Private App UNHANDLED UNHANDLED")
			case .atakForwarder:
				Logger.mesh.info("🕸️ MESH PACKET received for ATAK Forwarder App UNHANDLED UNHANDLED")
			case .simulatorApp:
				Logger.mesh.info("🕸️ MESH PACKET received for Simulator App UNHANDLED UNHANDLED")
			case .audioApp:
				Logger.mesh.info("🕸️ MESH PACKET received for Audio App UNHANDLED UNHANDLED")
			case .tracerouteApp:
				break
			case .neighborinfoApp:
				if let neighborInfo = try? NeighborInfo(serializedBytes: decodedInfo.packet.decoded.payload) {
					Logger.mesh.info("🕸️ MESH PACKET received for Neighbor Info App UNHANDLED \((try? neighborInfo.jsonString()) ?? "JSON Decode Failure", privacy: .public)")
				}
			case .paxcounterApp:
				paxCounterPacket(packet: decodedInfo.packet, context: context)
			case .mapReportApp:
				Logger.mesh.info("🕸️ MESH PACKET received Map Report App UNHANDLED \((try? decodedInfo.packet.jsonString()) ?? "JSON Decode Failure", privacy: .public)")
			case .UNRECOGNIZED:
				Logger.mesh.info("🕸️ MESH PACKET received UNRECOGNIZED App UNHANDLED \((try? decodedInfo.packet.jsonString()) ?? "JSON Decode Failure", privacy: .public)")
			case .max:
				Logger.services.info("MAX PORT NUM OF 511")
			case .atakPlugin:
				Logger.mesh.info("🕸️ MESH PACKET received for ATAK Plugin App UNHANDLED \((try? decodedInfo.packet.jsonString()) ?? "JSON Decode Failure", privacy: .public)")
			case .powerstressApp:
				Logger.mesh.info("🕸️ MESH PACKET received for Power Stress App UNHANDLED \((try? decodedInfo.packet.jsonString()) ?? "JSON Decode Failure", privacy: .public)")
			case .reticulumTunnelApp:
				Logger.mesh.info("🕸️ MESH PACKET received for Reticulum Tunnel App UNHANDLED \((try? decodedInfo.packet.jsonString()) ?? "JSON Decode Failure", privacy: .public)")
			case .keyVerificationApp:
				Logger.mesh.warning("🕸️ MESH PACKET received for Key Verification App UNHANDLED \((try? decodedInfo.packet.jsonString()) ?? "JSON Decode Failure", privacy: .public)")
			}

			if decodedInfo.configCompleteID != 0 {
				Logger.services.info("✅ [Accessory] Config Complete ID: \(decodedInfo.configCompleteID)")
				if let continuation = wantConfigContinuations[decodedInfo.configCompleteID] {
					wantConfigContinuations.removeValue(forKey: decodedInfo.configCompleteID)
					continuation.resume()
				}
			}

		}
	}
}

extension AccessoryManager: RSSIDelegate {
	func didUpdateRSSI(_ rssi: Int, for deviceId: UUID) {
		updateDeviceRSSI(deviceId: deviceId, rssi: rssi)
	}
}
