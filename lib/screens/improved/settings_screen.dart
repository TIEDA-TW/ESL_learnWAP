// 這裡是主設定頁面，已整合所有設定功能，請確保其他地方只 import 或導向這個檔案。

import 'package:flutter/material.dart';
import '../../services/user_service_improved.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ImprovedUserService _userService;
  final TextEditingController _nameController = TextEditingController();
  
  // 設置選項
  bool _enableSound = true;
  bool _enableVibration = true;
  bool _enableNotifications = true;
  bool _enableAutoPlay = false;
  String _preferredVoice = '女聲';
  String _selectedTheme = '系統預設';
  
  // 時間選擇
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);
  List<bool> _selectedDays = List.generate(7, (index) => index < 5); // 週一到週五
  
  @override
  void initState() {
    super.initState();
    _userService = ImprovedUserService();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final userName = await _userService.getUserName();
    // 模擬從服務載入其他設置
    final enableSound = await _userService.getEnableSound() ?? true;
    final enableVibration = await _userService.getEnableVibration() ?? true;
    final enableNotifications = await _userService.getEnableNotifications() ?? true;
    final enableAutoPlay = await _userService.getEnableAutoPlay() ?? false;
    final preferredVoice = await _userService.getPreferredVoice() ?? '女聲';
    final selectedTheme = await _userService.getSelectedTheme() ?? '系統預設';

    setState(() {
      _nameController.text = userName ?? '小朋友';
      _enableSound = enableSound;
      _enableVibration = enableVibration;
      _enableNotifications = enableNotifications;
      _enableAutoPlay = enableAutoPlay;
      _preferredVoice = preferredVoice;
      _selectedTheme = selectedTheme;
    });
  }
  
  // 保存設置
  Future<void> _saveSettings() async {
    // 保存用戶名
    await _userService.updateUserName(_nameController.text);
    
    // 保存學習提醒
    final selectedDays = <int>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        selectedDays.add(i + 1); // 1-7 表示週一到週日
      }
    }
    await _userService.setLearningReminder(_reminderTime, selectedDays);
    
    // 提示用戶
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('設置已保存'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  // 顯示時間選擇器
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: '保存設置',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用戶設置
          _buildSectionHeader('用戶設置'),
          _buildTextField(
            label: '用戶名稱',
            controller: _nameController,
            icon: Icons.person,
          ),
          
          const SizedBox(height: 24),
          
          // 讀書設置
          _buildSectionHeader('閱讀設置'),
          _buildSwitchTile(
            title: '啟用聲音',
            value: _enableSound,
            onChanged: (value) {
              setState(() {
                _enableSound = value;
              });
            },
            icon: Icons.volume_up,
          ),
          _buildSwitchTile(
            title: '啟用震動',
            value: _enableVibration,
            onChanged: (value) {
              setState(() {
                _enableVibration = value;
              });
            },
            icon: Icons.vibration,
          ),
          _buildSwitchTile(
            title: '自動播放',
            value: _enableAutoPlay,
            onChanged: (value) {
              setState(() {
                _enableAutoPlay = value;
              });
            },
            icon: Icons.play_circle_filled,
          ),
          
          const SizedBox(height: 16),
          
          // 聲音選擇
          ListTile(
            leading: const Icon(Icons.record_voice_over, color: Colors.blue),
            title: const Text('朗讀聲音'),
            trailing: DropdownButton<String>(
              value: _preferredVoice,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _preferredVoice = newValue;
                  });
                }
              },
              items: <String>['女聲', '男聲', '兒童聲']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 外觀設置
          _buildSectionHeader('外觀設置'),
          ListTile(
            leading: const Icon(Icons.color_lens, color: Colors.blue),
            title: const Text('主題'),
            trailing: DropdownButton<String>(
              value: _selectedTheme,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedTheme = newValue;
                  });
                }
              },
              items: <String>['系統預設', '淺色', '深色', '可愛風格', '海洋風格']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 提醒設置
          _buildSectionHeader('提醒設置'),
          _buildSwitchTile(
            title: '啟用通知',
            value: _enableNotifications,
            onChanged: (value) {
              setState(() {
                _enableNotifications = value;
              });
            },
            icon: Icons.notifications,
          ),
          
          // 提醒時間
          ListTile(
            enabled: _enableNotifications,
            leading: const Icon(Icons.access_time, color: Colors.blue),
            title: const Text('提醒時間'),
            trailing: TextButton(
              onPressed: _enableNotifications ? _selectTime : null,
              child: Text(
                '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: _enableNotifications ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // 提醒星期
          ListTile(
            enabled: _enableNotifications,
            title: const Text('提醒星期'),
            subtitle: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDayChip('一', 0),
                  _buildDayChip('二', 1),
                  _buildDayChip('三', 2),
                  _buildDayChip('四', 3),
                  _buildDayChip('五', 4),
                  _buildDayChip('六', 5),
                  _buildDayChip('日', 6),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 關於
          _buildSectionHeader('關於'),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.blue),
            title: const Text('應用版本'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.blue),
            title: const Text('使用幫助'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_support, color: Colors.blue),
            title: const Text('聯繫我們'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: const OutlineInputBorder(),
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }
  
  Widget _buildDayChip(String label, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedDays[index] && _enableNotifications,
        onSelected: _enableNotifications
            ? (selected) {
                setState(() {
                  _selectedDays[index] = selected;
                });
              }
            : null,
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.blue.shade100,
        labelStyle: TextStyle(
          color: _selectedDays[index] && _enableNotifications
              ? Colors.blue
              : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使用幫助')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '這裡是使用幫助內容，提供操作說明與常見問題解答。',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('聯繫我們')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '聯繫方式：\nEmail: support@example.com\n電話: 02-1234-5678',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}