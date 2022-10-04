import Foundation
import EvmKit
import Eip20Kit
import RxSwift
import BigInt
import HsExtensions

class Eip20Adapter {
    private let evmKit: EvmKit.Kit
    private let signer: Signer?
    private let eip20Kit: Eip20Kit.Kit
    private let token: Eip20Token

    init(evmKit: EvmKit.Kit, signer: Signer?, token: Eip20Token) throws {
        self.evmKit = evmKit
        self.signer = signer
        eip20Kit = try Eip20Kit.Kit.instance(evmKit: evmKit, contractAddress: token.contractAddress)
        self.token = token
    }

    private func transactionRecord(fromTransaction fullTransaction: FullTransaction) -> TransactionRecord? {
        let transaction = fullTransaction.transaction

        var amount: Decimal?

        if let value = transaction.value, let significand = Decimal(string: value.description) {
            amount = Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
        }

        return TransactionRecord(
                transactionHash: transaction.hash.hs.hexString,
                transactionHashData: transaction.hash,
                timestamp: transaction.timestamp,
                isFailed: transaction.isFailed,
                from: transaction.from,
                to: transaction.to,
                amount: amount,
                input: transaction.input.map {
                    $0.hs.hexString
                },
                blockHeight: transaction.blockNumber,
                transactionIndex: transaction.transactionIndex,
                decoration: String(describing: fullTransaction.decoration)
        )
    }

}

extension Eip20Adapter {

    func start() {
        eip20Kit.start()
    }

    func stop() {
        eip20Kit.stop()
    }

    func refresh() {
        eip20Kit.refresh()
    }

    var name: String {
        token.name
    }

    var coin: String {
        token.code
    }

    var lastBlockHeight: Int? {
        evmKit.lastBlockHeight
    }

    var syncState: EvmKit.SyncState {
        switch eip20Kit.syncState {
        case .synced: return EvmKit.SyncState.synced
        case .syncing: return EvmKit.SyncState.syncing(progress: nil)
        case .notSynced(let error): return EvmKit.SyncState.notSynced(error: error)
        }
    }

    var transactionsSyncState: EvmKit.SyncState {
        switch eip20Kit.transactionsSyncState {
        case .synced: return EvmKit.SyncState.synced
        case .syncing: return EvmKit.SyncState.syncing(progress: nil)
        case .notSynced(let error): return EvmKit.SyncState.notSynced(error: error)
        }
    }

    var balance: Decimal {
        if let balance = eip20Kit.balance, let significand = Decimal(string: balance.description) {
            return Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
        }

        return 0
    }

    var receiveAddress: Address {
        evmKit.receiveAddress
    }

    var lastBlockHeightObservable: Observable<Void> {
        evmKit.lastBlockHeightObservable.map { _ in () }
    }

    var syncStateObservable: Observable<Void> {
        eip20Kit.syncStateObservable.map { _ in () }
    }

    var transactionsSyncStateObservable: Observable<Void> {
        eip20Kit.transactionsSyncStateObservable.map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        eip20Kit.balanceObservable.map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        eip20Kit.transactionsObservable.map { _ in () }
    }

    func transactionsSingle(from hash: Data?, limit: Int?) -> Single<[TransactionRecord]> {
        try! eip20Kit.transactionsSingle(from: hash, limit: limit)
                .map { [weak self] in
                    $0.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord? {
        nil
    }

    func estimatedGasLimit(to address: Address, value: Decimal, gasPrice: GasPrice) -> Single<Int> {
        let value = BigUInt(value.hs.roundedString(decimal: token.decimal))!
        let transactionData = eip20Kit.transferTransactionData(to: address, value: value)

        return evmKit.estimateGas(transactionData: transactionData, gasPrice: gasPrice)
    }

    func transactionSingle(hash: Data) -> Single<FullTransaction> {
        evmKit.transactionSingle(hash: hash)
    }

    func allowanceSingle(spenderAddress: Address) -> Single<Decimal> {
        eip20Kit.allowanceSingle(spenderAddress: spenderAddress)
                .flatMap { [weak self] allowanceString in
                    guard let strongSelf = self else {
                        throw Kit.KitError.weakReference
                    }

                    if let significand = Decimal(string: allowanceString) {
                        return Single.just(Decimal(sign: .plus, exponent: -strongSelf.token.decimal, significand: significand))
                    }

                    return Single.just(0)
                }
    }

    func sendSingle(to: Address, amount: Decimal, gasLimit: Int, gasPrice: GasPrice) -> Single<Void> {
        guard let signer = signer else {
            return Single.error(SendError.noSigner)
        }

        let value = BigUInt(amount.hs.roundedString(decimal: token.decimal))!
        let transactionData = eip20Kit.transferTransactionData(to: to, value: value)

        return evmKit
                .rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
                .flatMap { [weak self] rawTransaction in
                    guard let strongSelf = self else {
                        throw EvmKit.Kit.KitError.weakReference
                    }

                    let signature = try signer.signature(rawTransaction: rawTransaction)

                    return strongSelf.evmKit.sendSingle(rawTransaction: rawTransaction, signature: signature)
                }
                .map { (tx: FullTransaction) in () }
    }

}

extension Eip20Adapter {

    enum SendError: Error {
        case noSigner
    }

}
