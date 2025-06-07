import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

class CurrencyConverter extends StatefulWidget {
  final Map<String, dynamic>? rates;

  const CurrencyConverter({super.key, this.rates});

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  final TextEditingController _amountController = TextEditingController();
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double? _convertedAmount;
  Map<String, dynamic>? _rates;
  bool _isLoading = false;
  String? _lastUpdateTime;

  final Map<String, String> _currencyNames = {
    'IDR': 'Indonesian Rupiah',
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'JPY': 'Japanese Yen',
  };

  final Map<String, String> _currencySymbols = {
    'IDR': 'Rp',
    'USD': '\$',
    'EUR': '€',
    'JPY': '¥',
  };

  @override
  void initState() {
    super.initState();
    _rates = widget.rates;
    _amountController.text = '100000'; // Default IDR amount
    if (_rates == null) {
      _loadCurrencyRates();
    } else {
      _convertCurrency();
      _setLastUpdateTime();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencyRates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rates = await ApiService.getCurrencyRates();
      setState(() {
        _rates = rates;
        _setLastUpdateTime();
      });
      _convertCurrency();
    } catch (e) {
      print('Error loading currency rates: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat kurs mata uang'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setLastUpdateTime() {
    if (_rates != null && _rates!['date'] != null) {
      setState(() {
        _lastUpdateTime = _rates!['date'];
      });
    }
  }

  void _convertCurrency() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _rates == null) {
      setState(() {
        _convertedAmount = null;
      });
      return;
    }

    double converted = 0.0;
    final rates = _rates!['rates'] as Map<String, dynamic>?;

    if (rates == null) {
      setState(() {
        _convertedAmount = null;
      });
      return;
    }

    // Convert based on Frankfurter API structure
    // The API returns rates from a base currency (usually EUR or the 'from' parameter)
    if (_fromCurrency == _toCurrency) {
      converted = amount;
    } else if (_fromCurrency == 'IDR') {
      // Converting from IDR to other currencies
      // Since Frankfurter uses IDR as base when we request from=IDR
      final rate = rates[_toCurrency];
      if (rate != null) {
        converted = amount * rate.toDouble();
      }
    } else if (_toCurrency == 'IDR') {
      // Converting to IDR from other currencies
      final rate = rates[_fromCurrency];
      if (rate != null) {
        converted = amount / rate.toDouble();
      }
    } else {
      // Converting between non-IDR currencies
      // First convert to IDR, then to target currency
      final fromRate = rates[_fromCurrency];
      final toRate = rates[_toCurrency];
      if (fromRate != null && toRate != null) {
        final idrAmount = amount / fromRate.toDouble();
        converted = idrAmount * toRate.toDouble();
      }
    }

    setState(() {
      _convertedAmount = converted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Konversi Mata Uang',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _loadCurrencyRates,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.refresh),
                color: AppTheme.primaryColor,
              ),
            ],
          ),

          // Last update info
          if (_lastUpdateTime != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Terakhir diperbarui: $_lastUpdateTime',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),

          // Amount Input Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jumlah',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Masukkan jumlah',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                      prefixText: '${_currencySymbols[_fromCurrency]} ',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (_) => _convertCurrency(),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Currency Selection Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // From Currency
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dari',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _fromCurrency,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _fromCurrency = value!;
                            });
                            _convertCurrency();
                          },
                          items:
                              _currencyNames.entries.map((entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Swap Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              final temp = _fromCurrency;
                              _fromCurrency = _toCurrency;
                              _toCurrency = temp;
                            });
                            _convertCurrency();
                          },
                          icon: const Icon(Icons.swap_horiz),
                          color: AppTheme.primaryColor,
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),

                  // To Currency
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ke',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _toCurrency,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _toCurrency = value!;
                            });
                            _convertCurrency();
                          },
                          items:
                              _currencyNames.entries.map((entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Result Card
          if (_isLoading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_convertedAmount != null && _rates != null)
            Card(
              elevation: 3,
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Hasil Konversi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _fromCurrency,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _toCurrency,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_currencySymbols[_toCurrency]} ${_formatAmount(_convertedAmount!, _toCurrency)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (_rates!['rates'] != null &&
                        _rates!['rates'][_toCurrency] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '1 $_fromCurrency = ${_formatAmount(_rates!['rates'][_toCurrency].toDouble(), _toCurrency)} $_toCurrency',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else if (_rates == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tidak dapat memuat kurs',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadCurrencyRates,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Info text
          Text(
            'Kurs mata uang disediakan oleh Frankfurter API dan diperbarui secara berkala.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount, String currency) {
    if (currency == 'JPY') {
      return amount.toStringAsFixed(0);
    } else if (currency == 'IDR') {
      // Format IDR with thousands separator
      final String amountStr = amount.toInt().toString();
      String result = '';
      int counter = 0;
      for (int i = amountStr.length - 1; i >= 0; i--) {
        if (counter > 0 && counter % 3 == 0) {
          result = '.$result';
        }
        result = amountStr[i] + result;
        counter++;
      }
      return result;
    } else {
      return amount.toStringAsFixed(2);
    }
  }
}
