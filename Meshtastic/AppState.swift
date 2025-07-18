import Combine
import SwiftUI

class AppState: ObservableObject {
	@Published
	var router: Router
	var accessoryManager: AccessoryManager

	@Published
	var unreadChannelMessages: Int

	@Published
	var unreadDirectMessages: Int

	var totalUnreadMessages: Int {
		unreadChannelMessages + unreadDirectMessages
	}

	private var cancellables: Set<AnyCancellable> = []

	init(router: Router, accessoryManager: AccessoryManager) {
		self.router = router
		self.accessoryManager = accessoryManager
		self.unreadChannelMessages = 0
		self.unreadDirectMessages = 0

		// Keep app icon badge count in sync with messages read status
		$unreadChannelMessages.combineLatest($unreadDirectMessages)
			.sink(receiveValue: { badgeCounts in
				UNUserNotificationCenter.current()
					.setBadgeCount(badgeCounts.0 + badgeCounts.1)
			})
			.store(in: &cancellables)
	}
}
