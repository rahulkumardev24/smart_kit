import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_background_remover/image_background_remover.dart';

class ImageBackgroundRemoveScreen extends StatefulWidget {
  const ImageBackgroundRemoveScreen({super.key});

  @override
  State<ImageBackgroundRemoveScreen> createState() =>
      _ImageBackgroundRemoveScreenState();
}

class _ImageBackgroundRemoveScreenState
    extends State<ImageBackgroundRemoveScreen> {
  File? _selectedImage;
  Uint8List? _removedBackgroundImage;
  Uint8List? _originalRemovedBackground; // Stores the transparent version
  bool _isLoading = false;
  String? _errorMessage;
  Color _selectedColor = Colors.white;

  @override
  void initState() {
    super.initState();
    BackgroundRemover.instance.initializeOrt();
  }

  @override
  void dispose() {
    BackgroundRemover.instance.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _removedBackgroundImage = null;
          _originalRemovedBackground = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to pick image: ${e.toString()}";
      });
    }
  }

  Future<void> _removeBackground() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final resultImage = await BackgroundRemover.instance.removeBg(imageBytes);
      final byteData =
          await resultImage.toByteData(format: ImageByteFormat.png);
      final resultBytes = byteData!.buffer.asUint8List();

      setState(() {
        _originalRemovedBackground = resultBytes;
        _removedBackgroundImage = resultBytes;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to remove background: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changeBackgroundColor(Color color) async {
    if (_originalRemovedBackground == null) return;

    setState(() {
      _isLoading = true;
      _selectedColor = color;
    });

    try {
      final modifiedImage = await BackgroundRemover.instance.addBackground(
        image: _originalRemovedBackground!,
        bgColor: color,
      );

      setState(() {
        _removedBackgroundImage = modifiedImage;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to change background: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Background Color'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite, // Ensure dialog has proper width
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 6,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Colors.red,
                    Colors.pink,
                    Colors.purple,
                    Colors.deepPurple,
                    Colors.indigo,
                    Colors.blue,
                    Colors.lightBlue,
                    Colors.cyan,
                    Colors.teal,
                    Colors.green,
                    Colors.lightGreen,
                    Colors.lime,
                    Colors.yellow,
                    Colors.amber,
                    Colors.orange,
                    Colors.deepOrange,
                    Colors.brown,
                    Colors.grey,
                    Colors.blueGrey,
                    Colors.black,
                    Colors.white,
                    Colors.transparent,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        _changeBackgroundColor(color);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color
                                ? Colors.blue
                                : Colors.grey,
                            width: _selectedColor == color ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Custom Color'),
                        content: ColorPicker(
                          pickerColor: _selectedColor,
                          onColorChanged: (color) {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              _changeBackgroundColor(_selectedColor);
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Custom Color'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Advanced Background Remover"),
        centerTitle: true,
        actions: [
          if (_removedBackgroundImage != null)
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: () {},
              tooltip: 'Save Image',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection button
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("Select Image"),
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 20),

            // Original image display
            if (_selectedImage != null) ...[
              const Text(
                "Original Image",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!),
                ),
              ),
              const SizedBox(height: 20),

              // Remove background button
              if (!_isLoading)
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text("Remove Background"),
                  onPressed: _removeBackground,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
            ],

            // Loading indicator
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text("Processing image..."),
                  ],
                ),
              ),
            ],

            // Result display
            if (_removedBackgroundImage != null) ...[
              const SizedBox(height: 20),
              const Text(
                "Background Removed",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_removedBackgroundImage!),
                ),
              ),
              const SizedBox(height: 20),

              // Color options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ColorOption(
                    color: Colors.white,
                    isSelected: _selectedColor == Colors.white,
                    onTap: () => _changeBackgroundColor(Colors.white),
                  ),
                  _ColorOption(
                    color: Colors.black,
                    isSelected: _selectedColor == Colors.black,
                    onTap: () => _changeBackgroundColor(Colors.black),
                  ),
                  _ColorOption(
                    color: Colors.transparent,
                    isSelected: _selectedColor == Colors.transparent,
                    onTap: () {
                      setState(() {
                        _removedBackgroundImage = _originalRemovedBackground;
                        _selectedColor = Colors.transparent;
                      });
                    },
                  ),
                  _ColorOption(
                    color: Colors.blue,
                    isSelected: _selectedColor == Colors.blue,
                    onTap: () => _changeBackgroundColor(Colors.blue),
                  ),
                  GestureDetector(
                    onTap: _showColorPicker,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 2),
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.green, Colors.blue],
                        ),
                      ),
                      child: const Icon(Icons.colorize, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "Select background color",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /* Future<void> _saveImageToGallery() async {
    if (_removedBackgroundImage == null) return;

    try {
      final result = await GallerySaver.saveImage(
        _removedBackgroundImage!,
        albumName: 'Background Remover',
      );

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved to gallery!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }*/
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final bool showLabel;
  final double pickerAreaHeightPercent;

  const ColorPicker({
    required this.pickerColor,
    required this.onColorChanged,
    this.showLabel = true,
    this.pickerAreaHeightPercent = 0.7,
  });

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.pickerColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height *
              widget.pickerAreaHeightPercent,
          child: GridView.count(
            crossAxisCount: 6,
            children: [
              Colors.red,
              Colors.pink,
              Colors.purple,
              Colors.deepPurple,
              Colors.indigo,
              Colors.blue,
              Colors.lightBlue,
              Colors.cyan,
              Colors.teal,
              Colors.green,
              Colors.lightGreen,
              Colors.lime,
              Colors.yellow,
              Colors.amber,
              Colors.orange,
              Colors.deepOrange,
              Colors.brown,
              Colors.grey,
              Colors.blueGrey,
              Colors.black,
              Colors.white,
              Colors.transparent,
            ].map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentColor = color;
                  });
                  widget.onColorChanged(color);
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _currentColor == color ? Colors.blue : Colors.grey,
                      width: _currentColor == color ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (widget.showLabel)
          Text(
            'Selected: ${_currentColor.toString()}',
            style: const TextStyle(fontSize: 16),
          ),
      ],
    );
  }
}
