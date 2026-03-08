import '../model/pln_transaction.dart';

class ParserService {

  static List<String> _lines(String text) =>
      text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  /// cari angka panjang (ID PLN / Meter)
  static String _findLongNumber(List<String> lines, int start) {
    for (int i = start; i < lines.length; i++) {
      if (RegExp(r'^\d{8,}$').hasMatch(lines[i])) {
        return lines[i];
      }
    }
    return '';
  }

  /// cari nama (mengandung huruf / *)
  static String _findName(List<String> lines, int start) {
    final forbidden = [
      'tarif',
      'token',
      'nomor',
      'meter',
      'pelanggan',
      'listrik',
      'nominal',
      'informasi',
      'pembayaran',
      'pesanan',
      'biaya',
      'total',
      'kb',
      'salin'
    ];

    for (int i = start; i < lines.length; i++) {
      final l = lines[i].toLowerCase();

      // harus mengandung huruf
      bool hasLetter = RegExp(r'[a-z\*]').hasMatch(l);

      // tidak boleh ada angka
      bool hasNumber = RegExp(r'\d').hasMatch(l);

      // tidak boleh mengandung kata label
      bool isForbidden = forbidden.any((f) => l.contains(f));

      if (hasLetter && !hasNumber && !isForbidden) {
        return lines[i];
      }
    }
    return '';
}

  /// cari tarif listrik
  static String _findTarif(List<String> lines, int start) {
    for (int i = start; i < lines.length; i++) {
      if (lines[i].contains('VA') || lines[i].contains('R1')) {
        return lines[i];
      }
    }
    return '';
  }

  /// cari nominal
  static String _findNominal(List<String> lines, int start) {
    for (int i = start; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains('token pln')) {
        return lines[i];
      }
    }
    return '';
  }

  /// Ambil token listrik (angka panjang)
  static String _extractToken(String text) {
    final regex = RegExp(r'(\d{4}\s\d{4}\s\d{4}\s\d{4}\s\d{4})');
    final match = regex.firstMatch(text);
    return match != null ? match.group(0)! : '';
  }

  static PlnTransaction parse(String text) {

    final lines = _lines(text);

    int idxId = lines.indexWhere((l) => l.contains('No. Pelanggan'));
    int idxNama = lines.indexWhere((l) => l.contains('Nama Pelanggan'));
    int idxTarif = lines.indexWhere((l) => l.contains('Tarif Listrik'));
    int idxNominal = lines.indexWhere((l) => l.contains('Nominal'));

    return PlnTransaction(
      idPln: _findLongNumber(lines, idxId + 1),
      nama: _findName(lines, idxNama + 1),
      tarifDaya: _findTarif(lines, idxTarif + 1),
      nominal: _findNominal(lines, idxNominal + 1),
      token: _extractToken(text),
    );
  }

  /// Token tetap dipisah per 4 angka
  static List<String> splitToken(String token) {

    String clean = token.replaceAll(RegExp(r'[^0-9]'), '');

    List<String> groups = [];
    for (int i = 0; i < clean.length; i += 4) {
      groups.add(clean.substring(i, i + 4 > clean.length ? clean.length : i + 4));
    }

    /// gabungkan kembali dengan spasi tiap 4 angka
    String spaced = groups.join(' ');

    /// split jadi 2 baris
    List<String> parts = spaced.split(' ');

    String line1 = parts.take(3).join(' '); // 12 digit pertama
    String line2 = parts.skip(3).join(' ');

    return [line1, line2];
  }
}