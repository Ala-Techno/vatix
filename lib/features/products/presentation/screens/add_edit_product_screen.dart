import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/di/dependency_injection.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/wholesaler_products_provider.dart';

/// [AddEditProductScreen] — شاشة إضافة أو تعديل منتج في كتالوج المورد
class AddEditProductScreen extends StatelessWidget {
  final ProductEntity? product;

  const AddEditProductScreen({super.key, this.product});

  bool get isEditing => product != null;

  /// مسار الانتقال للشاشة مع تمرير الـ Provider من الـ context الحالي
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

    // تحويل السعر من أصغر وحدة إلى نص عادي للإدخال
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final user = context.read<AuthProvider>().user;
    if (user == null) {
      _showError('لم يتم التعرف على حساب المورد');
      return;
    }

    // 1. فحص وتحويل السعر إلى Subunits بأمان تام عبر MoneyFormatter
    final priceSubunits = MoneyFormatter.tryParseToSubunits(
      _priceController.text,
      _selectedCurrency,
      allowZero: false,
    );

    if (priceSubunits == null || priceSubunits <= 0) {
      _showError('صيغة السعر غير صحيحة بالنسبة لعملة ${_selectedCurrency.arabicName}');
      return;
    }

    // 2. فحص كمية المخزون (إن كُتبت)
    int? stockQty;
    if (_stockController.text.trim().isNotEmpty) {
      stockQty = int.tryParse(_stockController.text.trim());
      if (stockQty != null && stockQty < 0) {
        _showError('كمية المخزون لا يمكن أن تكون سالبة');
        return;
      }
    }

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
                // ── 1. بيانات المنتج الأساسية ────────────────────────
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

                // ── 2. السعر والعملة ─────────────────────────────────
                _buildCardSection(
                  title: 'السعر والعملة المعتمدة',
                  icon: Icons.payments_outlined,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // حقل السعر
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

                        // قائمة اختيار العملة (YER, SAR, USD)
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

                // ── 3. وحدة البيع والتصنيف ───────────────────────────
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
                    // اقتراحات سريعة للوحدات الشائعة
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _commonUnits.map((u) {
                        final isSelected = _unitController.text.trim() == u;
                        return ChoiceChip(
                          label: Text(u),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _unitController.text = u);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // حقل التصنيف مع اقتراحات موجودة
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
                        spacing: 6,
                        runSpacing: 4,
                        children: provider.categories.take(6).map((cat) {
                          final isSelected =
                              _categoryController.text.trim() == cat;
                          return ActionChip(
                            label: Text(cat),
                            backgroundColor: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.surfaceVariant,
                            onPressed: () {
                              setState(() => _categoryController.text = cat);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // ── 4. كود SKU والمخزون والتوفر ──────────────────────
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
                    SwitchListTile(
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
                  ],
                ),
                const SizedBox(height: 28),

                // ── زر الحفظ النهائي ─────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: provider.isSaving ? null : _handleSave,
                    child: provider.isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
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
