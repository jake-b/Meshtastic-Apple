//
//  TCPConnection.swift
//  Meshtastic
//
//  Created by Jake Bordens on 7/19/25.
//

import Foundation
import Network
import OSLog
import MeshtasticProtobufs

class TCPConnection: Connection {
	private let connection: NWConnection
	private let queue = DispatchQueue(label: "tcp.connection")
	private var readerTask: Task<Void, Never>?

	weak var packetDelegate: PacketDelegate?

	var isConnected: Bool {
		connection.state == .ready
	}

	init(host: String, port: Int) async throws {
		let nwHost = NWEndpoint.Host(host)
		let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))
		connection = NWConnection(host: nwHost, port: nwPort, using: .tcp)

		try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
			connection.stateUpdateHandler = { state in
				switch state {
				case .ready:
					cont.resume()
				case .failed(let error):
					cont.resume(throwing: error)
				default:
					break
				}
			}
			connection.start(queue: queue)
		}

		startReader()
	}

	private func startReader() {
		readerTask = Task {
			var buffer = Data()
			while isConnected {
				do {
					let data = try await receiveData(min: 1, max: 65535)
					if data.isEmpty {
						break // EOF
					}
					buffer.append(data)

					while buffer.count >= 4 {
						guard buffer[0] == 0x94 && buffer[1] == 0xc3 else {
							Logger.services.error("Bad magic in TCP frame")
							throw AccessoryError.ioFailed("Bad magic in TCP frame")
						}

						let lenData = buffer[2..<4]
						let len = lenData.withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }

						if buffer.count >= Int(len) + 4 {
							let payload = buffer[4..<Int(len) + 4]
							if let fromRadio = try? FromRadio(serializedBytes: payload) {
								packetDelegate?.didReceive(result: .success(fromRadio))
							} else {
								Logger.services.error("Failed to deserialize FromRadio")
							}
							buffer.removeFirst(Int(len) + 4)
						} else {
							break
						}
					}
				} catch {
					Logger.services.error("Error reading from TCP: \(error)")
					packetDelegate?.didReceive(result: .failure(error))
					break
				}
			}
		}
	}

	private func receiveData(min: Int, max: Int) async throws -> Data {
		try await withCheckedThrowingContinuation { cont in
			connection.receive(minimumIncompleteLength: min, maximumLength: max) { content, _, isComplete, error in
				if let error = error {
					cont.resume(throwing: error)
					return
				}
				if isComplete {
					cont.resume(returning: Data())
					return
				}
				cont.resume(returning: content ?? Data())
			}
		}
	}

	func send(_ data: ToRadio) async throws {
		let serialized = try data.serializedData()
		var buffer = Data()
		buffer.append(0x94)
		buffer.append(0x73)
		var len = UInt16(serialized.count).bigEndian
		withUnsafeBytes(of: &len) { buffer.append(contentsOf: $0) }
		buffer.append(serialized)

		try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
			connection.send(content: buffer, completion: .contentProcessed { error in
				if let error = error {
					cont.resume(throwing: error)
				} else {
					cont.resume()
				}
			})
		}
	}

	func disconnect() async throws {
		readerTask?.cancel()
		connection.cancel()
	}

	func drainPendingPackets() async throws {
		// For TCP, since reader is always running, no need to drain separately
	}

	func startDrainPendingPackets() throws {
		// For TCP, reader is already started
	}
}
