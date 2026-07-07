import BigInt
import EvmKit
import Foundation

public class TransferMethodFactory: IContractMethodFactory {
    public let methodId: Data = ContractMethodHelper.methodId(signature: TransferMethod.methodSignature)

    public init() {}

    public func createMethod(inputArguments: Data) throws -> ContractMethod {
        guard inputArguments.count >= 64 else {
            throw ContractMethodFactories.DecodeError.invalidABI
        }
        let to = Address(raw: inputArguments[12 ..< 32])
        let value = BigUInt(inputArguments[32 ..< 64])

        return TransferMethod(to: to, value: value)
    }
}
