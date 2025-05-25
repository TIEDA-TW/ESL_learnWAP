// 這是一個用於網頁平台的存根文件，用於替換dart:io的File類
// 在web平台上，我們不能使用dart:io的File，所以提供一個空實現

class File {
  final String path;
  
  File(this.path);
  
  Future<bool> exists() async => false;
  
  Future<int> length() async => 0;
}