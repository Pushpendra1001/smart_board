import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:smart_board/pages/gallery_page.dart';
import 'package:smart_board/pages/whiteboard2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';




class HomePage extends StatelessWidget {
  final List<AppInfo> apps = [
    AppInfo('Email', Icons.email, Colors.red, _launchEmail),
    AppInfo('Google', Icons.search, Colors.blue, _launchGoogle),
    AppInfo('Whiteboard', Icons.edit, Colors.green, (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => WhiteboardPage()))),
    
    AppInfo('Camera', Icons.camera_alt, Colors.orange, (context) => handleCameraAndGallery(context)),
    AppInfo('Gallery', Icons.photo_library, Colors.purple, (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => GalleryPage())))
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Smart Hub',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: AnimationLimiter(
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      columnCount: 2,
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: AppCard(app: apps[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppInfo {
  final String name;
  final IconData icon;
  final Color color;
  final Function onTap;

  AppInfo(this.name, this.icon, this.color, this.onTap);
}

class AppCard extends StatelessWidget {
  final AppInfo app;

  AppCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => app.onTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: app.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: app.color.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              app.icon,
              size: 48,
              color: app.color,
            ),
            SizedBox(height: 8),
            Text(
              app.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: app.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _launchEmail(BuildContext context) async {
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: '',
  );
  if (await canLaunchUrl(emailLaunchUri)) {
    await launchUrl(emailLaunchUri);
  } else {
    // If we can't launch the email app, try opening Gmail specifically
    final Uri gmailUrl = Uri.parse('https://mail.google.com/');
    if (await canLaunchUrl(gmailUrl)) {
      await launchUrl(gmailUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch email app')),
      );
    }
  }
}

Future<void> _launchGoogle(BuildContext context) async {
  final Uri url = Uri.parse('https://www.google.com');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not launch Google')),
    );
  }
}



Future<void> handleCameraAndGallery(BuildContext context) async {
  try {
    
    final ImagePicker _picker = ImagePicker();

    
    final choice = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Choose option'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () { Navigator.pop(context, 'camera'); },
              child: const Text('Take a photo'),
            ),
            SimpleDialogOption(
              onPressed: () { Navigator.pop(context, 'gallery'); },
              child: const Text('Choose from gallery'),
            ),
          ],
        );
      }
    );

    if (choice == null) return;

    
    final XFile? image = await _picker.pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery
    );

    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected')),
      );
      return;
    }

    // Save the image
    final directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final String fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.png';
    final String filePath = '$path/$fileName';
    
    await File(image.path).copy(filePath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image saved successfully')),
    );

  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}