import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = FlutterSecureStorage();

  Future<void> saveLoginData(Map<String, dynamic> data) async {
    await _storage.write(key: 'token', value: data['token']);
    await _storage.write(key: 'expires', value: data['expires']);
    await _storage.write(key: 'currentUserId', value: data['currentUserId'].toString());
    await _storage.write(key: 'currentName', value: data['currentName']);
    await _storage.write(key: 'role', value: data['role'].toString());
    await _storage.write(key: 'idBoutique', value: data['idBoutique']?.toString() ?? '');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<Map<String, String?>> getLoginData() async {
    return {
      'token': await _storage.read(key: 'token'),
      'expires': await _storage.read(key: 'expires'),
      'currentUserId': await _storage.read(key: 'currentUserId'),
      'currentName': await _storage.read(key: 'currentName'),
      'role': await _storage.read(key: 'role'),
      'idBoutique': await _storage.read(key: 'idBoutique'),
    };
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
