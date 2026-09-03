import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/features/scanner/screens/product_scanner_screen.dart';
import 'package:stitch_cov_dark_mobile_login/models/product.dart';

class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.price,
    required this.quantity,
    this.barcode,
    this.photoUrl,
  });
  final String name;
  final double price;
  final int quantity;
  final String? barcode;
  final String? photoUrl;
}

class ProductEditorDialog extends StatefulWidget {
  const ProductEditorDialog({super.key, this.product});
  final Product? product;

  @override
  State<ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<ProductEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _photoUrlController;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product == null
          ? ''
          : widget.product!.price.toStringAsFixed(2),
    );
    _quantityController = TextEditingController(
      text: widget.product?.quantity.toString() ?? '',
    );
    _barcodeController = TextEditingController(
      text: widget.product?.barcode ?? '',
    );
    _photoUrlController = TextEditingController(
      text: widget.product?.photoUrl ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _barcodeController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    Navigator.pop(
      context,
      ProductDraft(
        name: _nameController.text,
        price: price,
        quantity: quantity,
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        photoUrl: _photoUrlController.text.trim().isEmpty
            ? null
            : _photoUrlController.text.trim(),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    if (kIsWeb || _isScanning) return;
    setState(() => _isScanning = true);
    final value = await openProductCodeScanner(context);
    if (!mounted) return;
    setState(() => _isScanning = false);
    if (value != null) _barcodeController.text = value;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.product == null ? 'Nuevo producto' : 'Editar producto'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe el nombre del producto.'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el precio.';
                }
                final price = double.tryParse(value.replaceAll(',', '.'));
                if (price == null || price < 0) {
                  return 'Precio inválido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _barcodeController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Código de barras o QR (opcional)',
                prefixIcon: const Icon(Icons.qr_code_2),
                helperText: kIsWeb
                    ? 'Escribe o pega el código del producto.'
                    : 'Escríbelo o usa la cámara para escanearlo.',
                suffixIcon: kIsWeb
                    ? null
                    : IconButton(
                        tooltip: 'Escanear con la cámara',
                        onPressed: _isScanning ? null : _scanBarcode,
                        icon: _isScanning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.qr_code_scanner),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Cantidad en stock',
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa la cantidad.';
                }
                final quantity = int.tryParse(value);
                if (quantity == null || quantity < 0) {
                  return 'Cantidad inválida.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _photoUrlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'URL de la imagen (opcional)',
                prefixIcon: Icon(Icons.image_outlined),
                helperText: 'Pega la URL de la imagen del producto.',
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  try {
                    final uri = Uri.parse(value.trim());
                    if (uri.scheme.isEmpty || uri.host.isEmpty) {
                      return 'Ingresa una URL válida.';
                    }
                  } catch (_) {
                    return 'Ingresa una URL válida.';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        onPressed: _submit,
        child: const Text('Guardar'),
      ),
    ],
  );
}