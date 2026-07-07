import BigInt
import EvmKit

public class TransferMethod: ContractMethod {
    static let methodSignature = "transfer(address,uint256)"

    public let to: Address
    public let value: BigUInt

    public init(to: Address, value: BigUInt) {
        self.to = to
        self.value = value

        super.init()
    }

    override public var methodSignature: String { TransferMethod.methodSignature }
    override public var arguments: [Any] { [to, value] }
}
