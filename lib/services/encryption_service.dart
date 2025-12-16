// lib/services/encryption_service.dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  static const String _staticKey = 'YOUR_32_CHAR_STATIC_KEY_HERE_123456'; // 32 chars
  static const String _staticIv = 'morpheus-iv-0001'; // 16 chars
  static final _encrypter = Encrypter(AES(Key.fromUtf8(_staticKey)));
  static final _iv = IV.fromUtf8(_staticIv);

  static String encryptData(String data) {
    return _encrypter.encrypt(data, iv: _iv).base64;
  }

  static String decryptData(String encryptedData) {
    return _encrypter.decrypt64(encryptedData, iv: _iv);
  }

  static String encryptPin(String pin) {
    return sha256.convert(utf8.encode(pin + _staticKey)).toString();
  }
}
