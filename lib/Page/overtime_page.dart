import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Sesuaikan path jika berbeda

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

  @override
  void dispose() {
    _dateController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih tanggal
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      // Format manual ke YYYY-MM-DD agar tidak perlu package intl
      String formattedDate = 
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      
      setState(() {
        _dateController.text = formattedDate;
      });
    }
  }

  // Fungsi Submit
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String date = _dateController.text;
    int duration = int.parse(_durationController.text);

    final result = await _apiService.submitOvertime(date, duration);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']), 
          backgroundColor: Colors.green
        ),
      );
      Navigator.pop(context); // Kembali ke dashboard setelah sukses
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengajuan Lembur"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Formulir Lembur",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "Isi data lembur dengan benar.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 25),

              // INPUT TANGGAL
              TextFormField(
                controller: _dateController,
                readOnly: true, // Tidak bisa diketik manual
                decoration: const InputDecoration(
                  labelText: "Tanggal Lembur",
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                onTap: _pickDate, // Buka kalender saat diklik
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // INPUT DURASI
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Durasi (Jam)",
                  prefixIcon: Icon(Icons.timer),
                  border: OutlineInputBorder(),
                  hintText: "Contoh: 2",
                  suffixText: "Jam"
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Durasi wajib diisi';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Harus berupa angka bulat';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // TOMBOL SUBMIT
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple, // Warna pembeda
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Kirim Pengajuan",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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