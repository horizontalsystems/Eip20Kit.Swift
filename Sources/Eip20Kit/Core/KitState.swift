import Combine
import BigInt
import EvmKit

class KitState {
    var syncState: SyncState = .syncing(progress: nil) {
        didSet {
            if syncState != oldValue {
                syncStateSubject.send(syncState)
            }
        }
    }

    var balance: BigUInt? {
        didSet {
            if let balance = balance, balance != oldValue {
                balanceSubject.send(balance)
            }
        }
    }

    let syncStateSubject = PassthroughSubject<SyncState, Never>()
    let balanceSubject = PassthroughSubject<BigUInt, Never>()
}
