import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfSplitScreen extends StatefulWidget {
  const PdfSplitScreen({Key? key}) : super(key: key);

  @override
  State<PdfSplitScreen> createState() => _PdfSplitScreenState();
}

class _PdfSplitScreenState extends State<PdfSplitScreen> {
  File? _selectedFile;
  bool _isProcessing = false;
  final TextEditingController _startPageController = TextEditingController();
  final TextEditingController _endPageController = TextEditingController();
  int _totalPages = 0;
  String? _pageRangeError;

  @override
  void initState() {
    super.initState();
    _startPageController.addListener(_validatePageRange);
    _endPageController.addListener(_validatePageRange);
  }

  @override
  void dispose() {
    _startPageController.dispose();
    _endPageController.dispose();
    super.dispose();
  }
  Future<bool> _checkAndRequestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    final result = await Permission.storage.request();

    if (result.isGranted) {
      return true;
    } else if (result.isPermanentlyDenied) {
      _showError('Storage permission permanently denied. Please enable it from app settings.');
      await openAppSettings();
    } else {
      _showError('Storage permission is required to save PDF files.');
    }

    return false;
  }

  // Function to pick a single PDF file from the device
  Future<void> _pickPdfFiles() async {
    try {
      // Use file_picker to select a single PDF file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false, // Changed to single file selection
      );

      // If a file is selected, update _selectedFile and _totalPages
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _selectedFile = file;
          _startPageController.clear();
          _endPageController.clear();
          _pageRangeError = null;
        });

        // Load the PDF to get the total number of pages
        try {
          final inputBytes = await file.readAsBytes();
          final inputDocument = PdfDocument(inputBytes: inputBytes);
          setState(() {
            _totalPages = inputDocument.pages.count;
          });
          inputDocument.dispose();
        } catch (e) {
          _showError('Error reading PDF: $e');
          setState(() {
            _selectedFile = null;
            _totalPages = 0;
          });
        }
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  void _validatePageRange() {
    if (_totalPages == 0) return;

    final startPage = int.tryParse(_startPageController.text) ?? 0;
    final endPage = int.tryParse(_endPageController.text) ?? 0;

    setState(() {
      if (startPage < 1 || endPage > _totalPages || startPage > endPage) {
        _pageRangeError = 'Invalid range (1-$_totalPages)';
      } else {
        _pageRangeError = null;
      }
    });
  }

  Future<void> _splitPdf() async {
    if (_selectedFile == null) {
      _showError('Please select a PDF file first');
      return;
    }

    if (!await _checkAndRequestStoragePermission()) {
      _showError('Storage permission required');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final appFolder = Directory('${directory.path}/PDFSplitter');
      if (!await appFolder.exists()) {
        await appFolder.create(recursive: true);
      }

      final outputPath = '${appFolder.path}/split_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Read input PDF
      final inputBytes = await _selectedFile!.readAsBytes();
      final inputDocument = PdfDocument(inputBytes: inputBytes);
      final outputDocument = PdfDocument();

      final startPage = int.tryParse(_startPageController.text) ?? 1;
      final endPage = int.tryParse(_endPageController.text) ?? _totalPages;

      for (int i = startPage - 1; i < endPage; i++) {
        final page = inputDocument.pages[i];
        final newPage = outputDocument.pages.add();
        final graphics = newPage.graphics;
        final template = page.createTemplate();
        graphics.drawPdfTemplate(template, const Offset(0, 0));
      }

      final outputBytes = await outputDocument.save();
      await File(outputPath).writeAsBytes(outputBytes, flush: true);

      inputDocument.dispose();
      outputDocument.dispose();

      if (!mounted) return;

      // Show success dialog
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success!', style: TextStyle(color: Colors.green)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 16),
              Text('Pages $startPage-$endPage extracted successfully'),
              const SizedBox(height: 8),
              Text(
                'Saved to: ${outputPath.split('/').last}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CLOSE'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OPEN FILE', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (shouldOpen == true) {
        await OpenFile.open(outputPath);
      }
    } catch (e) {
      _showError('Error splitting PDF: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Splitter'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickPdfFiles,
              icon: const Icon(Icons.upload_file),
              label: const Text('SELECT PDF'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedFile != null)
              Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: Text(
                        _selectedFile!.path.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('$_totalPages pages'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _totalPages = 0;
                            _startPageController.clear();
                            _endPageController.clear();
                            _pageRangeError = null;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('SELECT PAGE RANGE:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _startPageController,
                          decoration: const InputDecoration(
                            labelText: 'Start Page',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _endPageController,
                          decoration: InputDecoration(
                            labelText: 'End Page',
                            border: const OutlineInputBorder(),
                            suffixText: 'of $_totalPages',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  if (_pageRangeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _pageRangeError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_isProcessing || _pageRangeError != null) ? null : _splitPdf,
                      icon: _isProcessing
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.content_cut),
                      label: Text(_isProcessing ? 'PROCESSING...' : 'SPLIT PDF'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              const Spacer(),
              const Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No PDF selected',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}