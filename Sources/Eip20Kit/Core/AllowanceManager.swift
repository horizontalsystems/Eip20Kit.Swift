import RxSwift
import BigInt
import EvmKit
import HsCryptoKit

enum AllowanceParsingError: Error {
    case notFound
}

class AllowanceManager {
    private let disposeBag = DisposeBag()

    private let evmKit: EvmKit.Kit
    private let contractAddress: Address
    private let address: Address

    init(evmKit: EvmKit.Kit, contractAddress: Address, address: Address) {
        self.evmKit = evmKit
        self.contractAddress = contractAddress
        self.address = address
    }

    func allowanceSingle(spenderAddress: Address, defaultBlockParameter: DefaultBlockParameter) -> Single<BigUInt> {
        let data = AllowanceMethod(owner: address, spender: spenderAddress).encodedABI()

        return evmKit.call(contractAddress: contractAddress, data: data, defaultBlockParameter: defaultBlockParameter)
                .map { data in
                    BigUInt(data[0...31])
                }
    }

    func approveTransactionData(spenderAddress: Address, amount: BigUInt) -> TransactionData {
        TransactionData(
                to: contractAddress,
                value: BigUInt.zero,
                input: ApproveMethod(spender: spenderAddress, value: amount).encodedABI()
        )
    }

}
