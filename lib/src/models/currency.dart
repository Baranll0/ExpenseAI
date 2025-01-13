enum Currency {
  usd,
  eur,
  try_,
  gbp;

  String get symbol {
    switch (this) {
      case Currency.usd:
        return '\$';
      case Currency.eur:
        return '€';
      case Currency.try_:
        return '₺';
      case Currency.gbp:
        return '£';
    }
  }

  String get code {
    switch (this) {
      case Currency.usd:
        return 'USD';
      case Currency.eur:
        return 'EUR';
      case Currency.try_:
        return 'TRY';
      case Currency.gbp:
        return 'GBP';
    }
  }

  @override
  String toString() {
    switch (this) {
      case Currency.usd:
        return 'USD';
      case Currency.eur:
        return 'EUR';
      case Currency.try_:
        return 'TRY';
      case Currency.gbp:
        return 'GBP';
    }
  }

  static Currency get defaultCurrency => Currency.try_;

  static List<Currency> get availableCurrencies => Currency.values;
} 