import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/community/domain/entities/community_model.dart';
import 'package:localmind_ai/features/community/presentation/controllers/community_controller.dart';

class UploadModelScreen extends ConsumerStatefulWidget {
  const UploadModelScreen({super.key});

  @override
  ConsumerState<UploadModelScreen> createState() => _UploadModelScreenState();
}

class _UploadModelScreenState extends ConsumerState<UploadModelScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameCtrl = TextEditingController();
  final _familyCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _paramsCtrl = TextEditingController();
  final _quantCtrl = TextEditingController();
  final _dlSizeCtrl = TextEditingController();
  final _instSizeCtrl = TextEditingController();
  final _ramCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _checksumCtrl = TextEditingController();
  
  String _selectedCategory = 'Chat';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _familyCtrl.dispose();
    _descCtrl.dispose();
    _paramsCtrl.dispose();
    _quantCtrl.dispose();
    _dlSizeCtrl.dispose();
    _instSizeCtrl.dispose();
    _ramCtrl.dispose();
    _urlCtrl.dispose();
    _checksumCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.3),
            ),
          ),
        ),
        title: Text('Upload Model Metadata', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF070416),
                    const Color(0xFF0F0726),
                    const Color(0xFF020105),
                  ]
                : [
                    const Color(0xFFF0F2FA),
                    const Color(0xFFF5F6FC),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Submit your local open-source GGUF weights to the community repository so others can benchmark and download it.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 20),
                GlassContainer(
                  borderRadius: 24,
                  blur: 10,
                  color: Colors.white.withOpacity(0.04),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Model Name',
                        hint: 'e.g. Llama 3.2 3B Instruct',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _familyCtrl,
                        label: 'Model Family',
                        hint: 'e.g. Llama, Gemma, DeepSeek, Phi',
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Category',
                        items: ['Chat', 'Coding', 'Reasoning', 'Writing', 'Translation', 'Vision'],
                        value: _selectedCategory,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descCtrl,
                        label: 'Description',
                        hint: 'e.g. Meta Llama 3.2 quantized for mobile device runtimes.',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _paramsCtrl,
                              label: 'Parameters Size',
                              hint: 'e.g. 3.2B',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _quantCtrl,
                              label: 'Quantization',
                              hint: 'e.g. Q4_K_M',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _dlSizeCtrl,
                              label: 'Download Size',
                              hint: 'e.g. 2.0 GB',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _instSizeCtrl,
                              label: 'Installed Size',
                              hint: 'e.g. 2.5 GB',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _ramCtrl,
                        label: 'Minimum RAM Requirement',
                        hint: 'e.g. 6 GB',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _urlCtrl,
                        label: 'GGUF Weights URL',
                        hint: 'e.g. https://huggingface.co/.../weights.gguf',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _checksumCtrl,
                        label: 'Checksum Verification',
                        hint: 'e.g. sha256 checksum string',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: state.isUploading ? null : _submitForm,
                  child: state.isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Upload Metadata',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24),
              border: InputBorder.none,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Field cannot be empty';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color(0xFF0F0E23),
              value: value,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: items.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final user = ref.read(authStateChangesProvider).value;
      final model = CommunityModel(
        id: 'model_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text,
        family: _familyCtrl.text,
        developerId: user?.id ?? 'anonymous_dev',
        developerName: user?.displayName ?? user?.email ?? 'Anonymous Dev',
        description: _descCtrl.text,
        category: _selectedCategory,
        parameters: _paramsCtrl.text,
        quantization: _quantCtrl.text,
        downloadSize: _dlSizeCtrl.text,
        installedSize: _instSizeCtrl.text,
        ramRequirement: _ramCtrl.text,
        downloadUrl: _urlCtrl.text,
        checksum: _checksumCtrl.text,
        createdAt: DateTime.now(),
      );

      final success = await ref.read(communityControllerProvider.notifier).uploadModel(model);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model metadata uploaded successfully!'), backgroundColor: Colors.emerald),
        );
        context.pop();
      }
    }
  }
}
