import 'package:flutter/material.dart';
import 'package:flutter_phantom_demo/components/screens/screens.dart';
import 'package:flutter_phantom_demo/components/sidebar/sidebar_header.dart';
import 'package:flutter_phantom_demo/providers/screen_provider.dart';
import 'package:flutter_phantom_demo/providers/wallet_state_provider.dart';
import 'package:flutter_phantom_demo/utils/phantom.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Sidebar extends StatefulWidget {
  final PhantomInstance phantomInstance;
  const Sidebar({super.key, required this.phantomInstance});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WalletStateProvider>(context, listen: true);

    return Drawer(
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
          child: Column(
        children: provider.isConnected
            ? [
                const SidebarHeader(),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () {
                    context.read<ScreenProvider>().changeScreen(Screens.home);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.message),
                  title: const Text('Sign Message'),
                  onTap: () {
                    context
                        .read<ScreenProvider>()
                        .changeScreen(Screens.message);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.send),
                  title: const Text('Sign Transaction & Send'),
                  onTap: () {
                    context.read<ScreenProvider>().changeScreen(Screens.send);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.send),
                  title: const Text("Sign Transaction"),
                  onTap: () {
                    context.read<ScreenProvider>().changeScreen(Screens.sign);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dangerous),
                  title: const Text("Disconnect"),
                  onTap: () async {
                    context.read<ScreenProvider>().changeScreen(Screens.sign);
                    Uri url = widget.phantomInstance.generateDisconectUri();
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                ),
              ]
            : [
                const SidebarHeader(),
                const Divider(),
              ],
      )),
    );
  }
}
