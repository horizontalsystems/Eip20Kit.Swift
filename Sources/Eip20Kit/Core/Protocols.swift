import Foundation
import Combine
import BigInt
import EvmKit

protocol IBalanceManagerDelegate: AnyObject {
    func onSyncBalanceSuccess(balance: BigUInt)
    func onSyncBalanceFailed(error: Error)
}

protocol ITransactionManager {
    var transactionsPublisher: AnyPublisher<[FullTransaction], Never> { get }

    func transactions(from hash: Data?, limit: Int?) -> [FullTransaction]
    func pendingTransactions() -> [FullTransaction]
    func transferTransactionData(to: Address, value: BigUInt) -> TransactionData
}

protocol IBalanceManager {
    var delegate: IBalanceManagerDelegate? { get set }

    var balance: BigUInt? { get }
    func sync()
}

protocol IDataProvider {
    func fetchBalance(contractAddress: Address, address: Address) async throws -> BigUInt
}
