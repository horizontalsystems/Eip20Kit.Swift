import EvmKit

class Eip20ContractMethodFactories: ContractMethodFactories {
    static let shared = Eip20ContractMethodFactories()

    override init() {
        super.init()
        register(factories: [TransferMethodFactory(), ApproveMethodFactory()])
    }

}
