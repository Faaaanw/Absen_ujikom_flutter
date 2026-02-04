import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'absen_page.dart';
import 'izin_page.dart';
import 'overtime_page.dart';
import 'login_page.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = "User";
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userMap = json.decode(userDataString);
      setState(() {
        _userName = userMap['name'] ?? "Karyawan";
      });
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Ya, Keluar")),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _apiService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Latar belakang abu-abu sangat muda
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER CUSTOM ---
            Container(
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2980B9), Color(0xFF6DD5FA)], // Gradasi Biru
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: const Icon(Icons.person, size: 32, color: Color(0xFF2980B9)),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Selamat Datang,",
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              Text(
                                _userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                        tooltip: "Logout",
                      )
                    ],
                  ),
                ],
              ),
            ),

            // --- MENU GRID ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Menu Utama",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1, // Membuat kartu sedikit lebih lebar
                    children: [
                      _buildMenuCard(
                        icon: Icons.qr_code_scanner,
                        title: "Absensi QR",
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsenPage())),
                      ),
                      _buildMenuCard(
                        icon: Icons.assignment_turned_in_rounded,
                        title: "Izin / Cuti",
                        color: Colors.green,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IzinPage())),
                      ),
                      _buildMenuCard(
                        icon: Icons.access_time_filled,
                        title: "Lembur",
                        color: Colors.purple,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OvertimePage())),
                      ),
                      _buildMenuCard(
                        icon: Icons.history_rounded,
                        title: "Riwayat",
                        color: Colors.blue,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Coming Soon")));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}