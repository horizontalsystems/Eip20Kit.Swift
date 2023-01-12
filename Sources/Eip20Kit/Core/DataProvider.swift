import Foundation
import EvmKit
import RxSwift
import BigInt
import HsExtensions
import HsToolKit

public class DataProvider {
    private let evmKit: EvmKit.Kit

    public init(evmKit: EvmKit.Kit) {
        self.evmKit = evmKit
    }

}

extension DataProvider: IDataProvider {

    public func getBalance(contractAddress: Address, address: Address) -> Single<BigUInt> {
        evmKit.call(contractAddress: contractAddress, data: BalanceOfMethod(owner: address).encodedABI())
                .flatMap { data -> Single<BigUInt> in
                    guard let value = BigUInt(data.prefix(32).hs.hex, radix: 16) else {
                        return Single.error(Eip20Kit.TokenError.invalidHex)
                    }

                    return Single.just(value)
                }
    }

}

extension DataProvider {

    static func nameSingle(networkManager: NetworkManager, rpcSource: RpcSource, contractAddress: Address) -> Single<String> {
        EvmKit.Kit.callSingle(networkManager: networkManager, rpcSource: rpcSource, contractAddress: contractAddress, data: NameMethod().encodedABI())
                .flatMap { data -> Single<String> in
                    guard !data.isEmpty else {
                        return Single.error(Eip20Kit.TokenError.invalidHex)
                    }

                    let parsedArguments = ContractMethodHelper.decodeABI(inputArguments: data, argumentTypes: [Data.self])

                    guard let stringData = parsedArguments[0] as? Data else {
                        throw ContractMethodFactories.DecodeError.invalidABI
                    }

                    guard let string = String(data: stringData, encoding: .utf8) else {
                        return Single.error(Eip20Kit.TokenError.invalidHex)
                    }

                    return Single.just(string)
                }
    }

    static func symbolSingle(networkManager: NetworkManager, rpcSource: RpcSource, contractAddress: Address) -> Single<String> {
        EvmKit.Kit.callSingle(networkManager: networkManager, rpcSource: rpcSource, contractAddress: contractAddress, data: SymbolMethod().encodedABI())
                .flatMap { data -> Single<String> in
                    guard !data.isEmpty else {
                        return Single.error(Eip20Kit.TokenError.invalidHex)
                    }

                    let parsedArguments = ContractMethodHelper.decodeABI(inputArguments: data, argumentTypes: [Data.self])

                    guard let stringData = parsedArguments[0] as? Data else {
                        throw ContractMethodFactories.DecodeError.invalidABI
                    }

                    guard let string = String(data: stringData, encoding: .utf8) else {
                        return Single.error(Eip20Kit.TokenError.invalidHex)
                    }

                    return Single.just(string)
                }
    }

    static func decimalsSingle(networkManager: NetworkManager, rpcSource: RpcSource, contractAddress: Address) -> Single<Int> {
        EvmKit.Kit.callSingle(networkManager: networkManager, rpcSource: rpcSource, contractAddress: contractAddress, data: DecimalsMethod().encodedABI())
                .flatMap { data -> Single<Int> in
                    guard !data.isEmpty else {
                        return Single.error(Eip20Kit.TokenError.invalidHex)
                    }

                    guard let bigIntValue = BigUInt(data.prefix(32).hs.hex, radix: 16) else {
                        return Single.error(Eip20Kit.TokenError.invalidHex)
                    }

                    guard let value = Int(bigIntValue.description) else {
                        return Single.error(Eip20Kit.TokenError.invalidHex)
                    }

                    return Single.just(value)
                }
    }

}

extension DataProvider {

    class NameMethod: ContractMethod {
        override var methodSignature: String { "name()" }
        override var arguments: [Any] { [] }
    }

    class SymbolMethod: ContractMethod {
        override var methodSignature: String { "symbol()" }
        override var arguments: [Any] { [] }
    }

    class DecimalsMethod: ContractMethod {
        override var methodSignature: String { "decimals()" }
        override var arguments: [Any] { [] }
    }

}
