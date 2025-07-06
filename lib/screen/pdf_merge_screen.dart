import 'dart:io';
import 'package:flutter/material.dart';
/// For selecting PDF files from device
import 'package:file_picker/file_picker.dart';
/// For accessing app-specific directories
import 'package:path_provider/path_provider.dart';
/// For creating and manipulating PDF documents
import 'package:pdf/pdf.dart';
/// Alias for pdf package to create new PDFs
import 'package:pdf/widgets.dart' as pw;
/// For handling storage permissions
import 'package:permission_handler/permission_handler.dart';
/// For opening the merged PDF file
import 'package:open_file/open_file.dart';
/// Alias for pdfx package to load and render PDFs
import 'package:pdfx/pdfx.dart' as px;


class PdfMergeScreen extends StatefulWidget {
  const PdfMergeScreen({super.key});

  @override
  State<PdfMergeScreen> createState() => _PdfMergeScreenState();
}

class _PdfMergeScreenState extends State<PdfMergeScreen> {
  /// List to store selected PDF files
  final List<File> _selectedFiles = [];
  /// Flag to indicate if merging is in progress
  bool _isMerging = false;

  /// Function to pick multiple PDF files from the device
  Future<void> _pickPdfFiles() async {
    try {
      /// Use file_picker to select multiple PDF files
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      /// If files are selected, add them to _selectedFiles
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(
            result.files
                .where((file) => file.path != null)
                .map((file) => File(file.path!)),
          );
        });
      }
    } catch (e) {
      /// Show error message if file picking fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  /// Function to merge selected PDFs into a single PDF
  Future<void> _mergePdfs() async {
    // Check if at least 2 PDFs are selected
    if (_selectedFiles.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least 2 PDF files')),
        );
      }
      return;
    }

    /// Set merging flag to true to show progress indicator
    setState(() => _isMerging = true);

    try {
      /// Request storage permission for Android (optional for app-specific directories)
      var status = await Permission.storage.request();
      if (!status.isGranted && Platform.isAndroid) {
        status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission required')),
            );
          }
          return;
        }
      }

      // Get app's documents directory to save the merged PDF
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/merged_$timestamp.pdf';

      /// Create a new PDF document using the pdf package
      final pdf = pw.Document();

      /// Process each selected PDF file
      for (var file in _selectedFiles) {
        try {
          /// Load the PDF using pdfx to render its pages
          final pdfDoc = await px.PdfDocument.openFile(file.path);

          // Iterate through each page of the PDF
          for (var i = 1; i <= pdfDoc.pagesCount; i++) {
            final page = await pdfDoc.getPage(i);
            // Render the page as a PNG image
            final pageImage = await page.render(
              width: page.width,
              height: page.height,
              format: px.PdfPageImageFormat.png,
            );
            await page.close(); // Close the page to free resources

            // Add the rendered image to the new PDF
            if (pageImage != null) {
              pdf.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat(page.width, page.height),
                  build: (pw.Context context) => pw.Image(
                    pw.MemoryImage(pageImage.bytes),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              );
            }
          }
          /// Close the PDF document to free resources
          await pdfDoc.close();
        } catch (e) {
          /// Show error if processing a PDF fails and stop merging
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Error processing ${file.path.split('/').last}: $e')),
            );
          }
          return;
        }
      }

      // Save the merged PDF to the output path
      final mergedBytes = await pdf.save();
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(mergedBytes);

      if (!mounted) return;

      // Show success dialog with option to open the merged file
      bool? open = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: Text('PDFs merged successfully at:\n$outputPath'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open File'),
            ),
          ],
        ),
      );

      // Open the merged PDF if the user chooses to
      if (open == true) {
        final result = await OpenFile.open(outputPath);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening file: ${result.message}')),
          );
        }
      }
    } catch (e) {
      // Show error if merging fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error merging PDFs: $e')),
        );
      }
    } finally {
      // Reset merging flag when done
      if (mounted) {
        setState(() => _isMerging = false);
      }
    }
  }

  // Function to remove a PDF file from the selected list
  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build the UI with a Scaffold containing an AppBar and body
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge PDFs'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ListView to display selected PDF files
            Expanded(
              child: _selectedFiles.isEmpty
                  ? const Center(
                      child: Text('No PDFs selected'),
                    )
                  : ListView.builder(
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.picture_as_pdf,
                                color: Colors.red),
                            title: Text(
                              file.path.split('/').last,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _removeFile(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            // Row with buttons for adding and merging PDFs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add PDFs'),
                      onPressed: _isMerging
                          ? null
                          : _pickPdfFiles, // Disabled during merging
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      icon: _isMerging
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.merge),
                      label: Text(_isMerging ? 'Merging...' : 'Merge PDFs'),
                      onPressed: _isMerging
                          ? null
                          : _mergePdfs, // Disabled during merging
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
