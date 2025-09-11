import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class CurrencySelectionDialog extends StatefulWidget {
  final String? currentCurrency;

  const CurrencySelectionDialog({
    Key? key,
    this.currentCurrency,
  }) : super(key: key);

  @override
  State<CurrencySelectionDialog> createState() => _CurrencySelectionDialogState();
}

class _CurrencySelectionDialogState extends State<CurrencySelectionDialog> {
  String? _selectedCurrency;
  bool _isUpdating = false;

  // List of supported currencies
  final List<Map<String, String>> _currencies = [
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$'},
    {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'د.إ'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': 'ر.س'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currentCurrency;
  }

  Future<void> _updateCurrency() async {
    if (_selectedCurrency == null || _selectedCurrency == widget.currentCurrency) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final success = await CurrencyService().updateCurrency(_selectedCurrency!);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Currency updated to ${_selectedCurrency!}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to update currency. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating currency: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.currency_exchange,
            color: ColorManager.primary,
            size: isSmallScreen ? 20 : 24,
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Text(
              'Select Currency',
              style: TextStyle(
                fontSize: isSmallScreen ? FontSize.s16 : FontSize.s18,
                fontWeight: FontWeightManager.bold,
                color: ColorManager.black,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Text(
              'Choose your preferred currency for pricing and payments',
              style: TextStyle(
                fontSize: isSmallScreen ? FontSize.s12 : FontSize.s14,
                color: ColorManager.textGrey,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Expanded(
              child: ListView.builder(
                itemCount: _currencies.length,
                itemBuilder: (context, index) {
                  final currency = _currencies[index];
                  final isSelected = _selectedCurrency == currency['code'];
                  final isCurrent = widget.currentCurrency == currency['code'];

                  return Container(
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _isUpdating ? null : () {
                          setState(() {
                            _selectedCurrency = currency['code'];
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? ColorManager.primary.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? ColorManager.primary
                                  : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: isSmallScreen ? 36 : 40,
                                height: isSmallScreen ? 36 : 40,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? ColorManager.primary
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    currency['symbol']!,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? FontSize.s14 : FontSize.s16,
                                      fontWeight: FontWeightManager.semiBold,
                                      color: isSelected 
                                          ? Colors.white
                                          : ColorManager.black,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currency['name']!,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? FontSize.s14 : FontSize.s16,
                                        fontWeight: FontWeightManager.medium,
                                        color: ColorManager.black,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 2 : 4),
                                    Text(
                                      currency['code']!,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? FontSize.s12 : FontSize.s14,
                                        color: ColorManager.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 6 : 8,
                                    vertical: isSmallScreen ? 2 : 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Current',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? FontSize.s10 : FontSize.s12,
                                      color: Colors.green[700],
                                      fontWeight: FontWeightManager.medium,
                                    ),
                                  ),
                                ),
                              if (isSelected && !isCurrent)
                                Icon(
                                  Icons.check_circle,
                                  color: ColorManager.primary,
                                  size: isSmallScreen ? 20 : 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: isSmallScreen ? FontSize.s14 : FontSize.s16,
              color: Colors.black54,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isUpdating || _selectedCurrency == widget.currentCurrency 
              ? null 
              : _updateCurrency,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorManager.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20,
              vertical: isSmallScreen ? 8 : 12,
            ),
          ),
          child: _isUpdating
              ? SizedBox(
                  width: isSmallScreen ? 16 : 20,
                  height: isSmallScreen ? 16 : 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Update Currency',
                  style: TextStyle(
                    fontSize: isSmallScreen ? FontSize.s14 : FontSize.s16,
                    color: Colors.white,
                    fontWeight: FontWeightManager.semiBold,
                  ),
                ),
        ),
      ],
    );
  }
}
