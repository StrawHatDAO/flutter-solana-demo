import 'package:flutter/material.dart';
import 'package:flutter_phantom_demo/components/screens/screens.dart';
import 'package:flutter_phantom_demo/providers/screen_provider.dart';
import 'package:flutter_phantom_demo/utils/phantom.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class Sidebar extends StatelessWidget {
  final PhantomInstance phantomInstance;
  final padding = const EdgeInsets.symmetric(horizontal: 20);

  const Sidebar({super.key, required this.phantomInstance});
  @override
  Widget build(BuildContext context) {
    const solname = 'jhondoe.sol';
    var walletAddrs = phantomInstance.userPublicKey;
    const urlImage =
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=634&q=80';

    return Drawer(
      child: Material(
        color: const Color.fromRGBO(50, 75, 205, 1),
        child: ListView(
          children: <Widget>[
            buildHeader(
                urlImage: urlImage, name: solname, walletAddress: walletAddrs),
            Container(
              padding: padding,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  buildSideBarButton(
                    text: 'Home',
                    icon: Icons.home,
                    onClicked: () => selectedItem(context, 0, phantomInstance),
                  ),
                  const SizedBox(height: 16),
                  buildSideBarButton(
                    text: 'Sign Message',
                    icon: Icons.message,
                    onClicked: () => selectedItem(context, 1, phantomInstance),
                  ),
                  const SizedBox(height: 16),
                  buildSideBarButton(
                    text: 'Sign and Send Transaction',
                    icon: Icons.send_and_archive,
                    onClicked: () => selectedItem(context, 2, phantomInstance),
                  ),
                  const SizedBox(height: 16),
                  buildSideBarButton(
                    text: 'Sign Transaction',
                    icon: Icons.back_hand,
                    onClicked: () => selectedItem(context, 3, phantomInstance),
                  ),
                  const SizedBox(height: 16),
                  buildSideBarButton(
                    text: 'Disconnect',
                    icon: Icons.link_off,
                    onClicked: () => selectedItem(context, 4, phantomInstance),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white70),
                  const SizedBox(height: 24),
                  buildSideBarButton(
                    text: 'Plugins',
                    icon: Icons.account_tree_outlined,
                    onClicked: () => selectedItem(context, 10, phantomInstance),
                  ),
                  const SizedBox(height: 16),
                  buildSideBarButton(
                    text: 'Notifications',
                    icon: Icons.notifications_outlined,
                    onClicked: () => selectedItem(context, 10, phantomInstance),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader({
    required String urlImage,
    required String name,
    required String walletAddress,
  }) =>
      InkWell(
        child: Container(
          padding: padding.add(const EdgeInsets.symmetric(vertical: 40)),
          child: Row(
            children: [
              CircleAvatar(radius: 30, backgroundImage: NetworkImage(urlImage)),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    toShortAddres(address: walletAddress),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
              const Spacer(),
              InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(50)),
                splashColor: Colors.white12,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 0,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: const Icon(Icons.copy, color: Colors.white),
                  ),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: walletAddress));
                },
              ),
            ],
          ),
        ),
      );

  String toShortAddres({required String address}) {
    return "${address.substring(0, 10)}...${address.substring(phantomInstance.userPublicKey.length - 5, phantomInstance.userPublicKey.length)}";
  }

  Widget buildSideBarButton({
    required String text,
    required IconData icon,
    VoidCallback? onClicked,
  }) {
    const color = Colors.white;
    const hoverColor = Colors.white70;

    return ListTile(
      leading: Icon(icon, color: color),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      title: Text(text, style: const TextStyle(color: color)),
      hoverColor: hoverColor,
      onTap: onClicked,
    );
  }

  void selectedItem(
      BuildContext context, int index, PhantomInstance phantomInstance) async {
    Navigator.pop(context);
    switch (index) {
      case 0:
        context.read<ScreenProvider>().changeScreen(Screens.home);
        break;
      case 1:
        context.read<ScreenProvider>().changeScreen(Screens.message);
        break;
      case 2:
        context.read<ScreenProvider>().changeScreen(Screens.send);
        break;
      case 3:
        context.read<ScreenProvider>().changeScreen(Screens.sign);
        break;
      case 4:
        Uri url = phantomInstance.generateDisconectUri();
        await launchUrl(url, mode: LaunchMode.externalApplication);
        break;
      default:
        context.read<ScreenProvider>().changeScreen(Screens.home);
        break;
    }
  }
}
