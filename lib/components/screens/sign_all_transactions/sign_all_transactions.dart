import 'package:flutter/material.dart';
import 'package:flutter_phantom_demo/components/styled_text_feild.dart';
import 'package:flutter_phantom_demo/providers/wallet_state_provider.dart';
import 'package:flutter_phantom_demo/utils/phantom.dart';
import 'package:provider/provider.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'package:url_launcher/url_launcher.dart';

class SignAllTransactionScreen extends StatefulWidget {
  final PhantomInstance phantomInstance;
  const SignAllTransactionScreen({super.key, required this.phantomInstance});

  @override
  State<SignAllTransactionScreen> createState() =>
      _SignAllTransactionScreenState();
}

class _SignAllTransactionScreenState extends State<SignAllTransactionScreen> {
  // User input
  TextEditingController walletAddressController = TextEditingController();
  TextEditingController solAmountController = TextEditingController();

  signAndSendTransaction(WalletStateProvider walletStateProvider) async {
    int amount =
        ((double.parse(solAmountController.text)) * lamportsPerSol).toInt();
    final transferIx1 = SystemInstruction.transfer(
        fundingAccount:
            Ed25519HDPublicKey.fromBase58(widget.phantomInstance.userPublicKey),
        recipientAccount:
            Ed25519HDPublicKey.fromBase58(walletAddressController.text),
        lamports: amount);
    final message1 = Message.only(transferIx1);
    final transferIx2 = SystemInstruction.transfer(
        fundingAccount:
            Ed25519HDPublicKey.fromBase58(widget.phantomInstance.userPublicKey),
        recipientAccount:
            Ed25519HDPublicKey.fromBase58(walletAddressController.text),
        lamports: amount);
    final message2 = Message.only(transferIx2);
    final blockhash = await RpcClient('https://api.devnet.solana.com')
        .getRecentBlockhash()
        .then((b) => b.blockhash);
    final compiled1 = message1.compile(recentBlockhash: blockhash);
    final compiled2 = message2.compile(recentBlockhash: blockhash);

    final tx1 = SignedTx(
      messageBytes: compiled1.data,
      signatures: [
        Signature(
          List.filled(64, 0),
          publicKey: Ed25519HDPublicKey.fromBase58(
              widget.phantomInstance.userPublicKey),
        )
      ],
    ).encode();
    final tx2 = SignedTx(
      messageBytes: compiled2.data,
      signatures: [
        Signature(
          List.filled(64, 0),
          publicKey: Ed25519HDPublicKey.fromBase58(
              widget.phantomInstance.userPublicKey),
        )
      ],
    ).encode();

    var launchUri = widget.phantomInstance.generateUriSignAllTransactions(
        transactions: [tx1, tx2], redirect: '/signAllTransactions');
    await launchUrl(
      launchUri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState =
        Provider.of<WalletStateProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
          child: Column(
        children: [
          styledTextFeild(walletAddressController, "User Wallet Address",
              "Enter User wallet Address", Icons.wallet),
          const SizedBox(height: 10),
          styledTextFeild(solAmountController, "1 SOL = 1,000,000,000 LAMPORTS",
              "Enter amount to send in SOL", Icons.circle_outlined),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              signAndSendTransaction(walletState);
            },
            child: const Text("Sign Transaction"),
          )
        ],
      )),
    );
  }
}
