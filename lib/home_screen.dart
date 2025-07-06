import 'package:flutter/material.dart';
import 'package:smart_kit/screen/image_background_remove_screen.dart';
import 'package:smart_kit/screen/pdf_to_image_screen.dart';
import 'package:smart_kit/utils/uitils.dart';
import 'package:smart_kit/screen/image_compress_screen.dart';
import 'package:smart_kit/screen/image_resize_screen.dart';
import 'package:smart_kit/screen/image_to_pdf_screen.dart';
import 'package:smart_kit/screen/pdf_merge_screen.dart';
import 'constant/app_colors.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> tools = [
    {
      "title": "Image To PDF",
      "image": "lib/assets/images/pdf_icon.webp",
      "color": Colors.blueAccent
    },
    {
      "title": "PDF To Image",
      "image": "lib/assets/images/image_to_pdf.webp",
      "color": Colors.purpleAccent
    },
    {
      "title": "Resize Image",
      "image": "lib/assets/images/image_resize.webp",
      "color": Colors.orangeAccent
    },
    {
      "title": "Compress Image",
      "image": "lib/assets/images/compress.png",
      "color": Colors.greenAccent
    },
    {
      "title": "Background Remover",
      "image": "lib/assets/images/background remove.png",
      "color": Colors.redAccent
    },
    {
      "title": "Merge PDFs",
      "icon": Icons.merge_type,
      "color": Colors.tealAccent
    },
  ];

  @override
  Widget build(BuildContext context) {
    final mqData = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("ImagePro Toolkit",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          physics: BouncingScrollPhysics(),
          itemCount: tools.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            return ToolCard(
              title: tools[index]['title'],
              image: tools[index]['image'],
              icon: tools[index]['icon'],
              color: tools[index]['color'],
              onTap: () =>
                  _navigateToToolScreen(context, tools[index]['title']),
            );
          },
        ),
      ),
    );
  }

  void _navigateToToolScreen(BuildContext context, String title) {
    switch (title) {
      case "Resize Image":
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ImageResizeScreen()));
        break;
      case "Image To PDF":
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ImageToPdfScreen()));
        break;
      case "Compress Image":
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ImageCompressionScreen()));
        break;
      case "Merge PDFs":
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PdfMergeScreen()));
        break;
      case "PDF To Image":
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => PdfToImageScreen()));
        break;
      case "Background Remover":
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ImageBackgroundRemoveScreen()));
        break;
    }
  }
}

class ToolCard extends StatelessWidget {
  final String title;
  final String? image;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  const ToolCard({
    required this.title,
    this.image,
    this.icon,
    required this.color,
    required this.onTap,
    Key? key,
  })  : assert(image != null || icon != null, 'Either image or icon must be provided'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: icon != null
                  ? Icon(icon, size: 40, color: color)
                  : Image.asset(
                      image!,
                      height: 40,
                      width: 40,
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: myTextStyle18(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('Tap to start', style: myTextStyle14()),
          ],
        ),
      ),
    );
  }
}
