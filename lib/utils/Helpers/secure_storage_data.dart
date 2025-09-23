import 'robust_storage_service.dart';

class SecureStorageService {
  Future<void> saveLoginData(Map<String, dynamic> data) async {
    await RobustStorageService.write('token', data['token']);
    await RobustStorageService.write('expires', data['expires']);
    await RobustStorageService.write('currentUserId', data['currentUserId'].toString());
    await RobustStorageService.write('currentName', data['currentName']);
    await RobustStorageService.write('role', data['role']?.toString() ?? '');
    await RobustStorageService.write('idBoutique', data['idBoutique']?.toString() ?? '');
  }

  Future<String?> getToken() async {
    return await RobustStorageService.read('token');
  }

  Future<Map<String, String?>> getLoginData() async {
    return {
      'token': await RobustStorageService.read('token'),
      'expires': await RobustStorageService.read('expires'),
      'currentUserId': await RobustStorageService.read('currentUserId'),
      'currentName': await RobustStorageService.read('currentName'),
      'role': await RobustStorageService.read('role'),
      'idBoutique': await RobustStorageService.read('idBoutique'),
    };
  }

  Future<void> clear() async {
    await RobustStorageService.clear();
  }
}
