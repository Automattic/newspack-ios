import Foundation

/// SessionManager is responsible for defining the current session for the
/// current account.  It serves to decouple the API and Store layers.
///
struct SessionManager {

    var token: String

    init?(account: Account) {
        let store = StoreContainer.shared.accountStore
        guard let token = store.getAuthTokenForAccount(account) else {
            return nil
        }
        self.token = token
    }
}
