import 'package:flutter/material.dart';
import 'package:flutter_phantom_demo/components/screens/screens.dart';
import 'package:flutter_phantom_demo/components/screens/sign_and_send_transaction/sign_and_send_tx.dart';
import 'package:flutter_phantom_demo/components/screens/sign_in_message/sign_in_message.dart';
import 'package:flutter_phantom_demo/components/screens/sign_transaction/sign_tx.dart';
import 'package:flutter_phantom_demo/providers/screen_provider.dart';
import 'package:flutter_phantom_demo/utils/phantom.dart';
import 'package:provider/provider.dart';

class Connected extends StatefulWidget {
  final PhantomInstance phantomInstance;
  const Connected({super.key, required this.phantomInstance});

  @override
  State<Connected> createState() => _ConnectedState();
}

class _ConnectedState extends State<Connected> {
  @override
  Widget build(BuildContext context) {
    final scrrenProvider = Provider.of<ScreenProvider>(context, listen: true);

    return Container(child: _buildScreen(scrrenProvider.currentScreen));
  }

  Widget _buildScreen(Screens screen) {
    switch (screen) {
      case Screens.send:
        return SignAndSendTransactionScreen(
            phantomInstance: widget.phantomInstance);
      case Screens.message:
        return SignInMessageScreen(phantomInstance: widget.phantomInstance);
      case Screens.sign:
        return SignTransactionScreen(phantomInstance: widget.phantomInstance);
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                "Connected",
                style: TextStyle(fontSize: 20),
              ),
              Text(
                "Use menu to use other features",
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
        );
    }
  }
}
