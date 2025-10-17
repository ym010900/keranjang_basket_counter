import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fish Basket Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: const BasketApp(),
    );
  }
}

class BasketApp extends StatefulWidget {
  const BasketApp({super.key});

  @override
  State<BasketApp> createState() => _BasketAppState();
}

class _BasketAppState extends State<BasketApp> {
  late dynamic _objectModel;
  bool _modelLoaded = false;
  bool _isProcessing = false;
  int _basketCount = 0;
  XFile? _image;
  String _inferenceTime = "-";
  List<dynamic> _results = [];

  // Threshold confidence
  final double confidenceThreshold = 0.6;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      debugPrint("🔄 Loading model...");
      _objectModel = await PytorchLite.loadObjectDetectionModel(
        "assets/models/best.torchscript.pt",
        1,
        640,
        640,
        labelPath: "assets/labels.txt",
      );
      setState(() => _modelLoaded = true);
      debugPrint("✅ Model loaded successfully");
    } catch (e) {
      debugPrint("❌ Failed to load model: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    setState(() {
      _image = picked;
      _basketCount = 0;
      _inferenceTime = "-";
      _results = [];
    });

    final bytes = await picked.readAsBytes();
    final resized = await _resizeImage(bytes, 640, 640);

    await _runModelOnImage(resized);
  }

  Future<Uint8List> _resizeImage(Uint8List bytes, int width, int height) async {
    final original = img.decodeImage(bytes)!;
    final resized = img.copyResize(original, width: width, height: height);
    return Uint8List.fromList(img.encodeJpg(resized));
  }

  Future<void> _runModelOnImage(Uint8List bytes) async {
    if (!_modelLoaded) return;

    setState(() => _isProcessing = true);
    final start = DateTime.now();

    try {
      final result = await _objectModel.getImagePrediction(
        bytes,
        minimumScore: confidenceThreshold,
      );

      // Filter hasil dengan confidence threshold
      _results = result
          .where((r) => (r['confidence'] ?? 0.0) >= confidenceThreshold)
          .toList();

      final end = DateTime.now();
      final duration = end.difference(start).inMilliseconds;

      setState(() {
        _basketCount = _results.length;
        _isProcessing = false;
        _inferenceTime = "$duration ms";
      });

      debugPrint("✅ Detected $_basketCount basket(s) in $_inferenceTime");
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint("❌ Error during detection: $e");
    }
  }

  void _reset() {
    setState(() {
      _image = null;
      _basketCount = 0;
      _inferenceTime = "-";
      _results = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Fish Basket Counter",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Banner ilustrasi pelabuhan + ikan
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.blue[200]!, Colors.blue[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: const DecorationImage(
                  image: AssetImage("assets/images/port_banner.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Text(
                  "Selamat Datang di Fish Basket!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    shadows: const [
                      Shadow(
                        blurRadius: 3,
                        color: Colors.white,
                        offset: Offset(1, 1),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Aplikasi ini menggunakan AI (PyTorch Mobile) untuk mendeteksi jumlah keranjang ikan secara offline.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Gambar input
            _image == null
                ? Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Belum ada gambar",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
                : Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_image!.path)),
                ),
                const SizedBox(height: 16),
                _isProcessing
                    ? const CircularProgressIndicator(color: Colors.blue)
                    : Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final bytes = await _image!.readAsBytes();
                        final resized =
                        await _resizeImage(bytes, 640, 640);
                        await _runModelOnImage(resized);
                      },
                      icon: const Icon(Icons.search,
                          color: Colors.white),
                      label: const Text(
                        "Deteksi Keranjang",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                      ),
                    ),
                    TextButton(
                      onPressed: _reset,
                      child: Text(
                        "Reset",
                        style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "⏱ Waktu inferensi: $_inferenceTime",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    // Selalu tampilkan jumlah keranjang
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          "🧺 $_basketCount keranjang ikan terdeteksi!",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.blue),
            const SizedBox(height: 10),
            const Text(
              "Ambil Gambar dari:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    "Kamera",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo, color: Colors.white),
                  label: const Text(
                    "Galeri",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Footer info pelabuhan
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: const [
                  Icon(Icons.anchor, color: Colors.blue, size: 30),
                  SizedBox(height: 8),
                  Text(
                    "Ikan Bergizi dan Belimpah",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Jaga kebersihan dan kualitas ikan tetap terjaga.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
