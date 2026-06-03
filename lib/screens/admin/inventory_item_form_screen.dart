import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/inventory_item.dart';
import '../../services/inventory_service.dart';

const Color _backgroundDark = Color(0xFF0F0F0F);
const Color _cardGrey = Color(0xFF1B1B1B);
const Color _utmMaroon = Color(0xFF800000);

const Map<String, List<String>> _categoryOptions = {
  'Microcontroller': [
    'Main Board',
    'Development Board',
    'Communication Module',
    'Expansion Module',
  ],
  'Batteries and Casing': [
    'Battery',
    'Battery Holder',
    'Charging Part',
    'Casing',
  ],
  'Motors and Wheels': ['Motor', 'Wheel', 'Caster', 'Coupler', 'Drive Part'],
  'Pneumatic': ['Cylinder', 'Valve', 'Tube', 'Fitting', 'Air Part'],
  'Sensors': [
    'Motion Sensor',
    'Distance Sensor',
    'Position Sensor',
    'Environmental Sensor',
  ],
  'Adapter and Converter': [
    'Adapter',
    'Converter',
    'Regulator',
    'Cable',
    'Connector',
  ],
  'Breadboard': ['Breadboard', 'Jumper Wire', 'Prototype Part'],
  'Industrial PC': [
    'Mini PC',
    'Controller PC',
    'Industrial Display',
    'Peripheral',
  ],
  'LCD Module': [
    'Character LCD',
    'Graphic LCD',
    'OLED Display',
    'Touch Display',
  ],
  'Motor Driver': [
    'DC Motor Driver',
    'Stepper Driver',
    'Servo Driver',
    'Driver Module',
  ],
  'Servo': ['Micro Servo', 'Standard Servo', 'Continuous Servo', 'Servo Part'],
  'TechCare Cool ThingyMagic': [
    'Custom Module',
    'Club Prototype',
    'Special Part',
  ],
  'Webcam': ['USB Webcam', 'HD Webcam', 'Camera Accessory'],
  'Trivial': ['Tool', 'Fastener', 'Consumable', 'Miscellaneous'],
};

class InventoryItemFormScreen extends StatefulWidget {
  const InventoryItemFormScreen({
    super.key,
    required this.inventoryService,
    this.item,
  });

  final InventoryService inventoryService;
  final InventoryItem? item;

  bool get isEditing => item != null;

  @override
  State<InventoryItemFormScreen> createState() =>
      _InventoryItemFormScreenState();
}

class _InventoryItemFormScreenState extends State<InventoryItemFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  late String _generatedCode;
  late String _selectedCategory;
  late String _selectedSubCategory;
  XFile? _selectedImage;
  String _imageUrl = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController = TextEditingController(
      text: item?.totalAmount.toString() ?? '0',
    );
    _locationController = TextEditingController(text: item?.location ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _imageUrl = item?.imageUrl ?? '';

    _selectedCategory =
        item?.category.isNotEmpty == true &&
            _categoryOptions.containsKey(item!.category)
        ? item.category
        : _categoryOptions.keys.first;

    final subOptions = _categoryOptions[_selectedCategory]!;
    _selectedSubCategory =
        item?.subCategory.isNotEmpty == true &&
            subOptions.contains(item!.subCategory)
        ? item.subCategory
        : subOptions.first;

    _generatedCode = item?.code.isNotEmpty == true ? item!.code : '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  void _onCategoryChanged(String? value) {
    if (value == null) return;
    final nextSubOptions = _categoryOptions[value]!;
    setState(() {
      _selectedCategory = value;
      _selectedSubCategory = nextSubOptions.first;
    });
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile == null || !mounted) return;
      setState(() => _selectedImage = pickedFile);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to pick image: $error')));
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageUrl = '';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final base = widget.item;
    final code = widget.isEditing ? _generatedCode : _generateCode();
    var imageUrl = _imageUrl;

    try {
      if (_selectedImage != null) {
        imageUrl = await widget.inventoryService.uploadItemImage(
          imageFile: _selectedImage!,
          itemCode: code,
        );
      }

      final totalAmount = int.parse(_quantityController.text.trim());
      final holdingAmount = base?.holdingAmount ?? 0;
      final rentedAmount = base?.rentedAmount ?? 0;
      final item = InventoryItem(
        id: base?.id ?? '',
        code: code,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        subCategory: _selectedSubCategory,
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        totalAmount: totalAmount,
        availableAmount: totalAmount - holdingAmount - rentedAmount,
        holdingAmount: holdingAmount,
        rentedAmount: rentedAmount,
        imageUrl: imageUrl,
        timestamp: base?.timestamp,
      );

      if (widget.isEditing) {
        await widget.inventoryService.updateItem(item);
      } else {
        await widget.inventoryService.addItem(item);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save item: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subCategoryOptions = _categoryOptions[_selectedCategory]!;

    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _backgroundDark,
        title: Text(widget.isEditing ? 'Edit Item' : 'Add Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildField(_nameController, 'Name'),
            _buildDropdownField(
              label: 'Category',
              value: _selectedCategory,
              options: _categoryOptions.keys.toList(),
              onChanged: _onCategoryChanged,
            ),
            _buildDropdownField(
              label: 'Sub-category',
              value: _selectedSubCategory,
              options: subCategoryOptions,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedSubCategory = value);
              },
            ),
            _buildField(
              _quantityController,
              'Total Amount',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Required';
                final parsed = int.tryParse(value.trim());
                if (parsed == null) {
                  return 'Enter a valid number';
                }
                final activeAmount =
                    (widget.item?.holdingAmount ?? 0) +
                    (widget.item?.rentedAmount ?? 0);
                if (parsed < activeAmount) {
                  return 'Must be at least $activeAmount';
                }
                return null;
              },
            ),
            _buildField(_locationController, 'Location'),
            _buildField(_descriptionController, 'Description', maxLines: 4),
            _buildImageField(),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _utmMaroon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Saving...' : 'Save Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = true,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator:
            validator ??
            (value) {
              if (!isRequired) return null;
              return value == null || value.trim().isEmpty ? 'Required' : null;
            },
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
      ),
    );
  }

  Widget _buildImageField() {
    final hasExistingImage = _imageUrl.isNotEmpty;
    final hasSelectedImage = _selectedImage != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item Image',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.black26),
                child: _buildImagePreview(
                  hasSelectedImage: hasSelectedImage,
                  hasExistingImage: hasExistingImage,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _pickImage,
                  child: Text(
                    hasSelectedImage || hasExistingImage
                        ? 'Change Image'
                        : 'Upload Image',
                  ),
                ),
              ),
              if (hasSelectedImage || hasExistingImage) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _isSaving ? null : _removeImage,
                  child: const Text('Remove'),
                ),
              ],
            ],
          ),
          if (hasSelectedImage) ...[
            const SizedBox(height: 8),
            Text(
              _selectedImage!.name,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview({
    required bool hasSelectedImage,
    required bool hasExistingImage,
  }) {
    if (hasSelectedImage) {
      return FutureBuilder<Uint8List>(
        future: _selectedImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Preview unavailable'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    if (hasExistingImage) {
      return Image.network(
        _imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Text('Preview unavailable')),
      );
    }

    return const Center(
      child: Text('No image selected', style: TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: _cardGrey,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ).copyWith(labelText: label),
        items: options
            .map(
              (option) =>
                  DropdownMenuItem<String>(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
