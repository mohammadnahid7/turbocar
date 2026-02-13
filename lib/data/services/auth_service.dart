import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final DioClient _dioClient;
  final StorageService _storageService;

  AuthService(this._dioClient, this._storageService);

  Future<Map<String, dynamic>> login(
    String emailOrPhone,
    String password,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.login,
        data: {'email_or_phone': emailOrPhone, 'password': password},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String phone,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.register,
        data: {
          'email': email,
          'phone': phone,
          'password': password,
          'full_name': fullName,
        },
      );
      print(response.data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendOtp(String phone) async {
    await _dioClient.post(ApiConstants.sendOtp, data: {'phone': phone});
  }

  Future<void> verifyOtp(String phone, String code) async {
    await _dioClient.post(
      ApiConstants.verifyOtp,
      data: {'phone': phone, 'code': code},
    );
  }

  Future<void> logout() async {
    try {
      await _dioClient.post(ApiConstants.logout);
    } catch (e) {
      // Ignore errors on logout
    } finally {
      await _storageService.deleteToken();
      await _storageService.deleteUser();
    }
  }

  Future<UserModel> convertUserDtoToModel(Map<String, dynamic> userDto) async {
    // Backend returns UserDTO which matches UserModel structure usually,
    // but check if adaptation is needed.
    return UserModel.fromJson(userDto);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> userData) async {
    try {
      final response = await _dioClient.put(ApiConstants.me, data: userData);
      final user = UserModel.fromJson(response.data);
      await _storageService.saveUser(user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _dioClient.post(
        ApiConstants.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _dioClient.get(ApiConstants.me);
      final user = UserModel.fromJson(response.data);
      await _storageService.saveUser(user);
      return user;
    } catch (e) {
      // If unauthorized, token might be invalid
      return null;
    }
  }

  Future<String> uploadImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path),
      });

      final response = await _dioClient.post(
        '/api/upload', // Generic upload endpoint
        data: formData,
      );

      return response.data['url'] as String;
    } catch (e) {
      rethrow;
    }
  }
}
