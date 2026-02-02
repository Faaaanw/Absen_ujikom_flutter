import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _qrToken;
  
  // Variabel untuk UI status
  String _statusText = "Memuat status...";
  String _buttonText = "Generate QR Code";
  Color _buttonColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _checkStatus(); // Cek status saat halaman dibuka
  }

  // Fungsi tambahan untuk cek status (Opsional, perlu endpoint di Laravel)
  // Jika tidak punya endpoint khusus, logika backend di atas sudah cukup memblokir.
  // Di sini saya buat simulasi sederhana agar tombol berubah teks.
  Future<void> _checkStatus() async {
    // Idealnya panggil API: GET /attendance/today-status
    // Tapi karena codingan API Service belum ada fungsi itu, 
    // kita set default dulu. Status sebenarnya ditentukan saat klik tombol.
    setState(() {
      _statusText = "Silakan Generate QR untuk Absen";
      _buttonText = "Generate QR Absensi";
    });
  }

  Future<void> _generateAttendanceQr() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Cek Service GPS
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('GPS tidak aktif. Silakan aktifkan GPS.');
      setState(() => _isLoading = false);
      return;
    }

    // 2. Cek Izin Lokasi
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Izin lokasi ditolak.');
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      // 3. Ambil Posisi
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4. Panggil API (Laravel akan melakukan validasi Jam Pulang di sini)
      final result = await _apiService.generateQrToken(
        position.latitude,
        position.longitude,
      );
      
      if (result['success']) {
        setState(() {
          _qrToken = result['token'];
        });

        if (!mounted) return;
        
        // Ambil pesan dari backend ("QR Code Keluar" atau "Masuk")
        String message = result['message'] ?? 'QR Code berhasil dibuat';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );

        _showQrDialogue(message); // Tampilkan QR
      } else {
        // INI AKAN MENANGKAP ERROR DARI LARAVEL (Misal: "Belum waktunya pulang")
        _showError(result['message'] ?? 'Gagal generate QR.');
      }
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Peringatan'),
        content: Text(message), // Pesan error dari Laravel muncul disini
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showQrDialogue(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: QrImageView(
                  data: _qrToken!,
                  version: QrVersions.auto,
                  size: 220.0,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tunjukkan ke scanner kantor.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
               const Text(
                'Token berlaku 2 menit.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _qrToken = null);
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Status
              Icon(
                Icons.qr_code_scanner, 
                size: 100, 
                color: Theme.of(context).primaryColor
              ),
              const SizedBox(height: 24),
              
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              
              const SizedBox(height: 32),
              
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _generateAttendanceQr,
                        icon: const Icon(Icons.qr_code),
                        label: Text(_buttonText),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _buttonColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}