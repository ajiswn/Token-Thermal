import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://cek-id-pln-pasca-dan-pra-bayar.p.rapidapi.com';
  static String get _apiKey => dotenv.env['RAPID_API_KEY'] ?? '';
  static const String _apiHost = 'cek-id-pln-pasca-dan-pra-bayar.p.rapidapi.com';

  /// Fungsi untuk mengambil data pelanggan PLN berdasarkan ID
  static Future<Map<String, String>?> checkPlnCustomer(String idPelanggan) async {
    // Memasukkan idPelanggan ke dalam path URL sesuai dokumentasi
    final url = Uri.parse('$_baseUrl/pln/$idPelanggan/token_pln'); 

    try {
      final response = await http.get(
        url,
        headers: {
          'x-rapidapi-key': _apiKey,
          'x-rapidapi-host': _apiHost,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Memastikan properti 'success' bernilai true dan data tidak null
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          
          return {
            'nama': data['subscriber_name'] ?? 'Tidak Diketahui',
            'tarifDaya': data['segment_power'] ?? 'Tidak Diketahui',
          };
        } else {
          print("API Gagal: ${responseData['message'] ?? 'Status success false'}");
          return null;
        }
      } else {
        print("Server Error HTTP Status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error koneksi ApiService: $e");
      return null;
    }
  }
}