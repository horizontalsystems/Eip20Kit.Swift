import BigInt
import EvmKit
import Foundation

class ApproveMethodFactory: IContractMethodFactory {
    let methodId: Data = ContractMethodHelper.methodId(signature: ApproveMethod.methodSignature)

    func createMethod(inputArguments: Data) throws -> ContractMethod {
        guard inputArguments.count >= 64 else {
            throw ContractMethodFactories.DecodeError.invalidABI
        }
        let spender = Address(raw: inputArguments[12 ..< 32])
        let value = BigUInt(inputArguments[32 ..< 64])

        return ApproveMethod(spender: spender, value: value)
    }
}
