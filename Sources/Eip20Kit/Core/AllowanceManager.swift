import BigInt
import EvmKit
import HsCryptoKit

enum AllowanceParsingError: Error {
    case notFound
}

class AllowanceManager {
    private let evmKit: EvmKit.Kit
    private let contractAddress: Address
    private let address: Address

    init(evmKit: EvmKit.Kit, contractAddress: Address, address: Address) {
        self.evmKit = evmKit
        self.contractAddress = contractAddress
        self.address = address
    }

    func allowance(spenderAddress: Address, defaultBlockParameter: DefaultBlockParameter) async throws -> BigUInt {
        let methodData = AllowanceMethod(owner: address, spender: spenderAddress).encodedABI()
        let data = try await evmKit.fetchCall(contractAddress: contractAddress, data: methodData, defaultBlockParameter: defaultBlockParameter)
        return BigUInt(data[0...31])
    }

    func approveTransactionData(spenderAddress: Address, amount: BigUInt) -> TransactionData {
        TransactionData(
                to: contractAddress,
                value: BigUInt.zero,
                input: ApproveMethod(spender: spenderAddress, value: amount).encodedABI()
        )
    }

}
