import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Jangan lupa add package intl
import 'package:intl/date_symbol_data_local.dart';

// Import pages Anda
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
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  // Data User & Kantor
  String _userName = "Loading...";
  String _position = "-";
  String _officeName = "-";

  // Data Shift & Status
  String _shiftName = "-";
  String _shiftStart = "--:--";
  String _shiftEnd = "--:--";
  String _statusLabel = "Memuat data...";
  String _clockIn = "--:--";
  String _clockOut = "--:--";

  // Warna Status (Default Biru)
  Color _statusColor = const Color(0xFF2980B9);
  Color _statusColorLight = const Color(0xFF2980B9).withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _fetchHomeData();
  }

  // Mengambil data lengkap dari API (sesuai backend sebelumnya)
  Future<void> _fetchHomeData() async {
    try {
      final response = await _apiService
          .getHomeData(); // Pastikan method ini ada di ApiService

      if (response['success'] == true) {
        final data = response['data'];

        setState(() {
          _userName = data['name'];
          _position = data['position'];
          _officeName = data['office'];
          _shiftName = data['shift_name'];
          _shiftStart = data['shift_start'] != null
              ? _formatTime(data['shift_start'])
              : "--:--";
          _shiftEnd = data['shift_end'] != null
              ? _formatTime(data['shift_end'])
              : "--:--";

          _statusLabel = data['status_label'];
          _clockIn = data['clock_in'] ?? "--:--";
          _clockOut = data['clock_out'] ?? "--:--";

          // Logika Warna Berdasarkan Status Backend
          String colorString =
              data['status_color']; // 'red', 'green', 'orange', 'blue'

          if (colorString == 'red') {
            // Sakit/Izin
            _statusColor = const Color(0xFFE74C3C);
            _statusColorLight = const Color(0xFFE74C3C).withOpacity(0.1);
          } else if (colorString == 'orange') {
            // Lembur
            _statusColor = const Color(0xFFF39C12);
            _statusColorLight = const Color(0xFFF39C12).withOpacity(0.1);
          } else if (colorString == 'green') {
            // Hadir
            _statusColor = const Color(0xFF27AE60);
            _statusColorLight = const Color(0xFF27AE60).withOpacity(0.1);
          } else {
            // Regular
            _statusColor = const Color(0xFF2980B9);
            _statusColorLight = const Color(0xFF2980B9).withOpacity(0.1);
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching home data: $e");
      // Fallback load local data jika API error
      _loadLocalUser();
      setState(() => _isLoading = false);
    }
  }

  // Helper format jam (08:00:00 -> 08:00)
  String _formatTime(String time) {
    try {
      if (time.length >= 5) return time.substring(0, 5);
      return time;
    } catch (e) {
      return time;
    }
  }

  Future<void> _loadLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userMap = json.decode(userDataString);
      setState(() {
        _userName = userMap['name'] ?? "Karyawan";
        _officeName = userMap['office'] ?? "-";
      });
    }
  }

  Future<void> _logout() async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Logout"),
            content: const Text("Yakin ingin keluar aplikasi?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Batal",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Ya, Keluar",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

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
    // Tanggal Hari Ini
    String dateNow = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Putih kebiruan sangat muda
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchHomeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HEADER SECTION
                    _buildHeader(dateNow),

                    // 2. MAIN STATUS CARD (INFO SHIFT & STATUS)
                    Transform.translate(
                      offset: const Offset(
                        0,
                        -40,
                      ), // Efek floating card menumpuk header
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildStatusCard(),
                      ),
                    ),

                    // 3. ABSENCE INFO (Jam Masuk/Keluar)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTimeCard(
                              "Jam Masuk",
                              _clockIn,
                              Icons.login,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildTimeCard(
                              "Jam Keluar",
                              _clockOut,
                              Icons.logout,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // 4. MENU GRID TITLE
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "Menu Layanan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // 5. MENU GRID
                    _buildMenuGrid(context),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // WIDGET: Header Gradient
  Widget _buildHeader(String dateNow) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 60,
        left: 24,
        right: 24,
        bottom: 60,
      ), // Bottom padding besar untuk space card
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _statusColor,
            _statusColor.withOpacity(0.7),
          ], // Warna menyesuaikan Status
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: const AssetImage(
                        'assets/profile_placeholder.png',
                      ), // Ganti image
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _position,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: _logout,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            dateNow,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // WIDGET: Kartu Status Utama
  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Baris Atas: Status & Shift
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Status Saat Ini",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel.toUpperCase(),
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Jadwal Shift",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$_shiftStart - $_shiftEnd",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 25, thickness: 1, color: Color(0xFFF0F0F0)),

          // Baris Bawah: Lokasi Kantor
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Lokasi Kantor",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      _officeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET: Info Jam Kecil
  Widget _buildTimeCard(String title, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET: Menu Grid
  Widget _buildMenuGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4, // 4 Kolom agar ikon lebih compact
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 0.8,
        children: [
          _buildMenuItem(
            icon: Icons.qr_code_scanner,
            label: "Absen",
            color: Colors.blueAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AbsenPage()),
            ),
          ),
          _buildMenuItem(
            icon: Icons.assignment_turned_in,
            label: "Izin",
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IzinPage()),
            ),
          ),
          _buildMenuItem(
            icon: Icons.access_time_filled,
            label: "Lembur",
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OvertimePage()),
            ),
          ),
          _buildMenuItem(
            icon: Icons.history,
            label: "Riwayat",
            color: Colors.purple,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Fitur Coming Soon")),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
