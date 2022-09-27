import 'dart:convert';
import 'package:flutter_phantom_demo/utils/logger.dart';
import 'package:pinenacl/digests.dart';
import 'package:pinenacl/x25519.dart';
import 'package:solana/base58.dart';
import 'package:solana/solana.dart';

class PhantomInstance {
  // Phantom App deeplink
  String scheme = "https";
  String host = "phantom.app";

  String? _sessionToken;

  // App Keypair for encryption and decryption
  // App's private key must be kept secret
  late PrivateKey dAppSecretKey;
  late PublicKey dAppPublicKey;

  // App Url
  String appUrl;

  // User's public key
  late String userPublicKey;

  // deeplink uri
  String deepLink;

  Box? _sharedSecret;

  PhantomInstance({required this.appUrl, required this.deepLink}) {
    dAppSecretKey = PrivateKey.generate();
    dAppPublicKey = dAppSecretKey.publicKey;
  }

  Uri generateUriConnect({required String cluster, required String redirect}) {
    return Uri(
      scheme: 'https',
      host: 'phantom.app',
      path: '/ul/v1/connect',
      queryParameters: {
        'dapp_encryption_public_key': base58encode(dAppPublicKey.asTypedList),
        'cluster': cluster,
        'app_url': appUrl,
        'redirect_link': "$deepLink$redirect",
      },
    );
  }

  Uri generateUriSignAndSendTransaction(
      {required String transaction, required String redirect}) {
    var payload = {
      "session": _sessionToken,
      "transaction": base58encode(
        Uint8List.fromList(
          base64.decode(transaction),
        ),
      ),
    };
    var encryptedPayload = encryptPayload(payload);

    return Uri(
      scheme: 'https',
      host: 'phantom.app',
      path: '/ul/v1/signAndSendTransaction',
      queryParameters: {
        "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
        "nonce": base58encode(encryptedPayload["nonce"]),
        'redirect_link': "$deepLink$redirect",
        'payload': base58encode(encryptedPayload["encryptedPayload"])
      },
    );
  }

  Uri generateDisconectUri({required String redirect}) {
    var payLoad = {
      "session": _sessionToken,
    };
    var encryptedPayload = encryptPayload(payLoad);

    Uri launchUri = Uri(
      scheme: 'https',
      host: 'phantom.app',
      path: '/ul/v1/disconnect',
      queryParameters: {
        "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
        "nonce": base58encode(encryptedPayload["nonce"]),
        'redirect_link': "$deepLink$redirect",
        "payload": base58encode(encryptedPayload["encryptedPayload"]),
      },
    );
    _sharedSecret = null;
    return launchUri;
  }

  Uri generateUriSignTransaction(
      {required String transaction, required String redirect}) {
    var payload = {
      "transaction": base58encode(
        Uint8List.fromList(
          base64.decode(transaction),
        ),
      ),
      "session": _sessionToken,
    };
    var encryptedPayload = encryptPayload(payload);

    return Uri(
      scheme: 'https',
      host: 'phantom.app',
      path: '/ul/v1/signTransaction',
      queryParameters: {
        "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
        "nonce": base58encode(encryptedPayload["nonce"]),
        'redirect_link': "$deepLink$redirect",
        'payload': base58encode(encryptedPayload["encryptedPayload"])
      },
    );
  }

  Uri generateUriSignAllTransactions(
      {required List<String> transactions, required String redirect}) {
    var payload = {
      "transactions": transactions
          .map((e) => base58encode(
                Uint8List.fromList(
                  base64.decode(e),
                ),
              ))
          .toList(),
      "session": _sessionToken,
    };
    var encryptedPayload = encryptPayload(payload);

    return Uri(
      scheme: 'https',
      host: 'phantom.app',
      path: '/ul/v1/signAllTransactions',
      queryParameters: {
        "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
        "nonce": base58encode(encryptedPayload["nonce"]),
        'redirect_link': "$deepLink$redirect",
        'payload': base58encode(encryptedPayload["encryptedPayload"])
      },
    );
  }

  Uri generateUriSignMessage(
      {required Uint8List nonce, required String redirect}) {
    Uint8List nonceHashed = Hash.sha256(nonce);

    var message =
        "Sign this message for authenticating with your wallet. Nonce: ${base58encode(nonceHashed)}";

    var payload = {
      "session": _sessionToken,
      "message": base58encode(message.codeUnits.toUint8List()),
    };

    var encrypt = encryptPayload(payload);

    return Uri(
      scheme: scheme,
      host: host,
      path: 'ul/v1/signMessage',
      queryParameters: {
        "dapp_encryption_public_key":
            base58encode(Uint8List.fromList(dAppPublicKey)),
        "nonce": base58encode(encrypt["nonce"]),
        "redirect_link": "$deepLink$redirect",
        "payload": base58encode(encrypt["encryptedPayload"]),
      },
    );
  }

  bool createSession(Map<String, String> params) {
    try {
      createSharedSecret(Uint8List.fromList(
          base58decode(params["phantom_encryption_public_key"]!)));
      var dataDecrypted =
          decryptPayload(data: params["data"]!, nonce: params["nonce"]!);
      logger.e(dataDecrypted);
      _sessionToken = dataDecrypted["session"];
      userPublicKey = dataDecrypted["public_key"];
    } catch (e) {
      logger.e(e);
      return false;
    }
    return true;
  }

  Future<bool> isValidSignature(String signature, Uint8List nonce) async {
    Uint8List nonceHashed = Hash.sha256(nonce);
    var message =
        "Sign this message for authenticating with your wallet. Nonce: ${base58encode(nonceHashed)}";
    var messageBytes = message.codeUnits.toUint8List();
    var signatureBytes = base58decode(signature);
    bool verify = await verifySignature(
      message: messageBytes,
      signature: signatureBytes,
      publicKey: Ed25519HDPublicKey.fromBase58(userPublicKey),
    );
    nonce = Uint8List(0);
    return verify;
  }

  void createSharedSecret(Uint8List remotePubKey) async {
    _sharedSecret = Box(
      myPrivateKey: dAppSecretKey,
      theirPublicKey: PublicKey(remotePubKey),
    );
  }

  Map<dynamic, dynamic> decryptPayload(
      {required String data, required String nonce}) {
    if (_sharedSecret == null) {
      return <String, String>{};
    }

    final decryptedData = _sharedSecret?.decrypt(
      ByteList(base58decode(data)),
      nonce: Uint8List.fromList(base58decode(nonce)),
    );

    Map payload =
        const JsonDecoder().convert(String.fromCharCodes(decryptedData!));
    return payload;
  }

  Map<String, dynamic> encryptPayload(Map<String, dynamic> data) {
    if (_sharedSecret == null) {
      return <String, String>{};
    }
    var nonce = PineNaClUtils.randombytes(24);
    logger.d(jsonEncode(data));
    var payload = jsonEncode(data).codeUnits;
    var encryptedPayload =
        _sharedSecret?.encrypt(payload.toUint8List(), nonce: nonce).cipherText;
    return {"encryptedPayload": encryptedPayload?.asTypedList, "nonce": nonce};
  }
}
