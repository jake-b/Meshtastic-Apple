//
//  NodeFilter.swift
//  Meshtastic
//
//  Created by Jake Bordens on 9/3/25.
//
import SwiftUI

// NodeFilter
@MainActor
final class NodeListFilterParameters: ObservableObject {
	// Public variables
	@Published var searchText = ""
	@Published var isOnline = false
	@Published var isPkiEncrypted = false
	@Published var isFavorite = false
	@Published var isIgnored = false
	@Published var isEnvironment = false
	@Published var distanceFilter = false
	@Published var maxDistance: Double = 800_000
	@Published var hopsAway: Double = -1.0
	@Published var roleFilter = false
	@Published var deviceRoles: Set<Int> = []
	
	// Private backing vars
	@Published private var _viaLora = true
	@Published private var _viaMqtt = true
	
	// Public computed wrappers with enforcement
	var viaLora: Bool {
		get { _viaLora }
		set {
			_viaLora = newValue
			if !_viaLora && !_viaMqtt {
				_viaMqtt = true   // enforce at least one ON
			}
			objectWillChange.send()
		}
	}
	
	var viaMqtt: Bool {
		get { _viaMqtt }
		set {
			_viaMqtt = newValue
			if !_viaLora && !_viaMqtt {
				_viaLora = true   // enforce at least one ON
			}
			objectWillChange.send()
		}
	}
}
