# Eip20Kit.Swift

`Eip20Kit.Swift` is a extension to `EvmKit.Swift` to manage `Eip20` token standard.

## Features

- Support for `Eip20` token standard
- Sync balance
- Sync/Send/Receive `Eip20` token transactions
- Allowance management
- Incoming `Eip20` token transactions retrieved from Etherscan
- Reactive API for wallet

### Send `Eip20` Transaction

```swift
import EvmKit
import Eip20Kit

let decimalAmount: Decimal = 0.1
let amount = BigUInt(decimalAmount.roundedString(decimal: decimal))!
let address = try Address(hex: "0x...")

let eip20Kit = Eip20Kit.Kit.instance(evmKit: evmKit, contractAddress: "contract address of token")
let transactionData = eip20Kit.transferTransactionData(to: address, value: amount)

evmKit
        .sendSingle(transactionData: transactionData, gasPrice: 50_000_000_000, gasLimit: 1_000_000_000_000)
        .subscribe(onSuccess: { [weak self] _ in})
```

## Prerequisites

* Xcode 10.0+
* Swift 5+
* iOS 11+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/horizontalsystems/Eip20Kit.Swift.git", .upToNextMajor(from: "1.0.0"))
]
```

## License

The `Eip20Kit.Swift` toolkit is open source and available under the terms of the [MIT License](https://github.com/horizontalsystems/ethereum-kit-ios/blob/master/LICENSE).

