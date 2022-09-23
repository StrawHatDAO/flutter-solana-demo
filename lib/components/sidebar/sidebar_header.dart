import 'package:flutter/material.dart';
import 'package:flutter_phantom_demo/providers/wallet_state_provider.dart';
import 'package:provider/provider.dart';

class SidebarHeader extends StatefulWidget {
  const SidebarHeader({super.key});

  @override
  State<SidebarHeader> createState() => _SidebarHeaderState();
}

class _SidebarHeaderState extends State<SidebarHeader> {
  connectWallet() {
    print('connect wallet');
  }

  var connected = false;
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WalletStateProvider>(context, listen: true);

    return Container(
      color: Colors.white,
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: provider.isConnected
            ? [
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/images/user.png'),
                      scale: 1,
                    ),
                  ),
                ),
                const Text(
                  "jhondoe.sol",
                  style: TextStyle(color: Colors.blue, fontSize: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  "DVcjkv..3NX51eiv3i",
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 14,
                  ),
                ),
              ]
            : [
                ElevatedButton.icon(
                    onPressed: connectWallet,
                    icon: const Icon(Icons.wallet),
                    label: const Text("Connect Wallet")),
              ],
      ),
    );
  }
}
