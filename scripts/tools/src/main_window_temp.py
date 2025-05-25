import os
from PyQt5.QtWidgets import (QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
                            QPushButton, QLabel, QComboBox, QFileDialog, QFrame,
                            QGroupBox, QMessageBox)
from PyQt5.QtCore import Qt, QRectF, QTimer
from PyQt5.QtGui import QColor
from PyQt5.QtMultimedia import QMediaPlayer, QMediaContent
from PyQt5.QtCore import QUrl
from src.widgets.image_viewer import ImageViewer
from src.utils.book_data import BookData
from src.utils.audio_updater import AudioUpdater
from datetime import datetime

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.book_data = None
        self.selected_element = None
        self.media_player = QMediaPlayer()
        self.initUI()
        
    def initUI(self):  # 修改了這裡
        self.setWindowTitle('教材座標調整工具')
        self.setMinimumSize(1200, 800)
        
        # 創建主視窗布局
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QHBoxLayout(main_widget)
        
        # 創建左側控制面板
        control_panel = QWidget()
        control_panel.setFixedWidth(250)
        control_layout = QVBoxLayout(control_panel)
        control_layout.setSpacing(10)
        
        # 檔案操作組
        file_group = QGroupBox("檔案操作")
        file_layout = QVBoxLayout()
        self.load_button = QPushButton('載入JSON檔案')
        self.load_button.clicked.connect(self.loadJson)  # 修改了這裡
        self.file_label = QLabel('未載入檔案')
        file_layout.addWidget(self.load_button)
        file_layout.addWidget(self.file_label)
        file_group.setLayout(file_layout)
        control_layout.addWidget(file_group)

        # ... [其餘UI初始化代碼保持不變]
