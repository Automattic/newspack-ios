import Foundation
import WordPressFlux

class AccountStore: Store {

    /// Returns the number of accounts currently in the app.
    ///
    func numberOfAccounts() -> Int {
        let fetchRequest = Account.accountFetchRequest()
        let context = CoreDataManager.shared.mainContext
        let count = (try? context.count(for: fetchRequest)) ?? 0
        return count
    }

}
