# Eip20Kit.Swift

`Eip20Kit.Swift` is an extension to `EvmKit.Swift` that implements `Eip20` token standard. 

## Features

- Synchronization of EIP20 token balance and transactions
- Allowance management
- Reactive API for wallet

## Usage

### Initialization

```swift
import EvmKit
import Eip20Kit
import HdWalletKit

let contractAddress = try EvmKit.Address(hex: "0x..token..contract..address..")

let evmKit = try Kit.instance(
	address: try EvmKit.Address(hex: "0x..user..address.."),
	chain: .ethereum,
	rpcSource: .ethereumInfuraWebsocket(projectId: "...", projectSecret: "..."),
	transactionSource: .ethereumEtherscan(apiKey: "..."),
	walletId: "unique_wallet_id",
	minLogLevel: .error
)

let eip20Kit = try Eip20Kit.Kit.instance(
	evmKit: evmKit, 
	contractAddress: contractAddress
)

// Decorators are needed to detect transactions as `Eip20` transfer/approve transactions
Eip20Kit.Kit.addDecorators(to: evmKit)

// Eip20 transactions syncer is needed to pull Eip20 transfer transactions from Etherscan
Eip20Kit.Kit.addTransactionSyncer(to: evmKit)
```


### Get token balance

```swift
guard let balance = eip20Kit.balance else {
	return
}

print("Balance: \(balance.description)")

```

### Send `Eip20` Transaction

```swift
// Get Signer object
let seed = Mnemonic.seed(mnemonic: ["mnemonic", "words", ...])!
let signer = try Signer.instance(seed: seed, chain: .ethereum)

let to = try EvmKit.Address(hex: "0x..recipient..adress..here")
let amount = BigUInt("100000000000000000")
let gasPrice = GasPrice.legacy(gasPrice: 50_000_000_000)

// Construct TransactionData which calls a `Transfer` method of the EIP20 compatible smart contract
let transactionData = eip20Kit.transferTransactionData(to: to, value: amount)

// Estimate gas for the transaction
let estimateGasSingle = evmKit.estimateGas(transactionData: transactionData, gasPrice: gasPrice)

// Generate a raw transaction which is ready to be signed
let rawTransactionSingle = estimateGasSingle.flatMap { estimatedGasLimit in
    evmKit.rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: estimatedGasLimit)
}

let sendSingle = rawTransactionSingle.flatMap { rawTransaction in
    // Sign the transaction
    let signature = try signer.signature(rawTransaction: rawTransaction)
    
    // Send the transaction to RPC node
    return evmKit.sendSingle(rawTransaction: rawTransaction, signature: signature)
}


let disposeBag = DisposeBag()

// This step is needed for Rx reactive code to run
sendSingle
    .subscribe(
        onSuccess: { fullTransaction in
            // sendSingle returns FullTransaction object which contains transaction, and a transaction decoration
            // Eip20Kit.Swift kit creates a OutgoingDecoration decoration for transfer method transaction

            let transaction = fullTransaction.transaction
            print("Transaction sent: \(transaction.hash.hs.hexString)")

            guard let decoration = transaction.decoration as? OutgoingDecoration else {
                return
            }

            print("To: \(decoration.to.eip55)")
            print("Amount: \(decoration.value.description)")
        }, onError: { error in
            print("Send failed: \(error)")
        }
    )
    .disposed(by: disposeBag)
```

### Get transactions

```swift
evmKit.transactionsSingle(tagQueries: [TransactionTagQuery(protocol: .eip20, contractAddress: contractAddress)])
    .subscribe(
        onSuccess: { fullTransactions in
            for fullTransaction in fullTransactions {
                let transaction = fullTransaction.transaction
                print("Transaction hash: \(transaction.hash.hs.hexString)")

                switch fullTransaction.decoration {
                case let decoration as IncomingDecoration:
                    print("From: \(decoration.from.eip55)")
                    print("Amount: \(decoration.value.description)")

                case let decoration as OutgoingDecoration:
                    print("To: \(decoration.to.eip55)")
                    print("Amount: \(decoration.value.description)")

                default: ()
                }
            }
        }, onError: { error in
            print("Send failed: \(error)")
        }
    )
    .disposed(by: disposeBag)
```

## Prerequisites

* Xcode 10.0+
* Swift 5.5+
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

