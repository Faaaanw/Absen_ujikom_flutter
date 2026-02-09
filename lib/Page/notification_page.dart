import 'package:flutter/material.dart';
import 'package:qr_absen/services/api_service.dart'; // Sesuaikan import

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ApiService _apiService = ApiService();

  // Fungsi untuk mendapatkan warna status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'disetujui':
        return Colors.green;
      case 'rejected':
      case 'ditolak':
        return Colors.red;
      case 'pending':
      case 'menunggu':
      default:
        return Colors.orange;
    }
  }

  // Fungsi untuk menerjemahkan status ke Bahasa Indonesia (Opsional)
  String _translateStatus(String status) {
    if (status.toLowerCase() == 'approved') return 'Disetujui';
    if (status.toLowerCase() == 'rejected') return 'Ditolak';
    return 'Menunggu';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Ada 2 Tab: Cuti & Lembur
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Status Pengajuan"),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: "Cuti"),
              Tab(icon: Icon(Icons.access_time), text: "Lembur"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: LIST CUTI
            _buildLeaveList(),
            
            // TAB 2: LIST LEMBUR
            _buildOvertimeList(),
          ],
        ),
      ),
    );
  }

  // Widget untuk Menampilkan List Cuti
  Widget _buildLeaveList() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _apiService.getLeaveHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data?['success'] == false) {
          return Center(child: Text(snapshot.data?['message'] ?? "Gagal memuat data"));
        }

        final List listCuti = snapshot.data?['data'] ?? [];

        if (listCuti.isEmpty) {
          return const Center(child: Text("Belum ada riwayat pengajuan cuti"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: listCuti.length,
          itemBuilder: (context, index) {
            final item = listCuti[index];
            final status = item['status'] ?? 'pending';

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  child: Icon(
                    status == 'approved' ? Icons.check : Icons.access_time,
                    color: _getStatusColor(status),
                  ),
                ),
                title: Text(
                  "${item['type'] ?? 'Izin'} (${_translateStatus(status)})",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tanggal: ${item['start_date']} s/d ${item['end_date']}"),
                    Text("Alasan: ${item['reason'] ?? '-'}", maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _translateStatus(status),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Widget untuk Menampilkan List Lembur
  Widget _buildOvertimeList() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _apiService.getOvertimeHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data?['success'] == false) {
          return Center(child: Text(snapshot.data?['message'] ?? "Gagal memuat data"));
        }

        final List listLembur = snapshot.data?['data'] ?? [];

        if (listLembur.isEmpty) {
          return const Center(child: Text("Belum ada riwayat lembur"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: listLembur.length,
          itemBuilder: (context, index) {
            final item = listLembur[index];
            final status = item['status'] ?? 'pending'; // Pastikan backend kirim status

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  child: Icon(Icons.timer, color: _getStatusColor(status)),
                ),
                title: Text(
                  "Lembur: ${item['duration']} Jam",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Tanggal: ${item['date']}"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _translateStatus(status),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}