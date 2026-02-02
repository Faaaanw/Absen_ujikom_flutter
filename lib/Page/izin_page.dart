import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_absen/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // P

class IzinPage extends StatefulWidget {
  const IzinPage({super.key});

  @override
  State<IzinPage> createState() => _IzinPageState();
}

class _IzinPageState extends State<IzinPage> {
  final _formkey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  String? _selectedType;
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();
  TextEditingController _reasonController = TextEditingController();
  File? _attachment;

  bool _isLoading = false;

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      controller.text = formattedDate;
    }
  }

  Future<void> _pickAttachmentFile() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _attachment = File(pickedFile.path);
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Kembali ke halaman sebelumnya
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pengajuan Izin")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formkey,
          child: ListView(
            children: [
              // 1. Dropdown Tipe
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(labelText: 'Tipe Izin'),
                items: ['sakit', 'izin', 'cuti'].map((String val) {
                  return DropdownMenuItem(value: val, child: Text(val.toUpperCase()));
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val),
                validator: (val) => val == null ? 'Pilih tipe izin' : null,
              ),
              SizedBox(height: 16),

              // 2. Start Date
              TextFormField(
                controller: _startDateController,
                decoration: InputDecoration(
                  labelText: 'Tanggal Mulai',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, _startDateController),
                validator: (val) => val!.isEmpty ? 'Isi tanggal mulai' : null,
              ),
              SizedBox(height: 16),

              // 3. End Date
              TextFormField(
                controller: _endDateController,
                decoration: InputDecoration(
                  labelText: 'Tanggal Selesai',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, _endDateController),
                validator: (val) => val!.isEmpty ? 'Isi tanggal selesai' : null,
              ),
              SizedBox(height: 16),

              // 4. Alasan
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(labelText: 'Alasan'),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Isi alasan' : null,
              ),
              SizedBox(height: 16),

              // 5. Upload File
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickAttachmentFile,
                    icon: Icon(Icons.upload_file),
                    label: Text("Upload Bukti"),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _attachment != null ? "File terpilih" : "Tidak ada file (Opsional)",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              if (_attachment != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(_attachment!, height: 100, fit: BoxFit.cover),
                ),
              
              SizedBox(height: 24),

              // 6. Tombol Submit
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? CircularProgressIndicator(color: Colors.white) 
                  : Text("KIRIM PENGAJUAN"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
