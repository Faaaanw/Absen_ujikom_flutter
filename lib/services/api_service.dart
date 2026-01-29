import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // GANTI dengan IP Laptop/Komputer kamu.
  // Jangan pakai localhost untuk Android Emulator (gunakan 10.0.2.2) atau Real Device (IP LAN).
  final String baseUrl = 'http://192.168.0.146:8000/api';

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
}
