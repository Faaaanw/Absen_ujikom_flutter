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

  // Color Palette
  final Color _primaryColor = const Color(0xFF2563EB); // Royal Blue
  final Color _backgroundColor = const Color(0xFFF3F4F6); // Light Grey

  String? _selectedType;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  File? _attachment;
  bool _isLoading = false;

  // --- Style Helper ---
  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade50,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.6), size: 22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: _primaryColor,
            colorScheme: ColorScheme.light(primary: _primaryColor),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
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

  void _removeAttachment() {
    setState(() => _attachment = null);
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

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(result['message'])),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message']),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Formulir Pengajuan",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Form(
          key: _formkey,
          child: Column(
            children: [
              // Bagian Card Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Jenis Izin"),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: _buildInputDecoration(
                        hint: "Pilih jenis izin",
                        icon: Icons.category_outlined,
                      ),
                      dropdownColor: Colors.white,
                      items: ['sakit', 'izin', 'cuti'].map((String val) {
                        return DropdownMenuItem(
                          value: val,
                          child: Text(
                            val.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedType = val),
                      validator: (val) => val == null ? 'Silakan pilih tipe izin' : null,
                    ),
                    const SizedBox(height: 20),

                    // Date Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Mulai"),
                              TextFormField(
                                controller: _startDateController,
                                decoration: _buildInputDecoration(
                                  hint: "Tgl Mulai",
                                  icon: Icons.calendar_month_outlined,
                                ),
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
                              _buildLabel("Selesai"),
                              TextFormField(
                                controller: _endDateController,
                                decoration: _buildInputDecoration(
                                  hint: "Tgl Selesai",
                                  icon: Icons.event_repeat_outlined,
                                ),
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

                    _buildLabel("Alasan"),
                    TextFormField(
                      controller: _reasonController,
                      decoration: _buildInputDecoration(
                        hint: "Jelaskan detail alasan...",
                        icon: Icons.edit_note_rounded,
                      ).copyWith(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      maxLines: 4,
                      validator: (val) => val!.isEmpty ? 'Mohon isi alasan' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bagian Upload (Terpisah agar terlihat menonjol)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Lampiran Bukti"),
                    GestureDetector(
                      onTap: _pickAttachmentFile,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _attachment == null ? const Color(0xFFF8FAFC) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _attachment == null ? Colors.blueGrey.shade100 : Colors.transparent,
                            width: 2,
                            style: _attachment == null ? BorderStyle.solid : BorderStyle.none, // Gunakan package dotted_border jika ingin garis putus2
                          ),
                        ),
                        child: _attachment == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.cloud_upload_rounded,
                                        size: 32, color: _primaryColor),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Ketuk untuk unggah foto",
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "Mendukung JPG, PNG",
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade300,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(_attachment!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: _removeAttachment,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)]),
                                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Tombol Submit
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: _isLoading
                          ? [Colors.grey, Colors.grey]
                          : [_primaryColor, const Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "KIRIM PENGAJUAN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.blueGrey.shade700,
        ),
      ),
    );
  }
}