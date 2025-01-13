import 'package:project/src/models/currency.dart';

class ScannedReceipt {
  final String id;
  final String imagePath;
  final String merchantName;  // Satıcı/İşletme adı
  final double amount;
  final Currency currency;
  final DateTime date;
  final String category;
  final Map<String, dynamic> rawData;  // OCR'dan gelen ham veri
  final bool isProcessed;  // İşlenme durumu

  ScannedReceipt({
    required this.id,
    required this.imagePath,
    required this.merchantName,
    required this.amount,
    required this.currency,
    required this.date,
    required this.category,
    required this.rawData,
    this.isProcessed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'merchantName': merchantName,
    'amount': amount,
    'currency': currency.toString(),
    'date': date.toIso8601String(),
    'category': category,
    'rawData': rawData,
    'isProcessed': isProcessed,
  };

  factory ScannedReceipt.fromJson(Map<String, dynamic> json) => ScannedReceipt(
    id: json['id'] as String,
    imagePath: json['imagePath'] as String,
    merchantName: json['merchantName'] as String,
    amount: json['amount'] as double,
    currency: Currency.values.firstWhere(
      (c) => c.toString() == json['currency'],
    ),
    date: DateTime.parse(json['date'] as String),
    category: json['category'] as String,
    rawData: json['rawData'] as Map<String, dynamic>,
    isProcessed: json['isProcessed'] as bool,
  );

  ScannedReceipt copyWith({
    String? id,
    String? imagePath,
    String? merchantName,
    double? amount,
    Currency? currency,
    DateTime? date,
    String? category,
    Map<String, dynamic>? rawData,
    bool? isProcessed,
  }) => ScannedReceipt(
    id: id ?? this.id,
    imagePath: imagePath ?? this.imagePath,
    merchantName: merchantName ?? this.merchantName,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    date: date ?? this.date,
    category: category ?? this.category,
    rawData: rawData ?? this.rawData,
    isProcessed: isProcessed ?? this.isProcessed,
  );
} 