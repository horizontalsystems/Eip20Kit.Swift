import Foundation
import Combine
import BigInt
import EvmKit
import Eip20Kit
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

    var lastBlockHeightPublisher: AnyPublisher<Void, Never> {
        evmKit.lastBlockHeightPublisher.map { _ in () }.eraseToAnyPublisher()
    }

    var syncStatePublisher: AnyPublisher<Void, Never> {
        eip20Kit.syncStatePublisher.map { _ in () }.eraseToAnyPublisher()
    }

    var transactionsSyncStatePublisher: AnyPublisher<Void, Never> {
        eip20Kit.transactionsSyncStatePublisher.map { _ in () }.eraseToAnyPublisher()
    }

    var balancePublisher: AnyPublisher<Void, Never> {
        eip20Kit.balancePublisher.map { _ in () }.eraseToAnyPublisher()
    }

    var transactionsPublisher: AnyPublisher<Void, Never> {
        eip20Kit.transactionsPublisher.map { _ in () }.eraseToAnyPublisher()
    }

    func transactions(from hash: Data?, limit: Int?) -> [TransactionRecord] {
        eip20Kit.transactions(from: hash, limit: limit)
                .compactMap {
                    transactionRecord(fromTransaction: $0)
                }
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord? {
        nil
    }

    func estimatedGasLimit(to address: Address, value: Decimal, gasPrice: GasPrice) async throws -> Int {
        let value = BigUInt(value.hs.roundedString(decimal: token.decimal))!
        let transactionData = eip20Kit.transferTransactionData(to: address, value: value)

        return try await evmKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)
    }

    func fetchTransaction(hash: Data) async throws -> FullTransaction {
        try await evmKit.fetchTransaction(hash: hash)
    }

    func allowance(spenderAddress: Address) async throws -> Decimal {
        let allowanceString = try await eip20Kit.allowance(spenderAddress: spenderAddress)

        guard let significand = Decimal(string: allowanceString) else {
            return 0
        }

        return Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
    }

    func send(to: Address, amount: Decimal, gasLimit: Int, gasPrice: GasPrice) async throws {
        guard let signer = signer else {
            throw SendError.noSigner
        }

        let value = BigUInt(amount.hs.roundedString(decimal: token.decimal))!
        let transactionData = eip20Kit.transferTransactionData(to: to, value: value)

        let rawTransaction = try await evmKit.fetchRawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
        let signature = try signer.signature(rawTransaction: rawTransaction)

        _ = try await evmKit.send(rawTransaction: rawTransaction, signature: signature)
    }

}

extension Eip20Adapter {

    enum SendError: Error {
        case noSigner
    }

}
