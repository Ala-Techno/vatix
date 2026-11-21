import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/di/dependency_injection.dart';
import 'package:vatix/core/services/image_upload_service.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/core/widgets/vatix_product_image.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/wholesaler_products_provider.dart';

/// [AddEditProductScreen] — Wholesaler catalog product add/edit screen
class AddEditProductScreen extends StatelessWidget {
  final ProductEntity? product;

  const AddEditProductScreen({super.key, this.product});

  bool get isEditing => product != null;

  /// Route to screen passing the Provider from the current context
  static Route<bool?> route(BuildContext context, {ProductEntity? product}) {
    final provider = context.read<WholesalerProductsProvider>();
    return MaterialPageRoute<bool?>(
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: AddEditProductScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasProvider = true;
    try {
      Provider.of<WholesalerProductsProvider>(context, listen: false);
    } catch (_) {
      hasProvider = false;
    }

    if (!hasProvider) {
      return ChangeNotifierProvider<WholesalerProductsProvider>(
        create: (_) => getIt<WholesalerProductsProvider>(),
        child: _AddEditProductContent(product: product),
      );
    }

    return _AddEditProductContent(product: product);
  }
}

class _AddEditProductContent extends StatefulWidget {
  final ProductEntity? product;

  const _AddEditProductContent({this.product});

  bool get isEditing => product != null;

  @override
  State<_AddEditProductContent> createState() => _AddEditProductContentState();
}

class _AddEditProductContentState extends State<_AddEditProductContent> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _unitController;
  late final TextEditingController _categoryController;
  late final TextEditingController _skuController;
  late final TextEditingController _stockController;

  late Currency _selectedCurrency;
  late bool _isAvailable;

  // Product image management
  File? _pickedImageFile;
  String? _currentImageUrl;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;
  int _uploadPercent = 0;
  late final ImageUploadService _imageUploadService;

