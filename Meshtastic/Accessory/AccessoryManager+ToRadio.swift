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

		let logString = String.localizedStringWithFormat("Requested Canned Messages Module Messages for node: %@".localized, String(deviceNum))
		try await send(data: toRadio, debugDescription: logString)
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
	private func sendAdminMessageToRadio(meshPacket: MeshPacket, adminDescription: String?) async throws {

		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket

		try await send(data: toRadio)
		if let adminDescription {
			Logger.mesh.debug("\(adminDescription, privacy: .public)")
		}
	}

	public func addContactFromURL(base64UrlString: String) async throws {
		guard let deviceNum = self.activeConnection?.device.num else {
			Logger.services.error("Error while sending CannedMessageModule request.  No active device.")
			throw AccessoryError.ioFailed("No active device")
		}

		let decodedString = base64UrlString.base64urlToBase64()
		if let decodedData = Data(base64Encoded: decodedString) {
			do {
				let contact: SharedContact = try SharedContact(serializedBytes: decodedData)
				var adminPacket = AdminMessage()
				adminPacket.addContact = contact
				var meshPacket: MeshPacket = MeshPacket()
				meshPacket.to = UInt32(deviceNum)
				meshPacket.from	= UInt32(deviceNum)
				meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
				meshPacket.priority =  MeshPacket.Priority.reliable
				meshPacket.wantAck = true
				meshPacket.channel = 0
				var dataMessage = DataMessage()
				guard let adminData: Data = try? adminPacket.serializedData() else {
					throw AccessoryError.ioFailed("addContactFromURL: Unable to serialize admin packet")
				}
				dataMessage.payload = adminData
				dataMessage.portnum = PortNum.adminApp
				meshPacket.decoded = dataMessage
				var toRadio: ToRadio!
				toRadio = ToRadio()
				toRadio.packet = meshPacket

				let logString = String.localizedStringWithFormat("Added contact %@ to device".localized, contact.user.longName)
				try await send(data: toRadio, debugDescription: logString)

				// Create a NodeInfo (User) packet for the newly added contact
				var dataNodeMessage = DataMessage()
				if let nodeInfoData = try? contact.user.serializedData() {
					dataNodeMessage.payload = nodeInfoData
					dataNodeMessage.portnum = PortNum.nodeinfoApp
					var nodeMeshPacket = MeshPacket()
					nodeMeshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
					nodeMeshPacket.to = UInt32.max
					nodeMeshPacket.from = UInt32(contact.nodeNum)
					nodeMeshPacket.decoded = dataNodeMessage
					// Update local database with the new node info
					Task { @MainActor in
						upsertNodeInfoPacket(packet: nodeMeshPacket, context: context)
					}
				}

				// Refresh the config from the node, in a background task
				Task {
					await sendWantConfig()
				}

			} catch {
				Logger.data.error("Failed to decode contact data: \(error.localizedDescription, privacy: .public)")
				throw AccessoryError.appError("Unable to decode contact data from QR code.")
			}
		}
	}

	public func sendShutdown(fromUser: UserEntity, toUser: UserEntity) async throws {
		var adminPacket = AdminMessage()
		adminPacket.shutdownSeconds = 5
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		if let serializedData: Data = try? adminPacket.serializedData() {
			dataMessage.payload = serializedData
			dataMessage.portnum = PortNum.adminApp
			meshPacket.decoded = dataMessage
		} else {
			throw AccessoryError.ioFailed("sendShutdown: Unable to serialize admin packet")
		}
		let messageDescription = "🚀 Sent Shutdown Admin Message to: \(toUser.longName ?? "Unknown".localized) from: \(fromUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func sendReboot(fromUser: UserEntity, toUser: UserEntity) async throws {
		var adminPacket = AdminMessage()
		adminPacket.rebootSeconds = 5
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		if let serializedData: Data = try? adminPacket.serializedData() {
			dataMessage.payload = serializedData
			dataMessage.portnum = PortNum.adminApp
			meshPacket.decoded = dataMessage
		} else {
			throw AccessoryError.ioFailed("sendReboot: Unable to serialize Admin packet")
		}
		let messageDescription = "🚀 Sent Reboot Admin Message to: \(toUser.longName ?? "Unknown".localized) from: \(fromUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func sendMessage(message: String, toUserNum: Int64, channel: Int32, isEmoji: Bool, replyID: Int64) async throws {
		guard let fromUserNum = self.activeConnection?.device.num else {
			Logger.services.error("Error while sending CannedMessageModule request.  No active device.")
			throw AccessoryError.ioFailed("No active device")
		}

		guard message.count > 0 else {
			// Don't send an empty message
			Logger.mesh.info("🚫 Don't Send an Empty Message")
			return
		}

		Task { @MainActor in
			let messageUsers = UserEntity.fetchRequest()
			messageUsers.predicate = NSPredicate(format: "num IN %@", [fromUserNum, Int64(toUserNum)])

			do {
				let fetchedUsers = try context.fetch(messageUsers)
				if fetchedUsers.isEmpty {

					Logger.data.error("🚫 Message Users Not Found, Fail")
					throw AccessoryError.ioFailed("🚫 Message Users Not Found, Fail")
				} else if fetchedUsers.count >= 1 {
					let newMessage = MessageEntity(context: context)
					newMessage.messageId = Int64(UInt32.random(in: UInt32(UInt8.max)..<UInt32.max))
					newMessage.messageTimestamp =  Int32(Date().timeIntervalSince1970)
					newMessage.receivedACK = false
					newMessage.read = true
					if toUserNum > 0 {
						newMessage.toUser = fetchedUsers.first(where: { $0.num == toUserNum })
						newMessage.toUser?.lastMessage = Date()
						if newMessage.toUser?.pkiEncrypted ?? false {
							newMessage.publicKey = newMessage.toUser?.publicKey
							newMessage.pkiEncrypted = true
						}
					}
					newMessage.fromUser = fetchedUsers.first(where: { $0.num == fromUserNum })
					newMessage.isEmoji = isEmoji
					newMessage.admin = false
					newMessage.channel = channel
					if replyID > 0 {
						newMessage.replyID = replyID
					}
					newMessage.messagePayload = message
					newMessage.messagePayloadMarkdown = generateMessageMarkdown(message: message)
					newMessage.read = true

					let dataType = PortNum.textMessageApp
					var messageQuotesReplaced = message.replacingOccurrences(of: "’", with: "'")
					messageQuotesReplaced = message.replacingOccurrences(of: "”", with: "\"")
					let payloadData: Data = messageQuotesReplaced.data(using: String.Encoding.utf8)!

					var dataMessage = DataMessage()
					dataMessage.payload = payloadData
					dataMessage.portnum = dataType

					var meshPacket = MeshPacket()
					if newMessage.toUser?.pkiEncrypted ?? false {
						meshPacket.pkiEncrypted = true
						meshPacket.publicKey = newMessage.toUser?.publicKey ?? Data()
						// Auto Favorite nodes you DM so they don't roll out of the nodedb
						if !(newMessage.toUser?.userNode?.favorite ?? true) {
							newMessage.toUser?.userNode?.favorite = true
							do {
								try context.save()
								Logger.data.info("💾 Auto favorited node based on sending a message \(self.activeDeviceNum?.toHex() ?? "0", privacy: .public) to \(toUserNum.toHex(), privacy: .public)")

								guard let userNode = newMessage.toUser?.userNode else {
									Logger.data.warning("⚠️ Unable to set favorite node: userNode is nil.")
									return
								}
								Task {
									do {
										try await self.setFavoriteNode(node: userNode, connectedNodeNum: fromUserNum)
									} catch {
										Logger.data.warning("⚠️ Unable to set favorite node: userNode is nil.")
										return
									}
								}
							} catch {
								context.rollback()
								let nsError = error as NSError
								Logger.data.error("Unresolved Core Data error when auto favoriting in Send Message Function. Error: \(nsError, privacy: .public)")
							}
						}
					}
					meshPacket.id = UInt32(newMessage.messageId)
					if toUserNum > 0 {
						meshPacket.to = UInt32(toUserNum)
					} else {
						meshPacket.to = Constants.maximumNodeNum
					}
					meshPacket.channel = UInt32(channel)
					meshPacket.from	= UInt32(fromUserNum)
					meshPacket.decoded = dataMessage
					meshPacket.decoded.emoji = isEmoji ? 1 : 0
					if replyID > 0 {
						meshPacket.decoded.replyID = UInt32(replyID)
					}
					meshPacket.wantAck = true

					var toRadio: ToRadio!
					toRadio = ToRadio()
					toRadio.packet = meshPacket
					Task {
						let logString = String.localizedStringWithFormat("Sent message %@ from %@ to %@".localized, String(newMessage.messageId), fromUserNum.toHex(), toUserNum.toHex())
						try await send(data: toRadio, debugDescription: logString)
					}
					do {
						try context.save()
						Logger.data.info("💾 Saved a new sent message from \(self.activeDeviceNum?.toHex() ?? "0", privacy: .public) to \(toUserNum.toHex(), privacy: .public)")

					} catch {
						context.rollback()
						let nsError = error as NSError
						Logger.data.error("Unresolved Core Data error in Send Message Function your database is corrupted running a node db reset should clean up the data. Error: \(nsError, privacy: .public)")
						throw error
					}
				}
			} catch {
				Logger.data.error("💥 Send message failure \(self.activeDeviceNum?.toHex() ?? "0", privacy: .public) to \(toUserNum.toHex(), privacy: .public)")
			}
		}
	}

	public func setFavoriteNode(node: NodeInfoEntity, connectedNodeNum: Int64) async throws {
		var adminPacket = AdminMessage()
		adminPacket.setFavoriteNode = UInt32(node.num)
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(connectedNodeNum)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("setFavoriteNode: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage
		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket

		let logString = String.localizedStringWithFormat("Set node %@ as favorite on %@".localized, node.num.toHex(), connectedNodeNum.toHex())
		try await send(data: toRadio, debugDescription: logString)
	}

	public func removeFavoriteNode(node: NodeInfoEntity, connectedNodeNum: Int64) async throws {
		var adminPacket = AdminMessage()
		adminPacket.removeFavoriteNode = UInt32(node.num)
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(connectedNodeNum)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("removeFavoriteNode: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage
		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket

		let logString = String.localizedStringWithFormat("Remove node %@ as favorite on %@".localized, node.num.toHex(), connectedNodeNum.toHex())
		try await send(data: toRadio)
	}

	public func saveChannelSet(base64UrlString: String, addChannels: Bool = false, okToMQTT: Bool = false) async throws {
		guard let deviceNum = self.activeConnection?.device.num else {
			Logger.services.error("Error while sending saveChannelSet request.  No active device.")
			throw AccessoryError.ioFailed("No active device")
		}
		var i: Int32 = 0
		var myInfo: MyInfoEntity
		// Before we get started delete the existing channels from the myNodeInfo
		if !addChannels {
			tryClearExistingChannels()
		}

		let decodedString = base64UrlString.base64urlToBase64()
		if let decodedData = Data(base64Encoded: decodedString) {
			let channelSet: ChannelSet = try ChannelSet(serializedBytes: decodedData)
			for cs in channelSet.settings {
				if addChannels {
					// We are trying to add a channel so lets get the last index
					let fetchMyInfoRequest = MyInfoEntity.fetchRequest()
					fetchMyInfoRequest.predicate = NSPredicate(format: "myNodeNum == %lld", Int64(deviceNum))
					do {
						let fetchedMyInfo = try context.fetch(fetchMyInfoRequest)
						if fetchedMyInfo.count == 1 {
							i = Int32(fetchedMyInfo[0].channels?.count ?? -1)
							myInfo = fetchedMyInfo[0]
							// Bail out if the index is negative or bigger than our max of 8
							if i < 0 || i > 8 {
								throw AccessoryError.appError("Index out of range \(i)")
							}
							// Bail out if there are no channels or if the same channel name already exists
							guard let mutableChannels = myInfo.channels!.mutableCopy() as? NSMutableOrderedSet else {
								throw AccessoryError.appError("No channels or channel")
							}
							if mutableChannels.first(where: {($0 as AnyObject).name == cs.name }) is ChannelEntity {
								throw AccessoryError.appError("Channel already exists")
							}
						}
					} catch {
						Logger.data.error("Failed to find a node MyInfo to save these channels to: \(error.localizedDescription, privacy: .public)")
					}
				}

				var chan = Channel()
				if i == 0 {
					chan.role = Channel.Role.primary
				} else {
					chan.role = Channel.Role.secondary
				}
				chan.settings = cs
				chan.index = i
				i += 1

				var adminPacket = AdminMessage()
				adminPacket.setChannel = chan
				var meshPacket: MeshPacket = MeshPacket()
				meshPacket.to = UInt32(deviceNum)
				meshPacket.from	= UInt32(deviceNum)
				meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
				meshPacket.priority =  MeshPacket.Priority.reliable
				meshPacket.wantAck = true
				meshPacket.channel = 0
				guard let adminData: Data = try? adminPacket.serializedData() else {
					throw AccessoryError.ioFailed("saveChannelSet: Unable to serialize Admin packet")
				}
				var dataMessage = DataMessage()
				dataMessage.payload = adminData
				dataMessage.portnum = PortNum.adminApp
				meshPacket.decoded = dataMessage
				var toRadio: ToRadio!
				toRadio = ToRadio()
				toRadio.packet = meshPacket
				let logString = String.localizedStringWithFormat("Sent a Channel for: %@ Channel Index %d".localized, String(deviceNum), chan.index)
				try await send(data: toRadio, debugDescription: logString)
			}

			// Save the LoRa Config and the device will reboot
			var adminPacket = AdminMessage()
			adminPacket.setConfig.lora = channelSet.loraConfig
			adminPacket.setConfig.lora.configOkToMqtt = okToMQTT // Preserve users okToMQTT choice
			var meshPacket: MeshPacket = MeshPacket()
			meshPacket.to = UInt32(deviceNum)
			meshPacket.from	= UInt32(deviceNum)
			meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
			meshPacket.priority =  MeshPacket.Priority.reliable
			meshPacket.wantAck = true
			meshPacket.channel = 0
			var dataMessage = DataMessage()
			guard let adminData: Data = try? adminPacket.serializedData() else {
				throw AccessoryError.ioFailed("sendReboot: Unable to serialize Admin packet")
			}
			dataMessage.payload = adminData
			dataMessage.portnum = PortNum.adminApp
			meshPacket.decoded = dataMessage
			var toRadio: ToRadio!
			toRadio = ToRadio()
			toRadio.packet = meshPacket

			let logString = String.localizedStringWithFormat("Sent a LoRa.Config for: %@".localized, String(deviceNum))
			try await send(data: toRadio, debugDescription: logString)

			await sendWantConfig()
		}
	}

	public func saveChannel(channel: Channel, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {
		var adminPacket = AdminMessage()
		adminPacket.setChannel = channel
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveChannel: Unable to serialize Admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = true
		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved Channel \(channel.index) for \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		return Int64(meshPacket.id)
	}

	public func sendWaypoint(waypoint: Waypoint) async throws {
		guard let deviceNum = self.activeConnection?.device.num else {
			Logger.services.error("Error while sending sendWaypoint request.  No active device.")
			throw AccessoryError.ioFailed("No active device")
		}

		if waypoint.latitudeI == 0 && waypoint.longitudeI == 0 {
			throw AccessoryError.appError("sendWaypoint: Waypoint coordinates are invalid")
		}

		let fromNodeNum = UInt32(deviceNum)
		var meshPacket = MeshPacket()
		meshPacket.to = Constants.maximumNodeNum
		meshPacket.from	= fromNodeNum
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		do {
			dataMessage.payload = try waypoint.serializedData()
		} catch {
			throw AccessoryError.ioFailed("sendWaypoint: Unable to serialize data packet")
		}

		dataMessage.portnum = PortNum.waypointApp
		meshPacket.decoded = dataMessage
		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket

		let logString = String.localizedStringWithFormat("Sent a Waypoint Packet from: %@".localized, String(fromNodeNum))
		try await send(data: toRadio, debugDescription: logString)
		Logger.mesh.info("📍 \(logString, privacy: .public)")

		Task { @MainActor in
			let wayPointEntity = getWaypoint(id: Int64(waypoint.id), context: context)
			wayPointEntity.id = Int64(waypoint.id)
			wayPointEntity.name = waypoint.name.count >= 1 ? waypoint.name : "Dropped Pin"
			wayPointEntity.longDescription = waypoint.description_p
			wayPointEntity.icon	= Int64(waypoint.icon)
			wayPointEntity.latitudeI = waypoint.latitudeI
			wayPointEntity.longitudeI = waypoint.longitudeI
			if waypoint.expire > 1 {
				wayPointEntity.expire = Date.init(timeIntervalSince1970: Double(waypoint.expire))
			} else {
				wayPointEntity.expire = nil
			}
			if waypoint.lockedTo > 0 {
				wayPointEntity.locked = Int64(waypoint.lockedTo)
			} else {
				wayPointEntity.locked = 0
			}
			if wayPointEntity.created == nil {
				wayPointEntity.created = Date()
			} else {
				wayPointEntity.lastUpdated = Date()
			}
			do {
				try context.save()
				Logger.data.info("💾 Updated Waypoint from Waypoint App Packet From: \(fromNodeNum.toHex(), privacy: .public)")
			} catch {
				context.rollback()
				let nsError = error as NSError
				Logger.data.error("Error Saving NodeInfoEntity from WAYPOINT_APP \(nsError, privacy: .public)")
			}
		}
	}

	func sendTraceRouteRequest(destNum: Int64, wantResponse: Bool) async throws {
		guard let fromNodeNum = self.activeConnection?.device.num else {
			Logger.services.error("Error while sending traceroute request.  No active device.")
			throw AccessoryError.ioFailed("No active device")
		}

		let routePacket = RouteDiscovery()
		var meshPacket = MeshPacket()
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.to = UInt32(destNum)
		meshPacket.from	= UInt32(fromNodeNum)
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		if let serializedData: Data = try? routePacket.serializedData() {
			dataMessage.payload = serializedData
			dataMessage.portnum = PortNum.tracerouteApp
			dataMessage.wantResponse = true
			meshPacket.decoded = dataMessage
		} else {
			throw AccessoryError.ioFailed("sendTraceRouteRequest: Unable to serialize data packet")
		}
		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket

		let logString = String.localizedStringWithFormat("Sent a TraceRoute Packet from: %@ to: %@".localized, String(fromNodeNum), String(destNum))
		try await send(data: toRadio, debugDescription: logString)

		Task { @MainActor in
			let traceRoute = TraceRouteEntity(context: context)
			let nodes = NodeInfoEntity.fetchRequest()
			// TODO: Not sure what's going on here. We always have a fromNodeNum
			// if let connectedNum = fromNodeNum {
			nodes.predicate = NSPredicate(format: "num IN %@", [destNum, fromNodeNum])
			// } else {
			//	nodes.predicate = NSPredicate(format: "num == %@", destNum)
			// }
			do {
				let fetchedNodes = try context.fetch(nodes)
				let receivingNode = fetchedNodes.first(where: { $0.num == destNum })
				traceRoute.id = Int64(meshPacket.id)
				traceRoute.time = Date()
				traceRoute.node = receivingNode
				do {
					try context.save()
					Logger.data.info("💾 Saved TraceRoute sent to node: \(String(receivingNode?.user?.longName ?? "Unknown".localized), privacy: .public)")
				} catch {
					context.rollback()
					let nsError = error as NSError
					Logger.data.error("Error Updating Core Data BluetoothConfigEntity: \(nsError, privacy: .public)")
				}

				let logString = String.localizedStringWithFormat("Sent a Trace Route Request to node: %@".localized, destNum.toHex())
				Logger.mesh.info("🪧 \(logString, privacy: .public)")

			} catch {

			}
		}
	}

	public func requestStoreAndForwardClientHistory(fromUser: UserEntity, toUser: UserEntity) async throws {

		/// send a request for ClientHistory with a time period matching the heartbeat
		var sfPacket = StoreAndForward()
		sfPacket.rr = StoreAndForward.RequestResponse.clientHistory
		sfPacket.history.window = UInt32(toUser.userNode?.storeForwardConfig?.historyReturnWindow ?? 120)
		sfPacket.history.lastRequest = UInt32(toUser.userNode?.storeForwardConfig?.lastRequest ?? 0)
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let sfData: Data = try? sfPacket.serializedData() else {
			throw AccessoryError.ioFailed("requestStoreAndForwardClientHistory: Unable to serialize data packet")

		}
		dataMessage.payload = sfData
		dataMessage.portnum = PortNum.storeForwardApp
		dataMessage.wantResponse = true
		meshPacket.decoded = dataMessage

		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket
		let logString = String.localizedStringWithFormat("📮 Sent a request for a Store & Forward Client History to \(toUser.num.toHex()) for the last \(120) minutes.")
		try await send(data: toRadio, debugDescription: logString)
	}

	public func setIgnoredNode(node: NodeInfoEntity, connectedNodeNum: Int64) async throws {
		var adminPacket = AdminMessage()
		adminPacket.setIgnoredNode = UInt32(node.num)
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(connectedNodeNum)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("setIgnoredNode: Unable to serialize data packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage
		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket

		let logString = String.localizedStringWithFormat("📮 Sent a request to  ignore \(node.num.toHex())")
		try await send(data: toRadio, debugDescription: logString)
	}

	public func removeIgnoredNode(node: NodeInfoEntity, connectedNodeNum: Int64) async throws {
		var adminPacket = AdminMessage()
		adminPacket.removeIgnoredNode = UInt32(node.num)
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(connectedNodeNum)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("removeIgnoredNode: Unable to serialize data packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage
		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket

		let logString = String.localizedStringWithFormat("📮 Sent a request to un-ignore \(node.num.toHex())")
		try await send(data: toRadio, debugDescription: logString)
	}

	public func removeNode(node: NodeInfoEntity, connectedNodeNum: Int64) async throws {
		var adminPacket = AdminMessage()
		adminPacket.removeByNodenum = UInt32(node.num)
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(connectedNodeNum)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		if let serializedData: Data = try? adminPacket.serializedData() {
			dataMessage.payload = serializedData
			dataMessage.portnum = PortNum.adminApp
			meshPacket.decoded = dataMessage
		} else {
			throw AccessoryError.ioFailed("removeNode: Unable to serialize data packet")
		}
		var toRadio: ToRadio!
		toRadio = ToRadio()
		toRadio.packet = meshPacket

		let logString = String.localizedStringWithFormat("🗑️ Sent a request to remove node \(node.num.toHex())")
		try await send(data: toRadio, debugDescription: logString)

		Task { @MainActor in
			do {
				context.delete(node.user!)
				context.delete(node)
				try context.save()
				return true
			} catch {
				context.rollback()
				let nsError = error as NSError
				Logger.data.error("🚫 Error deleting node from core data: \(nsError, privacy: .public)")
			}
		}
	}

	func requestDeviceMetadata(fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		guard isConnected else {
			throw AccessoryError.ioFailed("No connected accessory")
		}

		var adminPacket = AdminMessage()
		adminPacket.getDeviceMetadataRequest = true
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		if let serializedData: Data = try? adminPacket.serializedData() {
			dataMessage.payload = serializedData
			dataMessage.portnum = PortNum.adminApp
			dataMessage.wantResponse = true
			meshPacket.decoded = dataMessage
		} else {
			throw AccessoryError.ioFailed("removeNode: Unable to serialize admin packet")
		}

		let messageDescription = "🛎️ [Device Metadata] Requested for node \(toUser.longName ?? "Unknown".localized) by \(fromUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		return Int64(meshPacket.id)
	}

	public func saveAmbientLightingModuleConfig(config: ModuleConfig.AmbientLightingConfig, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setModuleConfig.ambientLighting = config
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveAmbientLightingModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved Ambient Lighting Module Config for \(toUser.longName ?? "Unknown".localized)"

		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)

		Task { @MainActor in
			upsertAmbientLightingModuleConfigPacket(config: config, nodeNum: toUser.num, context: context)
		}
		return Int64(meshPacket.id)

	}

	public func requestAmbientLightingConfig(fromUser: UserEntity, toUser: UserEntity) async throws {

		var adminPacket = AdminMessage()
		adminPacket.getModuleConfigRequest = AdminMessage.ModuleConfigType.ambientlightingConfig
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("requestAmbientLightingConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = true

		meshPacket.decoded = dataMessage

		let messageDescription = "🛎️ Requested Ambient Lighting Config using an admin key for node: \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func saveCannedMessageModuleConfig(config: ModuleConfig.CannedMessageConfig, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setModuleConfig.cannedMessage = config
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveCannedMessageModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved Canned Message Module Config for \(toUser.longName ?? "Unknown".localized)"

		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		Task { @MainActor in
			upsertCannedMessagesModuleConfigPacket(config: config, nodeNum: toUser.num, context: context)
		}
		return Int64(meshPacket.id)
	}

	public func saveCannedMessageModuleMessages(messages: String, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setCannedMessageModuleMessages = messages
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveCannedMessageModuleMessages: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = true
		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved Canned Message Module Messages for \(toUser.longName ?? "Unknown".localized)"

		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		return Int64(meshPacket.id)
	}

	public func requestCannedMessagesModuleConfig(fromUser: UserEntity, toUser: UserEntity) async throws {

		var adminPacket = AdminMessage()
		adminPacket.getModuleConfigRequest = AdminMessage.ModuleConfigType.cannedmsgConfig
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("requestCannedMessagesModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = true

		meshPacket.decoded = dataMessage

		let messageDescription = "🛎️ Requested Canned Messages Module Config using an admin key for node: \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func saveDetectionSensorModuleConfig(config: ModuleConfig.DetectionSensorConfig, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setModuleConfig.detectionSensor = config
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveDetectionSensorModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved Detection Sensor Module Config for \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		Task {@MainActor in
			upsertDetectionSensorModuleConfigPacket(config: config, nodeNum: toUser.num, context: context)
		}
		return Int64(meshPacket.id)
	}

	public func requestDetectionSensorModuleConfig(fromUser: UserEntity, toUser: UserEntity) async throws {

		var adminPacket = AdminMessage()
		adminPacket.getModuleConfigRequest = AdminMessage.ModuleConfigType.detectionsensorConfig
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("requestDetectionSensorModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = true

		meshPacket.decoded = dataMessage

		let messageDescription = "🛎️ Requested Detection Sensor Module Config using an admin key for node: \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func saveExternalNotificationModuleConfig(config: ModuleConfig.ExternalNotificationConfig, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {
		var adminPacket = AdminMessage()
		adminPacket.setModuleConfig.externalNotification = config
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveExternalNotificationModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved External Notification Module Config for \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		Task { @MainActor in
			upsertExternalNotificationModuleConfigPacket(config: config, nodeNum: toUser.num, context: context)
		}
		return Int64(meshPacket.id)
	}

	public func savePaxcounterModuleConfig(config: ModuleConfig.PaxcounterConfig, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setModuleConfig.paxcounter = config
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("savePaxcounterModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved PAX Counter Module Config for \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		Task { @MainActor in
			upsertPaxCounterModuleConfigPacket(config: config, nodeNum: toUser.num, context: context)
		}
		return Int64(meshPacket.id)
	}

	public func saveRtttlConfig(ringtone: String, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setRingtoneMessage = ringtone
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveRtttlConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved RTTTL Ringtone Config for \(toUser.longName ?? "Unknown".localized)"

		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		Task { @MainActor in
			upsertRtttlConfigPacket(ringtone: ringtone, nodeNum: toUser.num, context: context)
		}
		return Int64(meshPacket.id)
	}

	public func saveMQTTConfig(config: ModuleConfig.MQTTConfig, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setModuleConfig.mqtt = config
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveMQTTConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp

		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved MQTT Config for \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		Task { @MainActor in
			upsertMqttModuleConfigPacket(config: config, nodeNum: toUser.num, context: context)
		}
		return Int64(meshPacket.id)
	}

	public func saveRangeTestModuleConfig(config: ModuleConfig.RangeTestConfig, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setModuleConfig.rangeTest = config
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveRangeTestModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved Range Test Module Config for \(toUser.longName ?? "Unknown".localized)"

		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		Task { @MainActor in
			upsertRangeTestModuleConfigPacket(config: config, nodeNum: toUser.num, context: context)
		}
		return Int64(meshPacket.id)
	}

	public func saveSerialModuleConfig(config: ModuleConfig.SerialConfig, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setModuleConfig.serial = config
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveSerialModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved Serial Module Config for \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		Task { @MainActor in
			upsertSerialModuleConfigPacket(config: config, nodeNum: toUser.num, context: context)
		}
		return Int64(meshPacket.id)
	}

	public func requestExternalNotificationModuleConfig(fromUser: UserEntity, toUser: UserEntity) async throws {

		var adminPacket = AdminMessage()
		adminPacket.getModuleConfigRequest = AdminMessage.ModuleConfigType.extnotifConfig
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("requestExternalNotificationModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = true

		meshPacket.decoded = dataMessage

		let messageDescription = "🛎️ Requested External Notificaiton Module Config using an admin key for node: \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func requestPaxCounterModuleConfig(fromUser: UserEntity, toUser: UserEntity) async throws {
		var adminPacket = AdminMessage()
		adminPacket.getModuleConfigRequest = AdminMessage.ModuleConfigType.paxcounterConfig
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("requestPaxCounterModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = true

		meshPacket.decoded = dataMessage

		let messageDescription = "🛎️ Requested PAX Counter Module Config using an admin key for node: \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func requestRtttlConfig(fromUser: UserEntity, toUser: UserEntity) async throws -> Bool {

		var adminPacket = AdminMessage()
		adminPacket.getRingtoneRequest = true
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("requestRtttlConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = true

		meshPacket.decoded = dataMessage

		let messageDescription = "🛎️ Requested RTTTL Ringtone Config using an admin key for node: \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func requestRangeTestModuleConfig(fromUser: UserEntity, toUser: UserEntity) async throws -> Bool {

		var adminPacket = AdminMessage()
		adminPacket.getModuleConfigRequest = AdminMessage.ModuleConfigType.rangetestConfig
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("requestRangeTestModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = true

		meshPacket.decoded = dataMessage

		let messageDescription = "🛎️ Requested Range Test Module Config using an admin key for node: \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func requestMqttModuleConfig(fromUser: UserEntity, toUser: UserEntity) async throws {

		var adminPacket = AdminMessage()
		adminPacket.getModuleConfigRequest = AdminMessage.ModuleConfigType.mqttConfig
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("requestMqttModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = true

		meshPacket.decoded = dataMessage

		let messageDescription = "🛎️ Requested MQTT Module Config using an admin key for node: \(String(activeDeviceNum ?? 0))"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func requestSerialModuleConfig(fromUser: UserEntity, toUser: UserEntity) async throws {

		var adminPacket = AdminMessage()
		adminPacket.getModuleConfigRequest = AdminMessage.ModuleConfigType.serialConfig
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("requestSerialModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = true

		meshPacket.decoded = dataMessage

		let messageDescription = "🛎️ Requested Serial Module Config using an admin key for node: \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func saveStoreForwardModuleConfig(config: ModuleConfig.StoreForwardConfig, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setModuleConfig.storeForward = config
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveStoreForwardModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved Store & Forward Module Config for \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		Task { @MainActor in
			upsertStoreForwardModuleConfigPacket(config: config, nodeNum: toUser.num, context: context)
		}
		return Int64(meshPacket.id)
	}

	public func requestStoreAndForwardModuleConfig(fromUser: UserEntity, toUser: UserEntity) async throws {

		var adminPacket = AdminMessage()
		adminPacket.getModuleConfigRequest = AdminMessage.ModuleConfigType.storeforwardConfig
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("requestStoreAndForwardModuleConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = true

		meshPacket.decoded = dataMessage

		let messageDescription = "🛎️ Requested Store and Forward Module Config using an admin key for node: \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)

	}

	public func sendEnterDfuMode(fromUser: UserEntity, toUser: UserEntity) async throws {
		var adminPacket = AdminMessage()
		adminPacket.enterDfuModeRequest = true
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		meshPacket.channel = UInt32(0)
		var dataMessage = DataMessage()
		if let serializedData: Data = try? adminPacket.serializedData() {
			dataMessage.payload = serializedData
			dataMessage.portnum = PortNum.adminApp
			meshPacket.decoded = dataMessage
		} else {
			throw AccessoryError.ioFailed("sendEnterDfuMode: Unable to serialize admin packet")
		}
		// TODO: automatic reconnect
		// automaticallyReconnect = false
		let messageDescription = "🚀 Sent enter DFU mode Admin Message to: \(toUser.longName ?? "Unknown".localized) from: \(fromUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func sendRebootOta(fromUser: UserEntity, toUser: UserEntity) async throws {
		var adminPacket = AdminMessage()
		adminPacket.rebootOtaSeconds = 5
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		if let serializedData: Data = try? adminPacket.serializedData() {
			dataMessage.payload = serializedData
			dataMessage.portnum = PortNum.adminApp
			meshPacket.decoded = dataMessage
		} else {
			throw AccessoryError.ioFailed("sendRebootOta: Unable to serialize admin packet")
		}
		let messageDescription = "🚀 Sent Reboot OTA Admin Message to: \(toUser.longName ?? "Unknown".localized) from: \(fromUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func saveUser(config: User, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {
		var adminPacket = AdminMessage()
		adminPacket.setOwner = config
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		if let serializedData: Data = try? adminPacket.serializedData() {
			dataMessage.payload = serializedData
			dataMessage.portnum = PortNum.adminApp
			meshPacket.decoded = dataMessage
		} else {
			throw AccessoryError.ioFailed("saveUser: Unable to serialize admin packet")
		}
		let messageDescription = "🛟 Saved User Config for \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		return Int64(meshPacket.id)
	}

	public func saveLicensedUser(ham: HamParameters, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {
		var adminPacket = AdminMessage()
		adminPacket.setHamMode = ham
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveLicensedUser: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		meshPacket.decoded = dataMessage
		let messageDescription = "🛟 Saved Ham Parameters for \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		return Int64(meshPacket.id)
	}

	public func sendFactoryReset(fromUser: UserEntity, toUser: UserEntity, resetDevice: Bool = false) async throws {
		var adminPacket = AdminMessage()
		if resetDevice {
			adminPacket.factoryResetDevice = 5
		} else {
			adminPacket.factoryResetConfig = 5
		}
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	=  UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		if let serializedData: Data = try? adminPacket.serializedData() {
			dataMessage.payload = serializedData
			dataMessage.portnum = PortNum.adminApp
			meshPacket.decoded = dataMessage
		} else {
			throw AccessoryError.ioFailed("saveLicensedUser: Unable to serialize admin packet")
		}

		let messageDescription = "🚀 Sent Factory Reset Admin Message to: \(toUser.longName ?? "Unknown".localized) from: \(fromUser.longName ??  "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func setFixedPosition(fromUser: UserEntity, channel: Int32) async throws {
		var adminPacket = AdminMessage()

		guard let positionPacket = try await getPositionFromPhoneGPS(destNum: fromUser.num, fixedPosition: true) else {
			throw AccessoryError.appError("Unable to get position from GPS")
		}

		adminPacket.setFixedPosition = positionPacket
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(fromUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		meshPacket.channel = UInt32(channel)
		var dataMessage = DataMessage()
		meshPacket.decoded = dataMessage
		if let serializedData: Data = try? adminPacket.serializedData() {
			dataMessage.payload = serializedData
			dataMessage.portnum = PortNum.adminApp
			meshPacket.decoded = dataMessage
		} else {
			throw AccessoryError.ioFailed("setFixedPosition: Unable to serialize admin packet")
		}
		let messageDescription = "🚀 Sent Set Fixed Postion Admin Message to: \(fromUser.longName ?? "Unknown".localized) from: \(fromUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func removeFixedPosition(fromUser: UserEntity, channel: Int32) async throws {
		var adminPacket = AdminMessage()
		adminPacket.removeFixedPosition = true
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(fromUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		meshPacket.channel = UInt32(channel)
		var dataMessage = DataMessage()
		if let serializedData: Data = try? adminPacket.serializedData() {
			dataMessage.payload = serializedData
			dataMessage.portnum = PortNum.adminApp
			meshPacket.decoded = dataMessage
		} else {
			throw AccessoryError.ioFailed("setFixedPosition: Unable to serialize admin packet")
		}
		let messageDescription = "🚀 Sent Remove Fixed Position Admin Message to: \(fromUser.longName ?? "Unknown".localized) from: \(fromUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func savePositionConfig(config: Config.PositionConfig, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setConfig.position = config
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("savePositionConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp

		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved Position Config for \(toUser.longName ?? "Unknown".localized)"

		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		Task { @MainActor in
			upsertPositionConfigPacket(config: config, nodeNum: toUser.num, context: context)
		}
		return Int64(meshPacket.id)
	}

	public func requestPositionConfig(fromUser: UserEntity, toUser: UserEntity) async throws {

		var adminPacket = AdminMessage()
		adminPacket.getConfigRequest = AdminMessage.ConfigType.positionConfig
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true

		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("requestPositionConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp
		dataMessage.wantResponse = true

		meshPacket.decoded = dataMessage

		let messageDescription = "🛎️ Requested Position Config using an admin key for node: \(toUser.longName ?? "Unknown".localized)"
		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
	}

	public func savePowerConfig(config: Config.PowerConfig, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setConfig.power = config

		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("savePowerConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp

		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved Power Config for \(toUser.longName ?? "Unknown".localized)"

		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		Task { @MainActor in
			upsertPowerConfigPacket(config: config, nodeNum: toUser.num, context: context)

		}
		return Int64(meshPacket.id)
	}

	public func saveNetworkConfig(config: Config.NetworkConfig, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setConfig.network = config
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveNetworkConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp

		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved Network Config for \(toUser.longName ?? "Unknown".localized)"

		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		Task { @MainActor in
			upsertNetworkConfigPacket(config: config, nodeNum: toUser.num, context: context)
		}
		return Int64(meshPacket.id)
	}

	public func saveSecurityConfig(config: Config.SecurityConfig, fromUser: UserEntity, toUser: UserEntity) async throws -> Int64 {

		var adminPacket = AdminMessage()
		adminPacket.setConfig.security = config
		if fromUser != toUser {
			adminPacket.sessionPasskey = toUser.userNode?.sessionPasskey ?? Data()
		}
		var meshPacket: MeshPacket = MeshPacket()
		meshPacket.to = UInt32(toUser.num)
		meshPacket.from	= UInt32(fromUser.num)
		meshPacket.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
		meshPacket.priority =  MeshPacket.Priority.reliable
		meshPacket.wantAck = true
		var dataMessage = DataMessage()
		guard let adminData: Data = try? adminPacket.serializedData() else {
			throw AccessoryError.ioFailed("saveSecurityConfig: Unable to serialize admin packet")
		}
		dataMessage.payload = adminData
		dataMessage.portnum = PortNum.adminApp

		meshPacket.decoded = dataMessage

		let messageDescription = "🛟 Saved Security Config for \(toUser.longName ?? "Unknown".localized)"

		try await sendAdminMessageToRadio(meshPacket: meshPacket, adminDescription: messageDescription)
		Task { @MainActor in
			upsertSecurityConfigPacket(config: config, nodeNum: toUser.num, context: context)
		}
		return Int64(meshPacket.id)
	}
}
