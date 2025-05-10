import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class ImageCompressionScreen extends StatefulWidget {
  const ImageCompressionScreen({super.key});

  @override
  State<ImageCompressionScreen> createState() => _ImageCompressionScreenState();
}

class _ImageCompressionScreenState extends State<ImageCompressionScreen> {
  File? _selectedImage;
  double _compressionQuality = 50;
  File? _compressedImage;
  int? _originalSize;
  int? _compressedSize;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _originalSize = _selectedImage!.lengthSync();
          _compressedImage = null;
          _compressedSize = null;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
    }
  }

  Future<void> _compressImage() async {
    if (_selectedImage == null) return;

    try {
      setState(() {
        _compressedImage = null;
      });

      // Read the image
      final imageBytes = await _selectedImage!.readAsBytes();
      final image = img.decodeImage(imageBytes);

      // Compress the image
      final compressedImage = img.copyResize(
        image!,
        width: (image.width * (_compressionQuality / 100)).round(),
        height: (image.height * (_compressionQuality / 100)).round(),
      );

      // Save the compressed image
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = File(tempPath);

      final compressedBytes =
          img.encodeJpg(compressedImage, quality: _compressionQuality.toInt());
      await compressedFile.writeAsBytes(compressedBytes);

      setState(() {
        _compressedImage = compressedFile;
        _compressedSize = compressedBytes.length;
      });

      _showSuccessSnackbar('Image compressed successfully!');
    } catch (e) {
      _showErrorSnackbar('Error compressing image: $e');
    }
  }

  Future<void> _saveToGallery() async {
    if (_compressedImage == null) return;
    try {
      final success = await GallerySaver.saveImage(
        _compressedImage!.path,
        albumName: 'Smart Kit',
      );
      if (success == true) {
        _showSuccessSnackbar('Image saved to gallery!');
      } else {
        _showErrorSnackbar('Failed to save image');
      }
    } catch (e) {
      _showErrorSnackbar('Error saving image: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Compressor'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 10,
        shadowColor: Colors.deepPurple.withOpacity(0.5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection card
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Select an Image',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Choose from Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _pickImage,
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Original Image',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _selectedImage!,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Size: ${_formatBytes(_originalSize!)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_selectedImage != null) ...[
              const SizedBox(height: 30),
              // Compression controls
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compression Settings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Quality: ${_compressionQuality.round()}%',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            _compressionQuality.round() < 30
                                ? 'Low'
                                : _compressionQuality.round() < 70
                                    ? 'Medium'
                                    : 'High',
                            style: TextStyle(
                              color: _compressionQuality.round() < 30
                                  ? Colors.red
                                  : _compressionQuality.round() < 70
                                      ? Colors.orange
                                      : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _compressionQuality,
                        min: 10,
                        max: 100,
                        divisions: 9,
                        activeColor: Colors.deepPurple,
                        inactiveColor: Colors.deepPurple[100],
                        thumbColor: Colors.deepPurpleAccent,
                        label: '${_compressionQuality.round()}%',
                        onChanged: (value) {
                          setState(() {
                            _compressionQuality = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.compress),
                        label: const Text('Compress Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _compressImage,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_compressedImage != null) ...[
              const SizedBox(height: 30),
              // Compressed image result
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Compressed Result',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                      ),
                      const SizedBox(height: 15),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _compressedImage!,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Original Size',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _formatBytes(_originalSize!),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Compressed Size',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _formatBytes(_compressedSize!),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reduction',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${((1 - _compressedSize! / _originalSize!) * 100).toStringAsFixed(1)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Save to Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _saveToGallery,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
