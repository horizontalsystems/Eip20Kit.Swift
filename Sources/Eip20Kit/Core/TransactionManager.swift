import Foundation
import EvmKit
import BigInt
import RxSwift

class TransactionManager {
    private let disposeBag = DisposeBag()

    private let evmKit: EvmKit.Kit
    private let contractAddress: Address
    private let contractMethodFactories: Eip20ContractMethodFactories
    private let address: Address
    private let tagQueries: [TransactionTagQuery]

    private let transactionsSubject = PublishSubject<[FullTransaction]>()

    var transactionsObservable: Observable<[FullTransaction]> {
        transactionsSubject.asObservable()
    }

    init(evmKit: EvmKit.Kit, contractAddress: Address, contractMethodFactories: Eip20ContractMethodFactories) {
        self.evmKit = evmKit
        self.contractAddress = contractAddress
        self.contractMethodFactories = contractMethodFactories

        address = evmKit.receiveAddress
        tagQueries = [TransactionTagQuery(contractAddress: contractAddress)]

        evmKit.transactionsObservable(tagQueries: [TransactionTagQuery(contractAddress: contractAddress)])
                .subscribe { [weak self] in
                    self?.processTransactions(eip20Transactions: $0)
                }
                .disposed(by: disposeBag)
    }

    private func processTransactions(eip20Transactions: [FullTransaction]) {
        guard !eip20Transactions.isEmpty else {
            return
        }

        transactionsSubject.onNext(eip20Transactions)
    }

}

extension TransactionManager: ITransactionManager {

    func transactionsSingle(from hash: Data?, limit: Int?) -> Single<[FullTransaction]> {
        evmKit.transactionsSingle(tagQueries: tagQueries, fromHash: hash, limit: limit)
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
