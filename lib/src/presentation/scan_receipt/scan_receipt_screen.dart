import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:project/src/models/scanned_receipt.dart';
import 'package:project/src/services/receipt_service.dart';
import 'package:project/src/models/currency.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final _receiptService = ReceiptService();
  final _textRecognizer = TextRecognizer();
  final _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  
  bool _isProcessing = false;
  String? _imagePath;
  Map<String, dynamic>? _extractedData;
  
  // Form alanları için controller'lar
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Diğer';

  // Kategori listesi
  final List<String> _categories = [
    'Market',
    'Restoran',
    'Kafe',
    'Akaryakıt',
    'Giyim',
    'Diğer',
  ];

  Future<void> _takePicture() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
      );

      if (image == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${const Uuid().v4()}.jpg';
      final savedImage = File(path.join(appDir.path, fileName));
      await savedImage.writeAsBytes(await image.readAsBytes());

      setState(() {
        _imagePath = savedImage.path;
        _isProcessing = true;
      });

      await _processImage(savedImage);
    } catch (e) {
      print('Resim çekilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim çekilirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final extractedData = _extractReceiptData(recognizedText.text);
      
      setState(() {
        _extractedData = extractedData;
        // Form alanlarını OCR sonuçlarıyla doldur
        _merchantController.text = extractedData['merchantName'] ?? '';
        _amountController.text = extractedData['amount']?.toString() ?? '';
        if (extractedData['date'] != null) {
          _selectedDate = extractedData['date'];
        }
        if (extractedData['category'] != null) {
          _selectedCategory = extractedData['category'];
        }
      });

      // Firebase Storage'a yükle
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('receipts')
          .child('${const Uuid().v4()}.jpg');
      
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();

      // Faturayı veritabanına kaydet
      final receipt = ScannedReceipt(
        id: const Uuid().v4(),
        imagePath: downloadUrl,
        merchantName: extractedData['merchantName'] ?? 'Bilinmeyen',
        amount: extractedData['amount'] ?? 0.0,
        currency: Currency.try_,
        date: extractedData['date'] ?? DateTime.now(),
        category: extractedData['category'] ?? 'Diğer',
        rawData: extractedData,
      );

      await _receiptService.addScannedReceipt(receipt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fatura başarıyla işlendi')),
        );
      }
    } catch (e) {
      print('Resim işlenirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim işlenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _saveManualEntry() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isProcessing = true);

      String? imageUrl;
      if (_imagePath != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('receipts')
            .child('${const Uuid().v4()}.jpg');
        
        await storageRef.putFile(File(_imagePath!));
        imageUrl = await storageRef.getDownloadURL();
      }

      final receipt = ScannedReceipt(
        id: const Uuid().v4(),
        imagePath: imageUrl ?? '',
        merchantName: _merchantController.text,
        amount: double.parse(_amountController.text),
        currency: Currency.try_,
        date: _selectedDate,
        category: _selectedCategory,
        rawData: {
          'merchantName': _merchantController.text,
          'amount': double.parse(_amountController.text),
          'date': _selectedDate.toIso8601String(),
          'category': _selectedCategory,
        },
      );

      await _receiptService.addScannedReceipt(receipt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harcama başarıyla kaydedildi')),
        );
        // Form alanlarını temizle
        _merchantController.clear();
        _amountController.clear();
        setState(() {
          _selectedDate = DateTime.now();
          _selectedCategory = 'Diğer';
          _imagePath = null;
          _extractedData = null;
        });
      }
    } catch (e) {
      print('Harcama kaydedilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harcama kaydedilirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Map<String, dynamic> _extractReceiptData(String text) {
    final lines = text.split('\n');
    final data = <String, dynamic>{
      'rawText': text,
      'merchantName': _findMerchantName(lines),
      'amount': _findAmount(lines),
      'date': _findDate(lines),
      'category': _findCategory(lines),
    };
    return data;
  }

  String? _findMerchantName(List<String> lines) {
    for (var line in lines.take(3)) {
      if (line.length > 3 && !line.contains(RegExp(r'[0-9]'))) {
        return line.trim();
      }
    }
    return null;
  }

  double? _findAmount(List<String> lines) {
    final amountRegex = RegExp(r'TOPLAM:?\s*([0-9,.]+)|([0-9,.]+)\s*TL');
    for (var line in lines.reversed) {
      final match = amountRegex.firstMatch(line);
      if (match != null) {
        final amount = match.group(1) ?? match.group(2);
        if (amount != null) {
          return double.tryParse(amount.replaceAll(',', '.'));
        }
      }
    }
    return null;
  }

  DateTime? _findDate(List<String> lines) {
    final dateRegex = RegExp(
      r'(\d{2})[./](\d{2})[./](\d{4})|(\d{4})-(\d{2})-(\d{2})',
    );
    for (var line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        try {
          if (match.group(1) != null) {
            return DateTime(
              int.parse(match.group(3)!),
              int.parse(match.group(2)!),
              int.parse(match.group(1)!),
            );
          } else {
            return DateTime(
              int.parse(match.group(4)!),
              int.parse(match.group(5)!),
              int.parse(match.group(6)!),
            );
          }
        } catch (e) {
          print('Tarih ayrıştırma hatası: $e');
        }
      }
    }
    return null;
  }

  String? _findCategory(List<String> lines) {
    final keywords = {
      'MARKET': 'Market',
      'RESTAURANT': 'Restoran',
      'CAFE': 'Kafe',
      'GIDA': 'Market',
      'AKARYAKIT': 'Akaryakıt',
      'GIYIM': 'Giyim',
    };

    for (var line in lines) {
      for (var entry in keywords.entries) {
        if (line.toUpperCase().contains(entry.key)) {
          return entry.value;
        }
      }
    }
    return null;
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcama Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_imagePath != null) ...[
                Image.file(
                  File(_imagePath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: 'İşletme Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen işletme adını girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Tutar (TL)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen tutarı girin';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli bir tutar girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tarih',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveManualEntry,
                        child: const Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isProcessing ? null : _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
} 