//
//  to.swift
//  Meshtastic
//
//  Created by jake on 12/2/25.
//


import Foundation
import NordicDFU
import CoreBluetooth

// A simple enum to track the UI state
enum DFUUpdateState: Equatable {
    case idle
    case selectingFile
    case uploading
    case success
	case downloading
    case error(String)
}

class DFUViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties (UI Binding)
    @Published var progress: Double = 0.0
    @Published var state: DFUUpdateState = .idle
    @Published var statusMessage: String = "Ready"
    
    // MARK: - DFU Controller
    private var dfuController: DFUServiceController?
    
    // MARK: - Start DFU
    /// Call this function from your SwiftUI View
    /// - Parameters:
    ///   - peripheral: The CoreBluetooth device you are connected to
    ///   - zipFileUrl: The local URL of the Firmware Zip file
    func startDFU(peripheral: CBPeripheral, zipFileUrl: URL) {
        
        guard let firmware = try? DFUFirmware(urlToZipFile: zipFileUrl) else {
            self.state = .error("Invalid Zip File")
            return
        }
        
        // Setup the initiator
        let initiator = DFUServiceInitiator(queue: .main, delegateQueue: .main)
	
		initiator.forceScanningForNewAddressInLegacyDfu = true
		initiator.dataObjectPreparationDelay = 0.4
		initiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
		initiator.forceDfu = false
		initiator.disableResume = true
		initiator.packetReceiptNotificationParameter = 8
		
		// Set self as delegate
        initiator.delegate = self
        initiator.progressDelegate = self
        initiator.logger = self // Optional: For debugging
        
        // Start the process
        self.state = .uploading
		self.dfuController = initiator.with(firmware: firmware)
			.start(target: peripheral)
    }
    
    // Abort function
    func abort() {
        _ = dfuController?.abort()
    }
}

// MARK: - DFU Service Delegate (State Changes)
extension DFUViewModel: DFUServiceDelegate {
	
	func startProcess(peripheral: CBPeripheral, remoteURLString: String) {
		guard let url = URL(string: remoteURLString) else {
			self.state = .error("Invalid Network URL")
			return
		}

		self.state = .downloading // Update UI to show "Downloading..."
		self.statusMessage = "Downloading Firmware..."

		let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
			// 1. Handle Network Errors
			if let error = error {
				DispatchQueue.main.async {
					self.state = .error(error.localizedDescription)
				}
				return
			}

			// 2. Move file to a permanent temporary location
			// downloadTask creates a file that deletes itself when the closure ends.
			// We must move it to keep it alive for the DFU library.
			guard let tempLocalURL = localURL else { return }
			
			do {
				let fileManager = FileManager.default
				let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
				let destinationURL = documentsURL.appendingPathComponent("firmware.zip")
				
				// Remove previous update file if it exists
				if fileManager.fileExists(atPath: destinationURL.path) {
					try fileManager.removeItem(at: destinationURL)
				}
				
				try fileManager.moveItem(at: tempLocalURL, to: destinationURL)
				
				// 3. Start DFU on Main Thread
				DispatchQueue.main.async {
					self.statusMessage = "Download complete. Starting Bluetooth update..."
					// Call the original function we wrote in the previous step
					self.startDFU(peripheral: peripheral, zipFileUrl: destinationURL)
				}
				
			} catch {
				DispatchQueue.main.async {
					self.state = .error("File System Error: \(error.localizedDescription)")
				}
			}
		}
		task.resume()
	}

	
    func dfuStateDidChange(to state: DFUState) {
        // Map Nordic's internal state to our UI string
        switch state {
        case .completed:
            self.state = .success
            self.statusMessage = "Update Complete"
            self.progress = 1.0
        case .disconnecting:
            self.statusMessage = "Disconnecting..."
        case .aborted:
            self.state = .error("Aborted")
            self.statusMessage = "Update Aborted"
        default:
            self.statusMessage = state.description
        }
        print("DFU State changed: \(state.description)")
    }
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        self.state = .error(message)
        self.statusMessage = "Error: \(message)"
    }
}

// MARK: - DFU Progress Delegate (Progress Bar)
extension DFUViewModel: DFUProgressDelegate {
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        // Convert 0-100 Int to 0.0-1.0 Double for SwiftUI ProgressView
        self.progress = Double(progress) / 100.0
    }
}

// MARK: - Logger Delegate (Optional)
extension DFUViewModel: LoggerDelegate {
    func logWith(_ level: LogLevel, message: String) {
        print("DFU Log: \(message)")
    }
}

