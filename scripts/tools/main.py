import sys
import os

# 確保必要的目錄存在
def ensure_directories():
    base_dir = "D:/click_to_read"
    required_dirs = [
        os.path.join(base_dir, "assets", "audio"),
        os.path.join(base_dir, "assets", "audio", "en"),
        os.path.join(base_dir, "assets", "audio", "en", "V1"),
        os.path.join(base_dir, "assets", "audio", "en", "V2"),
        os.path.join(base_dir, "assets", "audio", "zh"),
        os.path.join(base_dir, "assets", "audio", "zh", "V1"),
        os.path.join(base_dir, "assets", "audio", "zh", "V2"),
    ]
    
    for directory in required_dirs:
        if not os.path.exists(directory):
            print(f"Creating directory: {directory}")
            os.makedirs(directory, exist_ok=True)

# 獲取當前腳本的完整路徑
current_path = os.path.abspath(__file__)

# 獲取當前腳本所在目錄的路徑
current_dir = os.path.dirname(current_path)

# 將當前目錄加入 Python 路徑
if current_dir not in sys.path:
    sys.path.append(current_dir)

from PyQt5.QtWidgets import QApplication
from PyQt5.QtCore import Qt
from src.main_window import MainWindow

if __name__ == '__main__':
    # 確保需要的目錄存在
    ensure_directories()
    
    app = QApplication(sys.argv)
    
    # 設置應用程式樣式
    app.setStyle('Fusion')
    
    # 創建並顯示主窗口
    window = MainWindow()
    
    # 進入應用程式主循環
    sys.exit(app.exec_())