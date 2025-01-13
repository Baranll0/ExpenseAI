import 'package:project/src/models/currency.dart';

class CurrencyConverter {
  static final Map<Currency, double> _rates = {
    Currency.usd: 1.0,
    Currency.eur: 1.09,
    Currency.try_: 0.035,
    Currency.gbp: 1.27,
  };

  static double convertToUSD({
    required double amount,
    required Currency fromCurrency,
  }) {
    return amount * _rates[fromCurrency]!;
  }

  static double convertFromUSD({
    required double amount,
    required Currency toCurrency,
  }) {
    return amount / _rates[toCurrency]!;
  }
} 