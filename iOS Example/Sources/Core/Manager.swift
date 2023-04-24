import Foundation
import EvmKit
import Eip20Kit
import HdWalletKit

class Manager {
    static let shared = Manager()

    let token = Eip20Token(
            name: "DAI Stablecoin",
            code: "DAI",
            contractAddress: try! Address(hex: "0x6B175474E89094C44Da98b954EedeAC495271d0F"),
            decimal: 18
    )
//    let token = Eip20Token(
//            name: "Tether USD",
//            code: "USDT",
//            contractAddress: try! Address(hex: "0xdAC17F958D2ee523a2206206994597C13D831ec7"),
//            decimal: 6
//    )

    private let keyWords = "mnemonic_words"
    private let keyAddress = "address"

    var evmKit: EvmKit.Kit!
    var signer: Signer!
    var adapter: Eip20Adapter!

    init() {
        if let words = savedWords {
            try? initKit(words: words)
        } else if let address = savedAddress {
            try? initKit(address: address)
        }
    }

    private func initKit(address: Address, configuration: Configuration, signer: Signer?) throws {
        let evmKit = try EvmKit.Kit.instance(
                address: address,
                chain: configuration.chain,
                rpcSource: configuration.rpcSource,
                transactionSource: configuration.transactionSource,
                walletId: "walletId",
                minLogLevel: configuration.minLogLevel
        )

        adapter = try Eip20Adapter(evmKit: evmKit, signer: signer, token: token)

        Eip20Kit.Kit.addDecorators(to: evmKit)
        Eip20Kit.Kit.addTransactionSyncer(to: evmKit)

        self.evmKit = evmKit
        self.signer = signer

        evmKit.start()
        adapter.start()
    }


    private func initKit(words: [String]) throws {
        let configuration = Configuration.shared

        guard let seed = Mnemonic.seed(mnemonic: words) else {
            throw LoginError.seedGenerationFailed
        }

        let signer = try Signer.instance(seed: seed, chain: configuration.chain)

        try initKit(
                address: try Signer.address(seed: seed, chain: configuration.chain),
                configuration: configuration,
                signer: signer
        )
    }

    private func initKit(address: Address) throws {
        let configuration = Configuration.shared

        try initKit(address: address, configuration: configuration, signer: nil)
    }

    private var savedWords: [String]? {
        guard let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String else {
            return nil
        }

        return wordsString.split(separator: " ").map(String.init)
    }

    private var savedAddress: Address? {
        guard let addressString = UserDefaults.standard.value(forKey: keyAddress) as? String else {
            return nil
        }

        return try? Address(hex: addressString)
    }

    private func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func save(address: String) {
        UserDefaults.standard.set(address, forKey: keyAddress)
        UserDefaults.standard.synchronize()
    }

    private func clearStorage() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.removeObject(forKey: keyAddress)
        UserDefaults.standard.synchronize()
    }

}

extension Manager {

    func login(words: [String]) throws {
        try Kit.clear(exceptFor: ["walletId"])

        save(words: words)
        try initKit(words: words)
    }

    func watch(address: Address) throws {
        try Kit.clear(exceptFor: ["walletId"])

        save(address: address.hex)
        try initKit(address: address)
    }

    func logout() {
        clearStorage()

        signer = nil
        evmKit = nil
        adapter = nil
    }

}

extension Manager {

    enum LoginError: Error {
        case seedGenerationFailed
    }

}

struct Eip20Token {
    let name: String
    let code: String
    let contractAddress: Address
    let decimal: Int
}
