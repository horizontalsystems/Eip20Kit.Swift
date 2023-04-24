import Foundation
import EvmKit
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

    public func fetchBalance(contractAddress: Address, address: Address) async throws -> BigUInt {
        let data = try await evmKit.fetchCall(contractAddress: contractAddress, data: BalanceOfMethod(owner: address).encodedABI())

        guard let value = BigUInt(data.prefix(32).hs.hex, radix: 16) else {
            throw Eip20Kit.TokenError.invalidHex
        }

        return value
    }

}

extension DataProvider {

    static func fetchName(networkManager: NetworkManager, rpcSource: RpcSource, contractAddress: Address) async throws -> String {
        let data = try await EvmKit.Kit.call(networkManager: networkManager, rpcSource: rpcSource, contractAddress: contractAddress, data: NameMethod().encodedABI())

        guard !data.isEmpty else {
            throw Eip20Kit.TokenError.invalidHex
        }

        let parsedArguments = ContractMethodHelper.decodeABI(inputArguments: data, argumentTypes: [Data.self])

        guard let stringData = parsedArguments[0] as? Data else {
            throw ContractMethodFactories.DecodeError.invalidABI
        }

        guard let string = String(data: stringData, encoding: .utf8) else {
            throw Eip20Kit.TokenError.invalidHex
        }

        return string
    }

    static func fetchSymbol(networkManager: NetworkManager, rpcSource: RpcSource, contractAddress: Address) async throws -> String {
        let data = try await EvmKit.Kit.call(networkManager: networkManager, rpcSource: rpcSource, contractAddress: contractAddress, data: SymbolMethod().encodedABI())

        guard !data.isEmpty else {
            throw Eip20Kit.TokenError.invalidHex
        }

        let parsedArguments = ContractMethodHelper.decodeABI(inputArguments: data, argumentTypes: [Data.self])

        guard let stringData = parsedArguments[0] as? Data else {
            throw ContractMethodFactories.DecodeError.invalidABI
        }

        guard let string = String(data: stringData, encoding: .utf8) else {
            throw Eip20Kit.TokenError.invalidHex
        }

        return string
    }

    static func fetchDecimals(networkManager: NetworkManager, rpcSource: RpcSource, contractAddress: Address) async throws -> Int {
        let data = try await EvmKit.Kit.call(networkManager: networkManager, rpcSource: rpcSource, contractAddress: contractAddress, data: DecimalsMethod().encodedABI())

        guard !data.isEmpty else {
            throw Eip20Kit.TokenError.invalidHex
        }

        guard let bigIntValue = BigUInt(data.prefix(32).hs.hex, radix: 16) else {
            throw Eip20Kit.TokenError.invalidHex
        }

        guard let value = Int(bigIntValue.description) else {
            throw Eip20Kit.TokenError.invalidHex
        }

        return value
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
