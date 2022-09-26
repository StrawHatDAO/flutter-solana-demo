import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:bs58/bs58.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_phantom_demo/utils/logger.dart';
import 'package:solana/solana.dart';

class SendTxsScreen extends StatefulWidget {
  final List<String> transactions;
  const SendTxsScreen({super.key, required this.transactions});

  @override
  State<SendTxsScreen> createState() => _SendTxsScreenState();
}

class _SendTxsScreenState extends State<SendTxsScreen> {
  final rcpClient = RpcClient('https://api.devnet.solana.com');

  _sendTransactionToBlockchain(List<String> txs, BuildContext context) async {
    //
    List<String> decodedTxs = [];
    for (var tx in txs) {
      var transaction = base64.encode(
        Uint8List.fromList(
          base58.decode(tx),
        ),
      );
      decodedTxs.add(transaction);
      logger.e(transaction);
      final TransactionId signature = await rcpClient.sendTransaction(
        transaction,
        preflightCommitment: Commitment.processed,
      );

      logger.e("Signature was $signature");
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Transaction"),
      ),
      body: Center(
        child: ElevatedButton(
            onPressed: () {
              _sendTransactionToBlockchain(widget.transactions, context);
            },
            child: const Text("Send Transaction")),
      ),
    );
  }
}
