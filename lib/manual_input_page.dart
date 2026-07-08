import 'package:flutter/material.dart';
import 'model/pln_transaction.dart';
import 'services/api_service.dart';
import 'main.dart';

class ManualInputPage extends StatefulWidget {
  final String printerMac;
  const ManualInputPage({super.key, required this.printerMac});

  @override
  State<ManualInputPage> createState() => _ManualInputPageState();
}

class _ManualInputPageState extends State<ManualInputPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _idController = TextEditingController();
  final _customNominalController = TextEditingController();
  final _tokenController = TextEditingController();
  final _manualCustomerDataController = TextEditingController();

  String _namaFetched = '';
  String _tarifFetched = '';
  bool _isFetchingApi = false;
  bool _isApiFailed = false;

  // Variabel untuk mengontrol pilihan Radio Button Nominal
  String? _selectedNominal = '20.000'; // Default terpilih 20.000

  Future<void> _checkIdPln() async {
    if (_idController.text.trim().isEmpty) return;

    setState(() {
      _isFetchingApi = true;
      _namaFetched = '';
      _tarifFetched = '';
      _isApiFailed = false;
    });

    final result = await ApiService.checkPlnCustomer(_idController.text.trim());

    setState(() {
      _isFetchingApi = false;
      if (result != null) {
        _namaFetched = result['nama']!;
        _tarifFetched = result['tarifDaya']!;
        _isApiFailed = false;
      } else {
        _isApiFailed = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ID Pelanggan tidak ditemukan atau API Error")),
        );
      }
    });
  }

  void _submitData() {
    if (!_formKey.currentState!.validate()) return;
    if (_isApiFailed) {
      // Jika menggunakan jalur manual, pecah string berdasarkan "/"
      final rawInput = _manualCustomerDataController.text.trim();
      final parts = rawInput.split('/');
      
      if (parts.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Format input manual salah. Gunakan format NAMA/TARIF/DAYA")),
        );
        return;
      }
      
      _namaFetched = parts[0].trim();
      // Menggabungkan sisa bagian (Tarif dan Daya) menjadi satu string, misal: "B1/1300"
      _tarifFetched = parts.sublist(1).join('/').trim();
    } else {
      // Jika jalur API biasa
      if (_namaFetched.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Silakan periksa ID Pelanggan terlebih dahulu")),
        );
        return;
      }
    }

    // Menentukan nominal yang diambil berdasarkan pilihan radio button
    String finalNominal = '';
    if (_selectedNominal == 'lainnya') {
      finalNominal = "Rp ${_customNominalController.text.trim()}";
    } else {
      finalNominal = "Rp $_selectedNominal";
    }

    final trx = PlnTransaction(
      idPln: _idController.text.trim(),
      nama: _namaFetched,
      tarifDaya: _tarifFetched,
      nominal: finalNominal,
      token: _tokenController.text.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewPage(
          trx: trx,
          printerMac: widget.printerMac,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tema warna Material 3 bergaya Dark Mode
    final double borderRadius = 12.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Manual Struk"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              // 1. INPUT ID PELANGGAN (Material 3 Style)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _idController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: 'ID Pelanggan / No. Meter',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.electric_bolt),
                        prefixIconColor: WidgetStateColor.resolveWith((states) {
                          if(states.contains(WidgetState.focused)) {
                            return Colors.white;
                          }
                          return Colors.grey;
                        }),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: const BorderSide(color: Colors.white),
                        )
                      ),
                      validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56, // Menyesuaikan tinggi dengan M3 TextField
                    child: FilledButton(
                      onPressed: _isFetchingApi ? null : _checkIdPln,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                      ),
                      child: _isFetchingApi 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.search, size: 20,),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // TAMPILKAN HASIL RESEP API (NAMA & TARIF)
              if (_namaFetched.isNotEmpty && !_isApiFailed) ...[
                Card(
                  margin: EdgeInsets.zero,
                  color: Color(0xFF121212),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    side: BorderSide(color: Colors.grey)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Nama Pelanggan: $_namaFetched", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text("Tarif/Daya: $_tarifFetched", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // TAMPILKAN FIELD INPUT MANUAL (JIKA API GAGAL)
              if (_isApiFailed) ...[
                TextFormField(
                  controller: _manualCustomerDataController,
                  textCapitalization: TextCapitalization.characters, // Otomatis CAPS LOCK
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Format: NAMA/TARIF/DAYA',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.edit_note),
                    prefixIconColor: WidgetStateColor.resolveWith((states) {
                      if(states.contains(WidgetState.focused)) {
                        return Colors.white;
                      }
                      return Colors.grey;
                    }),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(color: Colors.white),
                    )
                  ),
                  validator: (v) {
                    if (_isApiFailed && (v == null || v.isEmpty)) {
                      return 'Data manual wajib diisi';
                    }
                    if (_isApiFailed && !v!.contains('/')) {
                      return 'Gunakan tanda garing (/) sebagai pemisah';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // 2. SELEKSI NOMINAL (Radio Button Segment)
              const Text("Pilih Nominal", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              Card(
                margin: EdgeInsets.all(0),
                color: Color(0xFF121212),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius), 
                  side: const BorderSide(color: Colors.grey, width: 0.5)
                ),
                child: RadioGroup<String>(
                  groupValue: _selectedNominal,
                  onChanged: (v) => setState(() => _selectedNominal = v),
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        title: Text("Rp 20.000", style: TextStyle(color: Colors.white)),
                        value: '20.000',
                        activeColor: Colors.white,
                      ),
                      RadioListTile<String>(
                        title: Text("Rp 50.000", style: TextStyle(color: Colors.white)),
                        value: '50.000',
                        activeColor: Colors.white,
                      ),
                      RadioListTile<String>(
                        title: Text("Rp 100.000", style: TextStyle(color: Colors.white)),
                        value: '100.000',
                        activeColor: Colors.white,
                      ),
                      RadioListTile<String>(
                        title: Text("Lainnya", style: TextStyle(color: Colors.white)),
                        value: 'lainnya',
                        activeColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // TEXTFIELD TAMBAHAN JIKA PILIH "LAINNYA" (Material 3 Style)
              if (_selectedNominal == 'lainnya') ...[
                TextFormField(
                  controller: _customNominalController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Masukkan Nominal (Ex: 150.000)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (v) => (_selectedNominal == 'lainnya' && v!.isEmpty) ? 'Masukkan nominal angka manual' : null,
                ),
                const SizedBox(height: 16),
              ],

              // 3. INPUT TOKEN (Material 3 Style)
              TextFormField(
                controller: _tokenController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Token Listrik',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.key),
                  prefixIconColor: WidgetStateColor.resolveWith((states) {
                    if(states.contains(WidgetState.focused)) {
                      return Colors.white;
                    }
                    return Colors.grey;
                  }),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: const BorderSide(color: Colors.white),
                  )
                ),
                validator: (v) => v!.length < 20 ? 'Token harus berisikan 20 digit angka' : null,
              ),
              const SizedBox(height: 40),

              // TOMBOL SELESAI / PREVIEW
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _submitData,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Preview Struk", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
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