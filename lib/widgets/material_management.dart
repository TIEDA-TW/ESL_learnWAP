import 'package:flutter/material.dart';
import 'dart:io';
import '../config/app_config.dart';
import '../services/book_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class MaterialManagement extends StatefulWidget {
  final BookService bookService;
  
  const MaterialManagement({
    Key? key, 
    required this.bookService
  }) : super(key: key);

  @override
  State<MaterialManagement> createState() => _MaterialManagementState();
}

class _MaterialManagementState extends State<MaterialManagement> {
  String _selectedVersion = AppConfig.currentVersion;

  Future<void> _uploadImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        final srcFile = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final targetDir = Directory('${appDir.path}/uploads/images/$_selectedVersion');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
        final fileName = srcFile.uri.pathSegments.last;
        final destFile = File('${targetDir.path}/$fileName');
        await srcFile.copy(destFile.path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('圖片已上傳至 ${destFile.path}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('圖片上傳失敗: \$e')),
        );
      }
    }
  }

  Future<void> _uploadAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result != null && result.files.single.path != null) {
        final srcFile = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final targetDir = Directory('${appDir.path}/uploads/audio/$_selectedVersion');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
        final fileName = srcFile.uri.pathSegments.last;
        final destFile = File('${targetDir.path}/$fileName');
        await srcFile.copy(destFile.path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('音檔已上傳至 ${destFile.path}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('音檔上傳失敗: \$e')),
        );
      }
    }
  }

  void _onVersionChanged(String? newVersion) {
    if (newVersion != null && newVersion != _selectedVersion) {
      setState(() {
        _selectedVersion = newVersion;
        AppConfig.currentVersion = newVersion;
      });
      // 重新載入書本資料
      widget.bookService.loadBookData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('教材管理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 版本選擇下拉選單
            Row(
              children: [
                const Text('選擇教材版本：', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedVersion,
                  items: AppConfig.bookVersions.map((String version) {
                    return DropdownMenuItem<String>(
                      value: version,
                      child: Text(version),
                    );
                  }).toList(),
                  onChanged: _onVersionChanged,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // 上傳按鈕
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _uploadImage,
                    child: const Text('上傳圖片'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _uploadAudio,
                    child: const Text('上傳音檔'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}