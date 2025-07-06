import 'dart:io'; // For file system operations (reading/writing files and directories)
import 'package:flutter/material.dart'; // For Material Design UI components
import 'package:file_picker/file_picker.dart'; // For selecting PDF files from device
import 'package:path_provider/path_provider.dart'; // For accessing app-specific and external directories
import 'package:pdf/pdf.dart'; // For creating and manipulating PDF documents
import 'package:pdf/widgets.dart'
    as pw; // Alias for pdf package to create new PDFs
import 'package:permission_handler/permission_handler.dart'; // For handling storage permissions
import 'package:open_file/open_file.dart'; // For opening the merged PDF file
import 'package:pdfx/pdfx.dart'
    as px; // Alias for pdfx package to load and render PDFs

// PdfMergeScreen is a StatefulWidget for the PDF merging UI
class PdfMergeScreen extends StatefulWidget {
  const PdfMergeScreen({super.key});

  @override
  State<PdfMergeScreen> createState() => _PdfMergeScreenState();
}

class _PdfMergeScreenState extends State<PdfMergeScreen> {
  // List to store selected PDF files
  final List<File> _selectedFiles = [];
  // Flag to indicate if merging is in progress
  bool _isMerging = false;
  // App name for custom folder
  static const String _appName = 'PDFMerger';

  // Function to pick multiple PDF files from the device
  Future<void> _pickPdfFiles() async {
    try {
      // Use file_picker to select multiple PDF files
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      // If files are selected, add them to _selectedFiles
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
      // Show error message if file picking fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  // Function to merge selected PDFs and save to custom app folder with improved quality
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

    // Set merging flag to true to show progress indicator
    setState(() => _isMerging = true);

    try {
      // Request storage permission for Android
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

      // Get the documents directory and create a subfolder named after the app
      final directory = await getApplicationDocumentsDirectory();
      final appFolder = Directory('${directory.path}/$_appName');
      if (!await appFolder.exists()) {
        await appFolder.create(
            recursive: true); // Create the folder if it doesn't exist
      }

      // Generate output path with timestamp in the app folder
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${appFolder.path}/merged_$timestamp.pdf';

      // Create a new PDF document with compression level for smaller file size
      final pdf = pw.Document(compress: true);

      // Process each selected PDF file
      for (var file in _selectedFiles) {
        try {
          // Load the PDF using pdfx to render its pages
          final pdfDoc = await px.PdfDocument.openFile(file.path);

          // Iterate through each page of the PDF
          for (var i = 1; i <= pdfDoc.pagesCount; i++) {
            final page = await pdfDoc.getPage(i);
            // Render the page as a JPEG image with higher resolution (2x scaling)
            final pageImage = await page.render(
              width: page.width * 2, // Double the resolution for better quality
              height: page.height * 2,
              format:
                  px.PdfPageImageFormat.jpeg, // Use JPEG for smaller file size
              quality: 90, // High JPEG quality (0-100)
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
                    // Set DPI for better quality in the output PDF
                    dpi: 300,
                  ),
                ),
              );
            }
          }
          await pdfDoc.close(); // Close the PDF document to free resources
        } catch (e) {
          // Show error if processing a PDF fails and stop merging
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

      // Save the merged PDF to the custom app folder
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
      // Show error if merging or saving fails
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
            // Row with buttons for adding and downloading PDFs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Button to add PDFs
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
                // Button to merge and download PDFs
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
                          : const Icon(Icons.download),
                      label: Text(_isMerging
                          ? 'Downloading...'
                          : 'Download Merged PDF'),
                      onPressed: (_isMerging || _selectedFiles.length < 2)
                          ? null
                          : _mergePdfs, // Disabled if merging or <2 files
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
