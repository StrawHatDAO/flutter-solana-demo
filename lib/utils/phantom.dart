import 'dart:convert';

import 'package:bs58/bs58.dart';
import 'package:flutter_phantom_demo/utils/logger.dart';
import 'package:pinenacl/x25519.dart';
import 'package:solana/base58.dart';
import 'package:solana/solana.dart';

class PhantomInstance {
  String urlApp = "domain";
  String scheme = "https";
  String host = "phantom.app";
  String? sessionToken;

  // App Keypair for encryption and decryption
  // App's private key must be kept secret
  late PrivateKey dAppSecretKey;
  late PublicKey dAppPublicKey;

  // User's public key
  late String userPublicKey;

  // deeplink uri
  String deepLink = "dapp://flutterphantom.app";

  Box? sharedSecret;

  PhantomInstance() {
    dAppSecretKey = PrivateKey.generate();
    dAppPublicKey = dAppSecretKey.publicKey;
  }

  Uri generateUriConnect({required String redirect, required String cluster}) {
    Uri url = Uri(
      scheme: 'https',
      host: 'phantom.app',
      path: '/ul/v1/connect',
      queryParameters: {
        'dapp_encryption_public_key': base58.encode(dAppPublicKey.asTypedList),
        'cluster': cluster,
        'app_url': "https://solgallery.vercel.app/",
        'redirect_link': "$deepLink$redirect",
      },
    );
    return url;
  }

  Uri generateUriSignAndSendTransaction({required String transaction}) {
    var payload = {
      "session": sessionToken,
      "transaction": base58.encode(
        Uint8List.fromList(
          base64.decode(transaction),
        ),
      ),
    };
    var encryptedPayload = encryptPayload(payload);

    var launchUriStr = 'https://phantom.app/ul/v1/signAndSendTransaction';

    final launchUri = Uri.parse(launchUriStr).replace(queryParameters: {
      "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
      "nonce": base58.encode(encryptedPayload["nonce"]),
      'redirect_link': "$deepLink/signAndSendTransaction",
      'payload': base58.encode(encryptedPayload["encryptedPayload"])
    });
    return launchUri;
  }

  Uri generateDisconectUri() {
    var launchUriStr = 'https://phantom.app/ul/v1/disconnect';
    var payLoad = {
      "session": sessionToken,
    };
    var encryptedPayload = encryptPayload(payLoad);

    final launchUri = Uri.parse(launchUriStr).replace(queryParameters: {
      "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
      "nonce": base58.encode(encryptedPayload["nonce"]),
      'redirect_link': "$deepLink/disconnect",
      "payload": base58.encode(encryptedPayload["encryptedPayload"]),
    });
    sharedSecret = null;
    return launchUri;
  }

  Uri generateUriSignTransaction({required String transaction}) {
    var payload = {
      "transaction": base58.encode(
        Uint8List.fromList(
          base64.decode(transaction),
        ),
      ),
      "session": sessionToken,
    };
    var encryptedPayload = encryptPayload(payload);

    var launchUriStr = 'https://phantom.app/ul/v1/signTransaction';

    final launchUri = Uri.parse(launchUriStr).replace(queryParameters: {
      "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
      "nonce": base58.encode(encryptedPayload["nonce"]),
      'redirect_link': "$deepLink/signTransaction",
      'payload': base58.encode(encryptedPayload["encryptedPayload"])
    });
    return launchUri;
  }

  Uri generateUriSignAllTransactions({required List<String> transactions}) {
    var payload = {
      "transactions": transactions
          .map((e) => base58.encode(
                Uint8List.fromList(
                  base64.decode(e),
                ),
              ))
          .toList(),
      "session": sessionToken,
    };
    var encryptedPayload = encryptPayload(payload);

    var launchUriStr = 'https://phantom.app/ul/v1/signAllTransactions';

    final launchUri = Uri.parse(launchUriStr).replace(queryParameters: {
      "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
      "nonce": base58.encode(encryptedPayload["nonce"]),
      'redirect_link': "$deepLink/signAllTransactions",
      'payload': base58.encode(encryptedPayload["encryptedPayload"])
    });
    return launchUri;
  }

  Uri generateUriSignMessage({required Uint8List nonce}) {
    var message =
        "Sign this message for authenticating with your wallet. Nonce: ${base58.encode(nonce)}";
    var payload = {
      "session": sessionToken,
      "message": base58.encode(message.codeUnits.toUint8List()),
    };

    var encrypt = encryptPayload(payload);

    return Uri(
        scheme: scheme,
        host: host,
        path: 'ul/v1/signMessage',
        queryParameters: {
          "dapp_encryption_public_key":
              base58.encode(Uint8List.fromList(dAppPublicKey)),
          "nonce": base58.encode(encrypt["nonce"]),
          "redirect_link": "$deepLink/onSignMessage",
          "payload": base58.encode(encrypt["encryptedPayload"]),
        });
  }

  bool createSession(Map<String, String> params) {
    try {
      createSharedSecret(
          base58.decode(params["phantom_encryption_public_key"]!));
      var dataDecrypted =
          decryptDataPayload(data: params["data"]!, nonce: params["nonce"]!);
      logger.e(dataDecrypted);
      sessionToken = dataDecrypted["session"];
      userPublicKey = dataDecrypted["public_key"];
    } catch (e) {
      logger.e(e);
      return false;
    }
    return true;
  }

  Future<bool> isValidSignature(String signature, Uint8List nonce) async {
    var message =
        "Sign this message for authenticating with your wallet. Nonce: ${base58.encode(nonce)}";
    var messageBytes = message.codeUnits.toUint8List();
    var signatureBytes = base58.decode(signature);
    bool verify = await verifySignature(
      message: messageBytes,
      signature: signatureBytes,
      publicKey: Ed25519HDPublicKey.fromBase58(userPublicKey),
    );
    return verify;
  }

  void createSharedSecret(Uint8List remotePubKey) async {
    sharedSecret = Box(
      myPrivateKey: dAppSecretKey,
      theirPublicKey: PublicKey(remotePubKey),
    );
  }

  Map<dynamic, dynamic> decryptDataPayload(
      {required String data, required String nonce}) {
    if (sharedSecret == null) {
      return <String, String>{};
    }

    final decryptedData = sharedSecret?.decrypt(
      ByteList(base58.decode(data)),
      nonce: base58.decode(nonce),
    );

    Map payload =
        const JsonDecoder().convert(String.fromCharCodes(decryptedData!));
    return payload;
  }

  Map<String, dynamic> encryptPayload(Map<String, dynamic> data) {
    if (sharedSecret == null) {
      return <String, String>{};
    }
    var nonce = PineNaClUtils.randombytes(24);
    logger.d(jsonEncode(data));
    var payload = jsonEncode(data).codeUnits;
    var encryptedPayload =
        sharedSecret?.encrypt(payload.toUint8List(), nonce: nonce).cipherText;
    return {"encryptedPayload": encryptedPayload?.asTypedList, "nonce": nonce};
  }
}