  static const _commonUnits = [
    'كرتون',
    'حبة',
    'باكت',
    'كيس',
    'شدة',
    'درزن',
    'كجم',
    'لتر',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');

    // Convert price from subunits to decimal/integer string for input
    if (p != null) {
      if (p.currency.decimals == 0) {
        _priceController = TextEditingController(text: p.price.toString());
      } else {
        final mainUnit = p.price / p.currency.multiplier;
        _priceController = TextEditingController(
          text: mainUnit.toStringAsFixed(p.currency.decimals),
        );
      }
    } else {
      _priceController = TextEditingController();
    }

    _unitController = TextEditingController(text: p?.unit ?? 'كرتون');
    _categoryController = TextEditingController(text: p?.category ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _stockController = TextEditingController(
      text: p?.stockQuantity?.toString() ?? '',
    );

    _selectedCurrency = p?.currency ?? Currency.yer;
    _isAvailable = p?.isAvailable ?? true;
    _currentImageUrl = p?.imageUrl;
    _imageUploadService = getIt<ImageUploadService>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _categoryController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // إغلاق الـ bottom sheet
    final result = await _imageUploadService.pickAndValidateImage(source: source);
    if (!mounted) return;

    if (result.errorMessage != null) {
      _showError(result.errorMessage!);
      return;
    }

    if (result.file != null) {
      setState(() {
        _pickedImageFile = result.file;
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'اختر صورة المنتج',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'الحد الأقصى 2 ميجابايت (JPG, PNG, WEBP)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                  ),
                  title: const Text('المعرض', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                  subtitle: const Text('اختر صورة من ألبوم الصور', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.accent),
                  ),
                  title: const Text('الكاميرا', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                  subtitle: const Text('التقط صورة جديدة للمنتج', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                if (_pickedImageFile != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)) ...[
                  const Divider(height: 24),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.statusBlocked.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.statusBlocked),
                    ),
                    title: const Text('حذف الصورة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, color: AppColors.statusBlocked)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _pickedImageFile = null;
                        _currentImageUrl = null;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final user = context.read<AuthProvider>().user;
    if (user == null) {
      _showError('لم يتم التعرف على حساب المورد');
      return;
    }

    // 1. Safely parse and convert price to subunits via MoneyFormatter
    final priceSubunits = MoneyFormatter.tryParseToSubunits(
      _priceController.text,
      _selectedCurrency,
      allowZero: false,
    );

    if (priceSubunits == null || priceSubunits <= 0) {
      _showError('صيغة السعر غير صحيحة بالنسبة لعملة ${_selectedCurrency.arabicName}');
      return;
    }

    // 2. Validate stock quantity (if entered)
    int? stockQty;
    if (_stockController.text.trim().isNotEmpty) {
      stockQty = int.tryParse(_stockController.text.trim());
      if (stockQty != null && stockQty < 0) {
        _showError('كمية المخزون لا يمكن أن تكون سالبة');
        return;
      }
    }

    // 3. Upload image to Firebase Storage if a new image was chosen, with percentage tracking
    String? finalImageUrl = _currentImageUrl;
    if (_pickedImageFile != null) {
      setState(() {
        _isUploadingImage = true;
        _uploadProgress = 0.0;
        _uploadPercent = 0;
      });

      final uploadedUrl = await _imageUploadService.uploadProductImage(
        imageFile: _pickedImageFile!,
        wholesalerId: user.id,
        onProgress: (progress, percent) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
              _uploadPercent = percent;
            });
          }
        },
      );

      if (!mounted) return;

      if (uploadedUrl != null) {
        finalImageUrl = uploadedUrl;
      } else {
        setState(() => _isUploadingImage = false);
        _showError('فشل رفع صورة المنتج، تأكد من اتصال الإنترنت وحاول مجدداً');
        return;
      }
      setState(() => _isUploadingImage = false);
    }

    if (!mounted) return;

    final provider = context.read<WholesalerProductsProvider>();
    bool success = false;

    if (widget.isEditing) {
      success = await provider.updateProduct(
        productId: widget.product!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: priceSubunits,
        currency: _selectedCurrency,
        unit: _unitController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        imageUrl: finalImageUrl,
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim().toUpperCase(),
        stockQuantity: stockQty,
        isAvailable: _isAvailable,
      );
    } else {
      success = await provider.createProduct(
        wholesalerId: user.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: priceSubunits,
        currency: _selectedCurrency,
        unit: _unitController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        imageUrl: finalImageUrl,
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim().toUpperCase(),
        stockQuantity: stockQty,
        isAvailable: _isAvailable,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.isEditing
                    ? 'تم تعديل المنتج بنجاح'
                    : 'تمت إضافة المنتج إلى الكتالوج بنجاح',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ],
          ),
          backgroundColor: AppColors.statusActive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      _showError(provider.errorMessage ?? 'تعذّر حفظ المنتج، حاول مجدداً');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.statusBlocked,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WholesalerProductsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'تعديل الصنف' : 'إضافة صنف جديد للكتالوج'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 0. Product image ────────────────────────────────
                _buildImagePickerCard(),
                const SizedBox(height: 14),

                // ── 1. Basic product info ───────────────────────────
                _buildCardSection(
                  title: 'بيانات الصنف والوصف',
                  icon: Icons.inventory_2_outlined,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'اسم الصنف التجاري *',
                        hintText: 'مثال: حليب ممتاز 390 جم',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'يرجى إدخال اسم الصنف';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      textInputAction: TextInputAction.next,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'وصف إضافي أو مواصفات (اختياري)',
                        hintText: 'تعبئة، بلد المنشأ، الحجم...',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── 2. Price and currency ────────────────────────────
                _buildCardSection(
                  title: 'السعر والعملة المعتمدة',
                  icon: Icons.payments_outlined,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price field
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'سعر الجملة *',
                              hintText: _selectedCurrency == Currency.yer
                                  ? '1500'
                                  : '12.50',
                              prefixIcon: const Icon(Icons.attach_money_rounded),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'يرجى إدخال السعر';
                              }
                              final subunits =
                                  MoneyFormatter.tryParseToSubunits(
                                v,
                                _selectedCurrency,
                                allowZero: false,
                              );
                              if (subunits == null || subunits <= 0) {
                                return 'سعر غير صالح';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Currency dropdown (YER, SAR, USD)
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<Currency>(
                            initialValue: _selectedCurrency,
                            decoration: const InputDecoration(
                              labelText: 'العملة *',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 14,
                              ),
                            ),
                            items: Currency.values.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(
                                  '${c.symbol} (${c.code})',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCurrency = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── 3. Sale unit and category ────────────────────────
                _buildCardSection(
                  title: 'وحدة البيع والتصنيف',
                  icon: Icons.category_outlined,
                  children: [
                    TextFormField(
                      controller: _unitController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'وحدة البيع *',
                        hintText: 'مثال: كرتون، باكت، حبة، كيس...',
                        prefixIcon: Icon(Icons.all_inbox_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'يرجى تحديد وحدة البيع';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    // Quick suggestions for common units
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _commonUnits.map((u) {
                        final isSelected = _unitController.text.trim() == u;
                        return ChoiceChip(
                          label: Text(
                            u,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : const BorderSide(color: Color(0xFFCBD5E1)).color,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (_) {
                            setState(() => _unitController.text = u);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Category field with existing suggestions
                    TextFormField(
                      controller: _categoryController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'التصنيف (اختياري)',
                        hintText: 'مثال: معلبات، منظفات، مواد غذائية...',
                        prefixIcon: Icon(Icons.grid_view_rounded),
                      ),
                    ),
                    if (provider.categories.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: provider.categories.take(6).map((cat) {
                          final isSelected =
                              _categoryController.text.trim() == cat;
                          return ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: const Color(0xFFF1F5F9),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : const BorderSide(color: Color(0xFFCBD5E1)).color,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onSelected: (_) {
                              setState(() => _categoryController.text = cat);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // ── 4. SKU code, stock and availability ─────────────
                _buildCardSection(
                  title: 'المخزون والتوفر',
                  icon: Icons.warehouse_outlined,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _skuController,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Z0-9a-z\-]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'كود الصنف SKU (اختياري)',
                              hintText: 'MLK-01',
                              prefixIcon: Icon(Icons.tag_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'الكمية المتوفرة (اختياري)',
                              hintText: '50',
                              prefixIcon: Icon(Icons.layers_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'إتاحة الصنف للطلب المباشر من التجار',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        subtitle: const Text(
                          'عند التعطيل، يظل الصنف ظاهراً كمعطل ولا يمكن إضافته للسلة.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        value: _isAvailable,
                        activeThumbColor: AppColors.statusActive,
                        onChanged: (val) => setState(() => _isAvailable = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Final save button ────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (provider.isSaving || _isUploadingImage) ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: (provider.isSaving || _isUploadingImage)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      value: _isUploadingImage ? _uploadProgress : null,
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isUploadingImage
                                        ? 'جاري رفع الصورة ($_uploadPercent%)...'
                                        : 'جاري الحفظ...',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                              if (_isUploadingImage) ...[
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: SizedBox(
                                    width: 160,
                                    height: 3,
                                    child: LinearProgressIndicator(
                                      value: _uploadProgress,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          )
                        : Text(
                            widget.isEditing
                                ? 'حفظ التعديلات'
                                : 'إضافة الصنف إلى الكتالوج',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Item image selection and preview card
  Widget _buildImagePickerCard() {
    final hasImage = _pickedImageFile != null ||
        (_currentImageUrl != null && _currentImageUrl!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.add_photo_alternate_outlined,
                  size: 18, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              const Text(
                'صورة الصنف (اختياري)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
              const Spacer(),
              if (hasImage)
                TextButton.icon(
                  onPressed: _showImageSourcePicker,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(
                    'تغيير',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showImageSourcePicker,
            child: hasImage
                ? Container(
                    height: 160,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                      color: AppColors.surfaceVariant,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_pickedImageFile != null)
                          Image.file(
                            _pickedImageFile!,
                            fit: BoxFit.cover,
                          )
                        else if (_currentImageUrl != null &&
                            _currentImageUrl!.isNotEmpty)
                          VatixProductImage(
                            imageUrl: _currentImageUrl!,
                            fit: BoxFit.cover,
                          ),
                        if (_isUploadingImage)
                          Container(
                            color: Colors.black.withValues(alpha: 0.6),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: CircularProgressIndicator(
                                          value: _uploadProgress,
                                          strokeWidth: 3.5,
                                          color: Colors.white,
                                          backgroundColor: Colors.white24,
                                        ),
                                      ),
                                      Text(
                                        '$_uploadPercent%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'جاري الرفع والسيرفر...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt_outlined,
                                      size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'تغيير الصورة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 24,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'اضغط هنا لإضافة صورة للصنف',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'يمكنك التقاط صورة بالكاميرا أو الاختيار من المعرض',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
