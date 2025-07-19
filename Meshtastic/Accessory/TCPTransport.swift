//
//  TCPTransport.swift
//  Meshtastic
//
//  Created by Jake Bordens on 7/19/25.
//

import Foundation
import Network
import OSLog
import MeshtasticProtobufs

let MESHTASTIC_SERVICE_TYPE = "_meshtastic._tcp."
let MESHTASTIC_DOMAIN = "local."

class TCPTransport: NSObject, Transport, NetServiceBrowserDelegate, NetServiceDelegate {
	let type: TransportType = .tcp
	var status: TransportStatus = .uninitialized

	private var browser: NetServiceBrowser?
	private var services: [String: ResolvedService] = [:] // Key: service.name
	private var continuation: AsyncStream<Device>.Continuation?

	struct ResolvedService {
		let service: NetService
		let host: String
		let port: Int
	}

	override init() {
		super.init()
		browser = NetServiceBrowser()
		browser?.delegate = self
	}

	func discoverDevices() -> AsyncStream<Device> {
		AsyncStream { cont in
			self.continuation = cont
			self.status = .discovering
			self.browser?.searchForServices(ofType: MESHTASTIC_SERVICE_TYPE, inDomain: MESHTASTIC_DOMAIN)
			cont.onTermination = { _ in
				self.browser?.stop()
				self.services.removeAll()
				self.continuation = nil
				self.status = .ready
			}
		}
	}

	func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
		service.delegate = self
		service.resolve(withTimeout: 5)
	}

	func netServiceDidResolveAddress(_ service: NetService) {
		guard let host = service.hostName else {
			Logger.services.error("Failed to resolve host for service \(service.name)")
			return
		}
		let port = service.port
		services[service.name] = ResolvedService(service: service, host: host, port: port)

		// Use service.name hash for stable ID
		let idString = String(format: "%llu", UInt64(abs(Int64(service.name.hashValue))))
		let device = Device(id: UUID(),
							name: service.name,
							transportType: .tcp,
							identifier: "\(host):\(port)")
		continuation?.yield(device)
	}

	func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
		Logger.services.error("Failed to resolve service \(sender.name): \(errorDict)")
	}

	func connect(to device: Device) async throws -> any Connection {
		let parts = device.identifier.split(separator: ":")
		guard parts.count == 2, let port = Int(parts[1]) else {
			throw AccessoryError.connectionFailed("Invalid identifier format")
		}
		let host = String(parts[0])
		return try await TCPConnection(host: host, port: port)
	}
}
