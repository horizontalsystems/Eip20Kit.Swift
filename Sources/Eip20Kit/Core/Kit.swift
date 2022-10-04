import Foundation
import RxSwift
import EvmKit
import BigInt

public class Kit {
    private let disposeBag = DisposeBag()

    private let contractAddress: Address
    private let evmKit: EvmKit.Kit
    private let transactionManager: ITransactionManager
    private let balanceManager: IBalanceManager
    private let allowanceManager: AllowanceManager

    private let state: KitState

    init(contractAddress: Address, evmKit: EvmKit.Kit, transactionManager: ITransactionManager, balanceManager: IBalanceManager, allowanceManager: AllowanceManager, state: KitState = KitState()) {
        self.contractAddress = contractAddress
        self.evmKit = evmKit
        self.transactionManager = transactionManager
        self.balanceManager = balanceManager
        self.allowanceManager = allowanceManager
        self.state = state

        onUpdateSyncState(syncState: evmKit.syncState)
        state.balance = balanceManager.balance

        evmKit.syncStateObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateSyncState(syncState: $0)
                })
                .disposed(by: disposeBag)

        transactionManager.transactionsObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.balanceManager.sync()
                })
                .disposed(by: disposeBag)
    }

    private func onUpdateSyncState(syncState: EvmKit.SyncState) {
        switch syncState {
        case .synced:
            state.syncState = .syncing(progress: nil)
            balanceManager.sync()
        case .syncing:
            state.syncState = .syncing(progress: nil)
        case .notSynced(let error):
            state.syncState = .notSynced(error: error)
        }
    }

}

extension Kit {

    public func start() {
        if case .synced = evmKit.syncState {
            balanceManager.sync()
        }
    }

    public func stop() {
    }

    public func refresh() {
    }

    public var syncState: SyncState {
        state.syncState
    }

    public var transactionsSyncState: SyncState {
        evmKit.transactionsSyncState
    }

    public var balance: BigUInt? {
        state.balance
    }

    public func transactionsSingle(from hash: Data?, limit: Int?) throws -> Single<[FullTransaction]> {
        transactionManager.transactionsSingle(from: hash, limit: limit)
    }

    public func pendingTransactions() -> [FullTransaction] {
        transactionManager.pendingTransactions()
    }

    public var syncStateObservable: Observable<SyncState> {
        state.syncStateSubject.asObservable()
    }

    public var transactionsSyncStateObservable: Observable<SyncState> {
        evmKit.transactionsSyncStateObservable
    }

    public var balanceObservable: Observable<BigUInt> {
        state.balanceSubject.asObservable()
    }

    public var transactionsObservable: Observable<[FullTransaction]> {
        transactionManager.transactionsObservable
    }

    public func allowanceSingle(spenderAddress: Address, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<String> {
        allowanceManager.allowanceSingle(spenderAddress: spenderAddress, defaultBlockParameter: defaultBlockParameter)
                .map { amount in
                    amount.description
                }
    }

    public func approveTransactionData(spenderAddress: Address, amount: BigUInt) -> TransactionData {
        allowanceManager.approveTransactionData(spenderAddress: spenderAddress, amount: amount)
    }

    public func transferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        transactionManager.transferTransactionData(to: to, value: value)
    }

}

extension Kit: IBalanceManagerDelegate {

    func onSyncBalanceSuccess(balance: BigUInt) {
        state.syncState = .synced
        state.balance = balance
    }

    func onSyncBalanceFailed(error: Error) {
        state.syncState = .notSynced(error: error)
    }

}

extension Kit {

    public static func instance(evmKit: EvmKit.Kit, contractAddress: Address) throws -> Kit {
        let address = evmKit.address

        let dataProvider: IDataProvider = DataProvider(evmKit: evmKit)
        let transactionManager = TransactionManager(evmKit: evmKit, contractAddress: contractAddress, contractMethodFactories: Eip20ContractMethodFactories.shared)
        let balanceManager = BalanceManager(storage: evmKit.eip20Storage, contractAddress: contractAddress, address: address, dataProvider: dataProvider)
        let allowanceManager = AllowanceManager(evmKit: evmKit, contractAddress: contractAddress, address: address)

        let kit = Kit(contractAddress: contractAddress, evmKit: evmKit, transactionManager: transactionManager, balanceManager: balanceManager, allowanceManager: allowanceManager)

        balanceManager.delegate = kit

        return kit
    }

    public static func addTransactionSyncer(to evmKit: EvmKit.Kit) {
        let syncer = Eip20TransactionSyncer(provider: evmKit.transactionProvider, storage: evmKit.eip20Storage)
        evmKit.add(transactionSyncer: syncer)
    }

    public static func addDecorators(to evmKit: EvmKit.Kit) {
        evmKit.add(methodDecorator: Eip20MethodDecorator(contractMethodFactories: Eip20ContractMethodFactories.shared))
        evmKit.add(eventDecorator: Eip20EventDecorator(userAddress: evmKit.address, storage: evmKit.eip20Storage))
        evmKit.add(transactionDecorator: Eip20TransactionDecorator(userAddress: evmKit.address))
    }

}
