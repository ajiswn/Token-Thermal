import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pln_thermal_printer/manual_input_page.dart';
import 'package:pln_thermal_printer/model/pln_transaction.dart';
import 'package:pln_thermal_printer/services/printer_pref.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'services/ocr_service.dart';
import 'services/parser_service.dart';
import 'services/print_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

// void main() {
//   runApp(const MyApp());
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFEDEDED)),
        )
      ),
      home: HomePage()
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<BluetoothInfo> printers = [];
  String? savedPrinter;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await requestPermissions();
    savedPrinter = await PrinterPref.load();

    if (savedPrinter == null) {
      printers = await PrintBluetoothThermal.pairedBluetooths;
    }

    setState(() => loading = false);
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> selectPrinter(BluetoothInfo p) async {
    await PrinterPref.save(p.macAdress);
    setState(() => savedPrinter = p.macAdress);
  }

  Future<void> importImage() async {

    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    final text = await OcrService.scan(File(img.path));
    final trx = ParserService.parse(text);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewPage(
          trx: trx,
          image: File(img.path),
          printerMac: savedPrinter!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// BELUM PILIH PRINTER
    if (savedPrinter == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Pilih Printer"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: ListView.builder(
          itemCount: printers.length,
          itemBuilder: (_, i) {
            final p = printers[i];
            return ListTile(
              title: Text(p.name, style: TextStyle(color: Colors.white)),
              subtitle: Text(p.macAdress, style: TextStyle(color: Colors.grey)),
              onTap: () => selectPrinter(p),
            );
          },
        ),
      );
    }

    /// SUDAH PILIH PRINTER → HALAMAN UTAMA
    return Scaffold(
      appBar: AppBar(
        title: const Text("PLN Thermal Printer"),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text("Import Screenshot", style: TextStyle(fontSize: 16)),
                onPressed: importImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  minimumSize: Size(0, 48)
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_note),
                label: const Text("Input Manual", style: TextStyle(fontSize: 16)),
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => ManualInputPage(printerMac: savedPrinter!),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  minimumSize: Size(0, 48)
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }
}

class ReviewPage extends StatelessWidget {

  final PlnTransaction trx;
  final File? image;
  final String printerMac;

  const ReviewPage({
    super.key,
    required this.trx,
    this.image,
    required this.printerMac,
  });

  Future<void> printNow() async {
    await PrintBluetoothThermal.connect(macPrinterAddress: printerMac);
    await PrintService.print(trx);
  }

  @override
  Widget build(BuildContext context) {

    final tokenLines = ParserService.splitToken(trx.token);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Struk"),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [

            if (image != null) ...[
              Image.file(image!, height: 200),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ID PLN     : ${trx.idPln}"),
                Text("Nama       : ${trx.nama}"),
                Text("Tarif/Daya : ${trx.tarifDaya}"),
                Text("Nominal    : ${trx.nominal}"),
              ],
            ),

            const SizedBox(height: 20),
            Text("Nomor Token", textAlign: TextAlign.center,),
            Text(tokenLines[0], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(tokenLines[1], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text("Print"),
                    onPressed: printNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      minimumSize: Size(0, 48)
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}