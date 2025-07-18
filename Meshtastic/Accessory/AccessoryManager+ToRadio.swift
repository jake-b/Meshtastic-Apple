//
//  AccessoryManager+ToRadio.swift
//  Meshtastic
//
//  Created by Jake Bordens on 7/18/25.
//

import Foundation
import MeshtasticProtobufs
import OSLog

extension AccessoryManager {

	public func getCannedMessageModuleMessages(destNum: Int64, wantResponse: Bool) async throws {
		guard let deviceNum = self.activeConnection?.device.num else {
			Logger.services.error("Error while sending CannedMessageModule request.  No active device.")
			throw AccessoryError.ioFailed("No active device")
		}

		var adminPacket = AdminMessage()
		adminPacket.getCannedMessageModuleMessagesRequest = true

		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(destNum)
		meshPacket.from	= UInt32(deviceNum)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		meshPacket.decoded.wantResponse = wantResponse

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("Error serializing admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = wantResponse

		meshPacket.decoded = dataMessage

		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket

		try await self.send(data: toRadio)
		let logString = String.localizedStringWithFormat("Requested Canned Messages Module Messages for node: %@".localized, String(deviceNum))
		Logger.mesh.info("🥫 \(logString, privacy: .public)")
	}

	public func saveTimeZone(config: Config.DeviceConfig, user: Int64) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setConfig.device = config
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(user)
		meshPacket.from	= UInt32(user)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			return 0
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage

		let messageDescription = "⌚ Device Config timezone was empty set timezone to \(config.tzdef)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		return Int64(meshPacket.id)
	}

	// Send an admin message to a radio, save a message to core data for logging
	private func sendAdminMessageToRadio(meshPacket: MeshPacket, adminDescription: String) async throws {

		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket

		try await self.send(data: toRadio)

		Logger.mesh.debug("\(adminDescription, privacy: .public)")
	}

}
