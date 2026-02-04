import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_absen/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class IzinPage extends StatefulWidget {
  const IzinPage({super.key});

  @override
  State<IzinPage> createState() => _IzinPageState();
}

class _IzinPageState extends State<IzinPage> {
  final _formkey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  String? _selectedType;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  File? _attachment;
  bool _isLoading = false;

  // --- Style Helper ---
  final InputDecoration _inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.blue, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _pickAttachmentFile() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _attachment = File(pickedFile.path));
    }
  }

  void _submit() async {
    if (!_formkey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result = await _apiService.submitLeaveRequest(
      type: _selectedType!,
      startDate: _startDateController.text,
      endDate: _endDateController.text,
      reason: _reasonController.text,
      attachment: _attachment,
    );
    setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Pengajuan Izin", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formkey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Jenis Izin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: _inputDecoration,
                dropdownColor: Colors.white,
                items: ['sakit', 'izin', 'cuti'].map((String val) {
                  return DropdownMenuItem(value: val, child: Text(val.toUpperCase()));
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val),
                validator: (val) => val == null ? 'Pilih tipe izin' : null,
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Mulai", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _startDateController,
                          decoration: _inputDecoration.copyWith(suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20)),
                          readOnly: true,
                          onTap: () => _selectDate(context, _startDateController),
                          validator: (val) => val!.isEmpty ? 'Wajib' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Selesai", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _endDateController,
                          decoration: _inputDecoration.copyWith(suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20)),
                          readOnly: true,
                          onTap: () => _selectDate(context, _endDateController),
                          validator: (val) => val!.isEmpty ? 'Wajib' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text("Alasan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: _inputDecoration.copyWith(hintText: "Jelaskan alasan pengajuan..."),
                maxLines: 4,
                validator: (val) => val!.isEmpty ? 'Isi alasan' : null,
              ),

              const SizedBox(height: 20),
              const Text("Bukti Pendukung", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickAttachmentFile,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: _attachment == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.blue),
                            SizedBox(height: 10),
                            Text("Ketuk untuk upload foto", style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_attachment!, fit: BoxFit.cover, width: double.infinity),
                        ),
                ),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    shadowColor: Colors.blue.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("KIRIM PENGAJUAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}