import Foundation

/// SessionManager is responsible for defining the current session for the
/// current account.  It serves to decouple the API and Store layers.
///
struct SessionManager {

    var token: String

    init?(account: Account) {
        guard let token = AccountStore().getAuthTokenForAccount(account) else {
            return nil
        }
        self.token = token
    }
}
