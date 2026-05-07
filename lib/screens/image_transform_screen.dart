import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

class ImageTransformScreen extends StatefulWidget {
  const ImageTransformScreen({super.key});

  @override
  State<ImageTransformScreen> createState() => _ImageTransformScreenState();
}

class _ImageTransformScreenState extends State<ImageTransformScreen> {
  Uint8List? _originalBytes;
  Uint8List? _finalBytes;

  // 🎛 CONTROLS
  double brightness = 0;
  double contrast = 1;
  double rotation = 0;
  double scale = 1;

  bool flipH = false;
  bool flipV = false;
  bool grayscale = false;

  // 📂 PICK IMAGE
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(() {
        _originalBytes = result.files.first.bytes;
        _finalBytes = _originalBytes;
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

  // 🎨 PROCESS IMAGE ON SAVE
  Uint8List _processImage() {
    img.Image? image = img.decodeImage(_originalBytes!);

    if (image == null) return _originalBytes!;

    // brightness
    image = img.adjustColor(
      image,
      brightness: brightness * 100,
      contrast: contrast,
    );

    // grayscale
    if (grayscale) {
      image = img.grayscale(image);
    }

    // flip
    if (flipH) image = img.flipHorizontal(image);
    if (flipV) image = img.flipVertical(image);

    // rotate
    if (rotation != 0) {
      image = img.copyRotate(image, angle: rotation.toInt());
    }

    return Uint8List.fromList(img.encodeJpg(image));
  }

  // 💾 SAVE IMAGE
  void _saveImage() {
    if (_originalBytes == null) return;

    final processed = _processImage();

    final blob = html.Blob([processed]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "edited_image.jpg")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  // 🔄 RESET
  void _reset() {
    setState(() {
      _resetValues();
      _finalBytes = _originalBytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pro Image Editor"),
        actions: [
          if (_originalBytes != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _saveImage,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          ),
        ],
      ),

      body: Column(
        children: [
          // 🖼 IMAGE PREVIEW
          Expanded(
            child: Center(
              child: _originalBytes == null
                  ? const Text("Pick an image")
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..scale(scale)
                        ..rotateZ(rotation * 3.1416 / 180)
                        ..scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix([
                          contrast, 0, 0, 0, brightness * 50,
                          0, contrast, 0, 0, brightness * 50,
                          0, 0, contrast, 0, brightness * 50,
                          0, 0, 0, 1, 0,
                        ]),
                        child: Image.memory(_originalBytes!, fit: BoxFit.contain),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 10),

          // 📂 PICK IMAGE
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text("Pick Image"),
          ),

          if (_originalBytes != null)
            Expanded(
              child: ListView(
                children: [
                  // 🌞 BRIGHTNESS
                  const Text("Brightness"),
                  Slider(
                    value: brightness,
                    min: -1,
                    max: 1,
                    onChanged: (v) => setState(() => brightness = v),
                  ),

                  // 🎚 CONTRAST
                  const Text("Contrast"),
                  Slider(
                    value: contrast,
                    min: 0.5,
                    max: 2,
                    onChanged: (v) => setState(() => contrast = v),
                  ),

                  // 🔄 ROTATE
                  const Text("Rotate"),
                  Slider(
                    value: rotation,
                    min: -180,
                    max: 180,
                    onChanged: (v) => setState(() => rotation = v),
                  ),

                  // 🔍 ZOOM
                  const Text("Zoom"),
                  Slider(
                    value: scale,
                    min: 0.5,
                    max: 3,
                    onChanged: (v) => setState(() => scale = v),
                  ),

                  // 🔘 TOGGLES
                  Wrap(
                    spacing: 10,
                    children: [
                      FilterChip(
                        label: const Text("Flip H"),
                        selected: flipH,
                        onSelected: (v) => setState(() => flipH = v),
                      ),
                      FilterChip(
                        label: const Text("Flip V"),
                        selected: flipV,
                        onSelected: (v) => setState(() => flipV = v),
                      ),
                      FilterChip(
                        label: const Text("Grayscale"),
                        selected: grayscale,
                        onSelected: (v) => setState(() => grayscale = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔘 BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _reset,
                          child: const Text("Reset"),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveImage,
                          child: const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}