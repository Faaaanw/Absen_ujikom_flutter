import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiService {
  // GANTI dengan IP Laptop/Komputer kamu.
  // Jangan pakai localhost untuk Android Emulator (gunakan 10.0.2.2) atau Real Device (IP LAN).
  final String baseUrl = 'http://192.168.0.137:8002/api';
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
        }, // Agar Laravel return JSON, bukan HTML saat error
        body: {'email': email, 'password': password},
      );

      final responseData = json.decode(response.body);

      // Skenario 1: Login Berhasil (Status 200)
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Ambil token dan data user dari JSON Laravel
        String token = responseData['data']['token'];
        Map<String, dynamic> user = responseData['data']['user'];

        // Simpan Token & Data User ke HP (Shared Preferences)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_data', json.encode(user));

        return {'success': true, 'data': user};
      }
      // Skenario 2: Salah Password/Email (401) atau Bukan Employee (403)
      else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Terjadi kesalahan',
        };
      }
    } catch (e) {
      // Skenario 3: Error Koneksi (Server mati / Internet putus)
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // Fungsi Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      final url = Uri.parse('$baseUrl/logout');
      try {
        await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      } catch (e) {
        print("Error logout API: $e");
      }
    }
    // Hapus data lokal
    await prefs.clear();
  }

  Future<Map<String, dynamic>> generateQrToken(double lat, double long) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/attendance/generate-token');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'latitude': lat, 'longitude': long}),
      );
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Error konesi: $e'};
    }
  }

  Future<Map<String, dynamic>> submitLeaveRequest({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
    File? attachment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/leave/store');

    try {
      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Authorization': ' Bearer $token',
        'Accept': ' application/json',
      });

      request.fields['type'] = type;
      request.fields['start_date'] = startDate;
      request.fields['end_date'] = endDate;
      request.fields['reason'] = reason;

      if (attachment != null) {
        request.files.add(
          await http.MultipartFile.fromPath('attachment', attachment.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var responseData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengajukan izin',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error koneksi: $e'};
    }
  }

  Future<Map<String, dynamic>> submitOvertime(String date, int duration) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/overtime');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json', // Wajib karena body kita JSON
        },
        body: json.encode({
          'date': date, // Format: YYYY-MM-DD
          'duration': duration, // Integer (jam)
        }),
      );

      final responseData = json.decode(response.body);

      // Status 201 Created (Berhasil)
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
        };
      }
      // Status 400 (Duplikat) atau 422 (Validasi Error)
      else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengajukan lembur',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error koneksi: $e'};
    }
  }

  // 2. Melihat Riwayat Lembur
  Future<Map<String, dynamic>> getOvertimeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/overtime/my-history');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'], // List of history
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memuat riwayat',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error koneksi: $e'};
    }
  }
}
