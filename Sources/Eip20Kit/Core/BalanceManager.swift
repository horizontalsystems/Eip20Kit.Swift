import Foundation
import EvmKit
import BigInt
import HsExtensions

class BalanceManager {
    weak var delegate: IBalanceManagerDelegate?

    private let storage: Eip20Storage
    private let contractAddress: Address
    private let address: Address
    private let dataProvider: IDataProvider
    private var tasks = Set<AnyTask>()

    init(storage: Eip20Storage, contractAddress: Address, address: Address, dataProvider: IDataProvider) {
        self.storage = storage
        self.contractAddress = contractAddress
        self.address = address
        self.dataProvider = dataProvider
    }

    private func save(balance: BigUInt) {
        storage.save(balance: balance, contractAddress: contractAddress)
    }

    private func _sync() async {
        do {
            let balance = try await dataProvider.fetchBalance(contractAddress: contractAddress, address: address)
            save(balance: balance)
            delegate?.onSyncBalanceSuccess(balance: balance)
        } catch {
            delegate?.onSyncBalanceFailed(error: error)
        }
    }

}

extension BalanceManager: IBalanceManager {

    var balance: BigUInt? {
        storage.balance(contractAddress: contractAddress)
    }

    func sync() {
        Task { [weak self] in await self?._sync() }.store(in: &tasks)
    }

}
