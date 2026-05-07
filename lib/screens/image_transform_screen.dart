import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

class ImageTransformScreen extends StatefulWidget {
  const ImageTransformScreen({super.key});

  @override
  State<ImageTransformScreen> createState() => _ImageTransformScreenState();
}

class _ImageTransformScreenState extends State<ImageTransformScreen> {
  // null = using the network sample image
  Uint8List? _userBytes;

  // Sample image shown before the user picks one
  static const String _sampleUrl =
      'https://picsum.photos/seed/student-hub/800/500';

  double brightness = 0;
  double contrast = 1;
  double rotation = 0;
  double scale = 1;
  bool flipH = false;
  bool flipV = false;
  bool grayscale = false;
  bool _saving = false;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.first.bytes != null) {
      setState(() {
        _userBytes = result.files.first.bytes;
        _resetValues();
      });
    }
  }

  void _resetValues() {
    brightness = 0;
    contrast = 1;
    rotation = 0;
    scale = 1;
    flipH = false;
    flipV = false;
    grayscale = false;
  }

  void _reset() => setState(() {
        _resetValues();
        _userBytes = null;
      });

  Future<void> _saveImage() async {
    if (_userBytes == null) return;
    setState(() => _saving = true);
    try {
      final params = _ProcessParams(
        bytes: _userBytes!,
        brightness: brightness,
        contrast: contrast,
        grayscale: grayscale,
        flipH: flipH,
        flipV: flipV,
        rotation: rotation,
      );
      final processed = await compute(_runProcessImage, params);
      final blob = html.Blob([processed]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'edited_image.jpg')
        ..click();
      html.Url.revokeObjectUrl(url);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Live preview widget — same transform applied to both sample and user image
  Widget _buildPreview() {
    final imageWidget = _userBytes != null
        ? Image.memory(_userBytes!, fit: BoxFit.contain)
        : Image.network(
            _sampleUrl,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, loading) => loading == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                size: 80,
                color: Colors.white24),
          );

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scale(scale)
        ..rotateZ(rotation * 3.1416 / 180)
        ..scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0),
      child: ColorFiltered(
        colorFilter: grayscale
            ? const ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0,      0,      0,      1, 0,
              ])
            : ColorFilter.matrix([
                contrast, 0, 0, 0, brightness * 50,
                0, contrast, 0, 0, brightness * 50,
                0, 0, contrast, 0, brightness * 50,
                0, 0, 0,        1, 0,
              ]),
        child: imageWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final labelColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12121C) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Image Editor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_userBytes != null)
            _saving
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.download_rounded),
                    tooltip: 'Download edited image',
                    onPressed: _saveImage,
                  ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset all',
            onPressed: _reset,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Image preview ──────────────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Center(child: _buildPreview()),
                // Sample badge
                if (_userBytes == null)
                  Positioned(
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 13, color: Colors.amber),
                          SizedBox(width: 5),
                          Text('Sample image — pick yours below',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Controls panel ─────────────────────────────────────
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, -4))
                ],
              ),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _SliderRow(
                    label: 'Brightness',
                    icon: Icons.brightness_6_rounded,
                    value: brightness,
                    min: -1,
                    max: 1,
                    displayValue:
                        '${brightness >= 0 ? '+' : ''}${(brightness * 100).toInt()}',
                    color: Colors.orange,
                    labelColor: labelColor,
                    onChanged: (v) => setState(() => brightness = v),
                  ),
                  _SliderRow(
                    label: 'Contrast',
                    icon: Icons.contrast_rounded,
                    value: contrast,
                    min: 0.5,
                    max: 2,
                    displayValue: '${contrast.toStringAsFixed(1)}×',
                    color: Colors.blue,
                    labelColor: labelColor,
                    onChanged: (v) => setState(() => contrast = v),
                  ),
                  _SliderRow(
                    label: 'Rotation',
                    icon: Icons.rotate_right_rounded,
                    value: rotation,
                    min: -180,
                    max: 180,
                    displayValue: '${rotation.toInt()}°',
                    color: Colors.purple,
                    labelColor: labelColor,
                    onChanged: (v) => setState(() => rotation = v),
                  ),
                  _SliderRow(
                    label: 'Zoom',
                    icon: Icons.zoom_in_rounded,
                    value: scale,
                    min: 0.5,
                    max: 3,
                    displayValue: '${scale.toStringAsFixed(1)}×',
                    color: Colors.teal,
                    labelColor: labelColor,
                    onChanged: (v) => setState(() => scale = v),
                  ),
                  const SizedBox(height: 8),
                  // Toggles
                  Wrap(
                    spacing: 8,
                    children: [
                      _ToggleChip(
                        label: 'Flip H',
                        icon: Icons.flip_rounded,
                        selected: flipH,
                        onTap: () => setState(() => flipH = !flipH),
                      ),
                      _ToggleChip(
                        label: 'Flip V',
                        icon: Icons.flip_rounded,
                        selected: flipV,
                        onTap: () => setState(() => flipV = !flipV),
                      ),
                      _ToggleChip(
                        label: 'Grayscale',
                        icon: Icons.filter_b_and_w_rounded,
                        selected: grayscale,
                        onTap: () => setState(() => grayscale = !grayscale),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.image_outlined),
                          label: Text(_userBytes == null
                              ? 'Pick My Image'
                              : 'Change Image'),
                          onPressed: _pickImage,
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (_userBytes != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(Icons.download_rounded),
                            label: Text(_saving ? 'Processing…' : 'Save'),
                            onPressed: _saving ? null : _saveImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5C6BC0),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image processing (runs in isolate via compute) ──────────────

class _ProcessParams {
  final Uint8List bytes;
  final double brightness;
  final double contrast;
  final bool grayscale;
  final bool flipH;
  final bool flipV;
  final double rotation;

  const _ProcessParams({
    required this.bytes,
    required this.brightness,
    required this.contrast,
    required this.grayscale,
    required this.flipH,
    required this.flipV,
    required this.rotation,
  });
}

Uint8List _runProcessImage(_ProcessParams p) {
  img.Image? image = img.decodeImage(p.bytes);
  if (image == null) return p.bytes;
  image = img.adjustColor(image, brightness: p.brightness * 100, contrast: p.contrast);
  if (p.grayscale) image = img.grayscale(image);
  if (p.flipH) image = img.flipHorizontal(image);
  if (p.flipV) image = img.flipVertical(image);
  if (p.rotation != 0) image = img.copyRotate(image, angle: p.rotation.toInt());
  return Uint8List.fromList(img.encodeJpg(image));
}

// ── Reusable slider row ─────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final Color color;
  final Color labelColor;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.color,
    required this.labelColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: labelColor)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.15),
                inactiveTrackColor: color.withValues(alpha: 0.2),
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(displayValue,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Toggle chip ─────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF5C6BC0)
              : const Color(0xFF5C6BC0).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF5C6BC0)
                : const Color(0xFF5C6BC0).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? Colors.white : const Color(0xFF5C6BC0)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : const Color(0xFF5C6BC0))),
          ],
        ),
      ),
    );
  }
}
