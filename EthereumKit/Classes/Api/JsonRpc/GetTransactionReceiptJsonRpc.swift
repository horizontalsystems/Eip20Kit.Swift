class GetTransactionReceiptJsonRpc: JsonRpc<[String: Any]?> {

    init(transactionHash: Data) {
        super.init(
                method: "eth_getTransactionReceipt",
                params: [transactionHash.toHexString()]
        )
    }

    override func parse(result: Any?) throws -> [String: Any]? {
        result as? [String: Any]
    }

}
