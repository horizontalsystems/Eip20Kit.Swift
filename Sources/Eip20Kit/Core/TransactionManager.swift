import Foundation
import Combine
import BigInt
import EvmKit

class TransactionManager {
    private var cancellables = Set<AnyCancellable>()

    private let evmKit: EvmKit.Kit
    private let contractAddress: Address
    private let contractMethodFactories: Eip20ContractMethodFactories
    private let address: Address
    private let tagQueries: [TransactionTagQuery]

    private let transactionsSubject = PassthroughSubject<[FullTransaction], Never>()

    var transactionsPublisher: AnyPublisher<[FullTransaction], Never> {
        transactionsSubject.eraseToAnyPublisher()
    }

    init(evmKit: EvmKit.Kit, contractAddress: Address, contractMethodFactories: Eip20ContractMethodFactories) {
        self.evmKit = evmKit
        self.contractAddress = contractAddress
        self.contractMethodFactories = contractMethodFactories

        address = evmKit.receiveAddress
        tagQueries = [TransactionTagQuery(contractAddress: contractAddress)]

        evmKit.transactionsPublisher(tagQueries: [TransactionTagQuery(contractAddress: contractAddress)])
                .sink { [weak self] in
                    self?.processTransactions(eip20Transactions: $0)
                }
                .store(in: &cancellables)
    }

    private func processTransactions(eip20Transactions: [FullTransaction]) {
        guard !eip20Transactions.isEmpty else {
            return
        }

        transactionsSubject.send(eip20Transactions)
    }

}

extension TransactionManager: ITransactionManager {

    func transactions(from hash: Data?, limit: Int?) -> [FullTransaction] {
        evmKit.transactions(tagQueries: tagQueries, fromHash: hash, limit: limit)
    }

    func pendingTransactions() -> [FullTransaction] {
        evmKit.pendingTransactions(tagQueries: tagQueries)
    }

    func transferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        TransactionData(
                to: contractAddress,
                value: BigUInt.zero,
                input: TransferMethod(to: to, value: value).encodedABI()
        )
    }

}
