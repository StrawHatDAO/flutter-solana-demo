import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phantom_demo/components/connected/connected.dart';
import 'package:flutter_phantom_demo/components/not_connected/not_connected.dart';
import 'package:flutter_phantom_demo/components/screens/sign_in_message/signature_verify.dart';
import 'package:flutter_phantom_demo/components/screens/sign_transaction/send_transaction.dart';
import 'package:flutter_phantom_demo/components/screens/transaction_status.dart';
import 'package:flutter_phantom_demo/components/sidebar/sidebar.dart';
import 'package:flutter_phantom_demo/providers/wallet_state_provider.dart';
import 'package:flutter_phantom_demo/utils/logger.dart';
import 'package:flutter_phantom_demo/utils/phantom.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final phantomInstance = PhantomInstance(
    appUrl: "https://solgallery.vercel.app",
    deepLink: "dapp://flutterphantom.app",
  );
  late StreamSubscription sub;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks(context);
  }

  @override
  void dispose() {
    logger.w("Dispose");
    super.dispose();
    sub.cancel();
  }

  void _handleIncomingLinks(context) async {
    final provider = Provider.of<WalletStateProvider>(context, listen: false);
    try {
      sub = uriLinkStream.listen((Uri? link) {
        if (!mounted) return;
        Map<String, String> params = link?.queryParameters ?? {};
        logger.i("Params: $params");
        if (params.containsKey("errorCode")) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.red[400],
              content:
                  Text(params["errorMessage"] ?? "Error connecting wallet"),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
          logger.e(params["errorMessage"]);
        } else {
          logger.w("Dapp path ${link?.path}");
          switch (link?.path) {
            case '/connected':
              if (phantomInstance.createSession(params)) {
                provider.updateConnection(phantomInstance);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green[400],
                    content: const Text("Connected to wallet"),
                    action: SnackBarAction(
                      label: 'Ok',
                      textColor: Colors.white,
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green[400],
                    content: const Text("Error creating session"),
                    action: SnackBarAction(
                      label: 'Ok',
                      textColor: Colors.white,
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                  ),
                );
              }
              break;
            case '/disconnect':
              setState(() {
                provider.updateConnection(phantomInstance);
              });
              break;
            case '/signAndSendTransaction':
              var data = phantomInstance.decryptPayload(
                  data: params["data"]!, nonce: params["nonce"]!);
              logger.i("Decrypted data: ${data['signature']}");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionStatus(
                    signature: data['signature'],
                  ),
                ),
              );
              break;
            case '/signTransaction':
              var data = phantomInstance.decryptPayload(
                  data: params["data"]!, nonce: params["nonce"]!);
              logger.wtf("Decrypted data: $data");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SendTxScreen(
                    transaction: data["transaction"],
                  ),
                ),
              );
              break;
            case '/signAllTransactions':
              var data = phantomInstance.decryptPayload(
                  data: params["data"]!, nonce: params["nonce"]!);
              logger.wtf("Decrypted data: $data");
              break;
            case '/onSignMessage':
              var data = phantomInstance.decryptPayload(
                  data: params["data"]!, nonce: params["nonce"]!);
              logger.i("Decrypted data: ${data['signature']}");
              logger.i("Sign message");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SignatureVerifyScreen(
                    signature: data['signature'],
                    phantomInstance: phantomInstance,
                  ),
                ),
              );
              break;
            default:
              logger.i('unknown');
          }
        }
      }, onError: (err) {
        logger.e('OnError Error: $err');
      });
    } on PlatformException {
      // Handle exception by warning the user their action did not succeed
      logger.e("Error occured PlatfotmException");
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WalletStateProvider>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Welcome to Flutter Demo App"),
      ),
      drawer: provider.isConnected
          ? Sidebar(phantomInstance: phantomInstance)
          : null,
      body: Builder(builder: (context) {
        return provider.isConnected
            ? Connected(phantomInstance: phantomInstance)
            : NotConnected(phantomInstance: phantomInstance);
      }),
    );
  }
}
