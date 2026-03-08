import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../model/pln_transaction.dart';
import 'parser_service.dart';

class PrintService {

  static Future<void> print(PlnTransaction trx) async {

    String nowFormatted() {
      final now = DateTime.now();

      String two(int n) => n.toString().padLeft(2, '0');

      return "${two(now.day)}/${two(now.month)}/${now.year} "
            "${two(now.hour)}:${two(now.minute)}";
    }

    bool connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected) return;

    List<int> bytes = [];

    bytes += [0x1B, 0x40];  
    bytes += [0x1B, 0x33, 0x00]; 

    void normal() => bytes += [0x1B, 0x21, 0x00];
    void boldOn() => bytes += [0x1B, 0x45, 0x01];
    void boldOff() => bytes += [0x1B, 0x45, 0x00];
    void big() => bytes += [0x1D, 0x21, 0x11];
    void center() => bytes += [0x1B, 0x61, 0x01];
    void left() => bytes += [0x1B, 0x61, 0x00];

    void text(String s) => bytes += s.codeUnits;
    void line() => bytes += "\n".codeUnits;

    left();
    normal();
    text("Jwanz Cell\n");
    text("${nowFormatted()}\n");
    line();
    center();
    boldOn();
    text("STRUK TOKEN LISTRIK\n");
    boldOff();
    line();

    left();
    normal();

    text("ID PLN     : ${trx.idPln}\n");
    text("NAMA       : ${trx.nama}\n");
    text("TARIF/DAYA : ${trx.tarifDaya}\n");
    text("NOMINAL    : ${trx.nominal}\n");

    line();
    center();
    text("NOMOR TOKEN\n");
    line();

    final tokenLines = ParserService.splitToken(trx.token);

    big();
    boldOn();
    text("${tokenLines[0]}\n");
    text("${tokenLines[1]}\n");
    boldOff();

    normal();
    line();
    line();
    line();

    await PrintBluetoothThermal.writeBytes(bytes);
  }
}