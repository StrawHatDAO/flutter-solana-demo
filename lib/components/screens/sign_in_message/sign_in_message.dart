import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phantom_demo/providers/wallet_state_provider.dart';
import 'package:flutter_phantom_demo/utils/logger.dart';
import 'package:flutter_phantom_demo/utils/phantom.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

//https://github.com/ilap/pinenacl-dart/blob/master/example/signature.dart

class SignInMessageScreen extends StatefulWidget {
  final PhantomInstance phantomInstance;
  const SignInMessageScreen({super.key, required this.phantomInstance});

  @override
  State<SignInMessageScreen> createState() => _SignInMessageScreenState();
}

class _SignInMessageScreenState extends State<SignInMessageScreen> {
  _signInAUth(WalletStateProvider walletState) async {
    Uint8List nonce = walletState.generateNoce();
    Uri launchUri = widget.phantomInstance.generateUriSignMessage(nonce: nonce);
    logger.i(launchUri);
    await launchUrl(
      launchUri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState =
        Provider.of<WalletStateProvider>(context, listen: false);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              _signInAUth(walletState);
            },
            child: const Text("Sign Message"),
          ),
        ],
      ),
    );
  }
}
