import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Import QR Flutter
import '../services/api_service.dart';
import 'login_page.dart'; // Untuk navigasi logout

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _qrToken;
  int _expiresIn = 0;

  Future<void> _generateAttendanceQr() async {
    setState(() {
      _isLoading = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('GPS tidak aktif. Silakan aktifkan GPS untuk melanjutkan.');
      setState(() => _isLoading = false);
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError(
          'Izin lokasi ditolak. Silakan izinkan akses lokasi untuk melanjutkan.',
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final result = await _apiService.generateQrToken(
        position.latitude,
        position.longitude,
      );
      
      if (result['success']) {
        setState(() {
          _qrToken = result['token'];
          _expiresIn = result['expires_in'] ?? 60;
        });

        if (!mounted) return;

        // 1. Tampilkan Notifikasi Berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR Code Absensi berhasil dibuat'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // 2. TAMPILKAN POPUP GAMBAR QR (Ini yang sebelumnya kurang)
        _showQrDialogue(); // <--- TAMBAHKAN BARIS INI

      } else {
        _showError(result['message'] ?? 'Gagal menghasilkan QR Code.');
      }
    } catch (e) {
      _showError('Gagal mendapatkan lokasi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showQrDialogue() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('QR Code Absensi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: _qrToken!,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Tunjukkan QR Code ini untuk absensi.'),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => {_qrToken = null});
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
      appBar: AppBar(
        title: const Text('Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (ctx) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, size: 100, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Selamat datang di aplikasi absensi QR Code!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _generateAttendanceQr,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Generate QR Code Absensi'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
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
