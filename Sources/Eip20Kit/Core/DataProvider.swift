import EvmKit
import RxSwift
import BigInt
import HsExtensions

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
