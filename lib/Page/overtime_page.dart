import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OvertimePage extends StatefulWidget {
  const OvertimePage({super.key});

  @override
  State<OvertimePage> createState() => _OvertimePageState();
}

class _OvertimePageState extends State<OvertimePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Style input konsisten dengan halaman lain
  final InputDecoration _inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.purple, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.purple),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      String formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() => _dateController.text = formattedDate);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _apiService.submitOvertime(
      _dateController.text,
      int.parse(_durationController.text),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Pengajuan Lembur", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.purple),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Pastikan Anda telah mendapatkan persetujuan atasan sebelum mengisi form lembur.",
                        style: TextStyle(color: Colors.purple, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              const Text("Tanggal Lembur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: _inputDecoration.copyWith(
                  hintText: "Pilih Tanggal",
                  suffixIcon: const Icon(Icons.calendar_month, color: Colors.purple),
                ),
                onTap: _pickDate,
                validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
              ),

              const SizedBox(height: 20),
              const Text("Durasi (Jam)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration.copyWith(
                  hintText: "Contoh: 2",
                  suffixIcon: const Icon(Icons.timer_outlined, color: Colors.purple),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wajib diisi';
                  if (int.tryParse(val) == null) return 'Harus angka';
                  return null;
                },
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    shadowColor: Colors.purple.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("AJUKAN LEMBUR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}