import os
import uuid
from PyQt5.QtWidgets import (QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
                            QPushButton, QLabel, QComboBox, QFileDialog, QFrame,
                            QGroupBox, QMessageBox, QTabWidget, QLineEdit, QCheckBox)
from PyQt5.QtCore import Qt, QRectF, QTimer
from PyQt5.QtGui import QColor
from PyQt5.QtMultimedia import QMediaPlayer, QMediaContent
from PyQt5.QtCore import QUrl
from src.widgets.image_viewer import ImageViewer
from src.utils.book_data import BookData
from src.utils.audio_updater import AudioUpdater
from src.audio_functions import AudioFunctions
from src.page_functions import PageFunctions
from src.region_functions import RegionFunctions
from src.add_mode_window import AddModeWindow
from datetime import datetime

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.book_data = None
        self.selected_element = None
        
        # 創建主視窗
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        main_layout = QVBoxLayout(main_widget)
        
        # 創建頁面選擇器和導航（供兩個模式共用）
        nav_widget = QWidget()
        nav_layout = QHBoxLayout(nav_widget)
        
        self.page_combo = QComboBox()
        self.page_combo.currentIndexChanged.connect(self.onPageChanged)
        nav_layout.addWidget(QLabel("頁面:"))
        nav_layout.addWidget(self.page_combo)
        
        self.prev_button = QPushButton('←')
        self.next_button = QPushButton('→')
        self.prev_button.clicked.connect(self.prevPage)
        self.next_button.clicked.connect(self.nextPage)
        nav_layout.addWidget(self.prev_button)
        nav_layout.addWidget(self.next_button)
        
        self.page_label = QLabel('第 0 頁 / 共 0 頁')
        nav_layout.addWidget(self.page_label)
        
        # 添加檔案載入按鈕
        self.load_button = QPushButton('載入JSON檔案')
        self.load_button.clicked.connect(self.loadJson)
        nav_layout.addWidget(self.load_button)
        self.file_label = QLabel('未載入檔案')
        nav_layout.addWidget(self.file_label)
        
        main_layout.addWidget(nav_widget)
        
        # 創建主要內容區域
        content_widget = QWidget()
        content_layout = QHBoxLayout(content_widget)
        
        # 創建分頁控制面板
        self.tab_widget = QTabWidget()
        self.tab_widget.setFixedWidth(300)  # 設置固定寬度
        
        # 創建編輯模式分頁
        self.edit_mode = self.createEditMode()
        self.tab_widget.addTab(self.edit_mode, "編輯模式")
        
        # 創建新增模式分頁
        self.add_mode = AddModeWindow(self)
        self.tab_widget.addTab(self.add_mode, "新增模式")
        
        content_layout.addWidget(self.tab_widget)
        
        # 創建圖片顯示區域
        self.image_viewer = ImageViewer(self)
        content_layout.addWidget(self.image_viewer)
        
        main_layout.addWidget(content_widget)
        
        # 初始化功能模組
        self.audio_functions = AudioFunctions(self)
        self.page_functions = PageFunctions(self)
        self.region_functions = RegionFunctions(self)
        
        # 連接信號
        self.image_viewer.regionSelected.connect(self.onRegionSelected)
        self.image_viewer.regionMoved.connect(self.onRegionMoved)
        self.image_viewer.regionResized.connect(self.onRegionResized)
        self.tab_widget.currentChanged.connect(self.onTabChanged)
        
        # 設置窗口屬性
        self.setWindowTitle('教材座標調整工具')
        self.setMinimumSize(1200, 800)
        self.show()
        
    def createEditMode(self):
        """創建編輯模式介面"""
        widget = QWidget()
        layout = QVBoxLayout(widget)
        
        # 文字框類別組
        category_group = QGroupBox("文字框類別")
        category_layout = QVBoxLayout()
        self.category_combo = QComboBox()
        self.category_combo.addItems(['Word', 'Sentence', 'Full Text'])
        self.category_combo.currentTextChanged.connect(self.onCategoryChanged)
        category_layout.addWidget(self.category_combo)
        category_group.setLayout(category_layout)
        layout.addWidget(category_group)
        
        # 文字內容組
        text_group = QGroupBox("文字內容")
        text_layout = QVBoxLayout()
        self.text_input = QLineEdit()
        text_layout.addWidget(self.text_input)
        text_group.setLayout(text_layout)
        layout.addWidget(text_group)
        
        # 中文翻譯組
        translation_group = QGroupBox("中文翻譯")
        translation_layout = QVBoxLayout()
        self.chinese_translation_input = QLineEdit()
        translation_layout.addWidget(self.chinese_translation_input)
        translation_group.setLayout(translation_layout)
        layout.addWidget(translation_group)
        
        # 座標資訊組
        coord_group = QGroupBox("座標資訊")
        coord_layout = QVBoxLayout()
        self.coord_label = QLabel('X1: -, Y1: -\nX2: -, Y2: -')
        coord_layout.addWidget(self.coord_label)
        coord_group.setLayout(coord_layout)
        layout.addWidget(coord_group)
        
        # 固定Y軸核取方塊
        self.fix_y_checkbox = QCheckBox("固定Y軸 (只改變寬度)")
        self.fix_y_checkbox.setToolTip("勾選後，在調整文字框大小時只會改變X軸大小，Y軸位置保持不變")
        self.fix_y_checkbox.stateChanged.connect(self.onFixYChanged)
        layout.addWidget(self.fix_y_checkbox)
        
        # 保存按鈕
        self.save_button = QPushButton('保存變更')
        self.save_button.setStyleSheet('background-color: #007AFF; color: white; padding: 8px;')
        self.save_button.clicked.connect(self.saveChanges)
        layout.addWidget(self.save_button)
        
        # 添加彈性空間
        layout.addStretch()
        
        return widget

    def onPageChanged(self, index):
        if index >= 0:
            self.loadPage(index)
            
    def prevPage(self):
        current_index = self.page_combo.currentIndex()
        if current_index > 0:
            self.page_combo.setCurrentIndex(current_index - 1)
            
    def nextPage(self):
        current_index = self.page_combo.currentIndex()
        if current_index < self.page_combo.count() - 1:
            self.page_combo.setCurrentIndex(current_index + 1)
            
    def onCategoryChanged(self, category):
        if self.book_data and self.page_combo.currentIndex() >= 0:
            self.loadPage(self.page_combo.currentIndex())
            
    def loadJson(self):
        file_dialog = QFileDialog()
        json_file, _ = file_dialog.getOpenFileName(
            self,
            "選擇JSON檔案",
            "D:/click_to_read_MGX/assets/Book_data",
            "JSON files (*.json)"
        )
        
        if json_file:
            self.book_data = BookData(json_file)
            if self.book_data.load():
                self.file_label.setText(os.path.basename(json_file))
                # 初始化音檔更新器
                self.audio_updater = AudioUpdater(self.book_data)
                # 設置更新回調
                self.audio_updater.set_update_callback(self.audio_functions.on_audio_updated)
                
                # 更新頁面下拉選單
                self.page_combo.clear()
                total_pages = self.book_data.get_total_pages()
                for i in range(total_pages):
                    self.page_combo.addItem(f"第 {i + 1} 頁")
                    
                # 載入第一頁
                self.loadPage(0)
            else:
                self.file_label.setText('載入失敗')
                
    def loadPage(self, page_index):
        """載入頁面"""
        if not self.book_data:
            print("No book data loaded!")
            return
            
        print(f"Loading page index: {page_index}")
        
        # 重要：在加载页面前先确保页面数据更新
        # 获取页面对应的图片名称
        page_keys = list(self.book_data.pages.keys())
        if page_index >= 0 and page_index < len(page_keys):
            page_key = page_keys[page_index]
            page_data = self.book_data.pages[page_key]
            
            # 确保每个元素都有最新的 rect 属性
            for elem in page_data:
                if 'X1' in elem and 'Y1' in elem and 'X2' in elem and 'Y2' in elem:
                    elem['rect'] = QRectF(
                        elem['X1'],
                        elem['Y1'],
                        elem['X2'] - elem['X1'],
                        elem['Y2'] - elem['Y1']
                    )
            
        # 清除未保存的框
        if hasattr(self.image_viewer, 'regions'):
            self.image_viewer.regions = [region for region in self.image_viewer.regions 
                                    if not region.get('new_created', False)]
            self.image_viewer.selected_region = None

        # 載入圖片
        image_path = self.book_data.get_image_path(page_index)
        if image_path:
            print(f'Loading image from: {image_path}')
            self.image_viewer.load_image(image_path)
        else:
            print(f"Failed to get image path for page index: {page_index}")
            
        # 載入內容
        if self.tab_widget.currentIndex() == 0:  # 編輯模式
            print("Loading in edit mode")
            self.page_functions.load_page(page_index)
        else:  # 新增模式
            print("Loading in add mode")
            # 獲取當前頁面的所有文字框
            page = self.book_data.get_page(page_index)
            if page:
                print(f"Page loaded: {len(page)} elements found")
                elements = []
                current_category = self.add_mode.category_combo.currentText()
                print(f"Current category filter: {current_category}")
                
                for i, elem in enumerate(page):
                    # 只顯示當前選擇的類別
                    elem_category = elem.get('Category', elem.get('category', ''))
                    if elem_category == current_category:  # 注意大小寫
                        print(f"Processing element: {elem.get('Text', 'Unknown')}")
                        # 檢查座標是否存在
                        if 'rect' in elem:
                            print(f"Using pre-converted rect: {elem['rect']}")
                            rect = elem['rect']
                        elif all(k in elem for k in ['X1', 'Y1', 'X2', 'Y2']):
                            print(f"Creating rect from X1={elem['X1']}, Y1={elem['Y1']}, X2={elem['X2']}, Y2={elem['Y2']}")
                            rect = QRectF(
                                elem['X1'],
                                elem['Y1'],
                                elem['X2'] - elem['X1'],
                                elem['Y2'] - elem['Y1'])
                        else:
                            print(f"No valid coordinates found for: {elem.get('Text', 'Unknown')}")
                            continue
                            
                        # 使用 uuid 生成唯一 ID（如果原始資料沒有 id）
                        element_id = elem.get('id', str(uuid.uuid4()))
                        element_data = {
                            'rect': rect,
                            'text': elem.get('Text', elem.get('text', '')),  # 注意大小寫
                            'category': elem.get('Category', elem.get('category', 'Word')),  # 注意大小寫
                            'audioFile': elem.get('English_Audio_File', elem.get('audioFile', '')),
                            'audio_name': elem.get('English_Audio_File', elem.get('audioFile', '')),
                            'id': element_id,
                            'element_index': i,  # 使用当前循环内的i
                            'saved': True,  # 標記為已保存的元素
                            '中文翻譯': elem.get('中文翻譯', '')  # 添加中文翻譯欄位
                        }
                        elements.append(element_data)
                        print(f"Added element: {element_data}")
                    else:
                        if 'Category' in elem:
                            print(f"Skipping element with category: {elem['Category']}")
                        else:
                            print(f"Skipping element without category: {elem}")
                
                print(f"Processed {len(elements)} elements with category '{current_category}'")
                self.add_mode.current_regions = elements
                self.add_mode.update_regions_display()
            else:
                print(f"No page data found for index: {page_index}")
            
    def onRegionSelected(self, region):
        if self.tab_widget.currentIndex() == 0:  # 編輯模式
            self.selected_element = region  # 更新選中的元素
            self.region_functions.on_region_selected(region)
        else:  # 新增模式
            # 修改 on_region_selected 調用，確保當前音檔資訊會被正確傳遞
            audio_info = {
                'audio_name': region.get('audioFile') if region and 'audioFile' in region else None,
                **region
            } if region else None
            self.add_mode.on_region_selected(audio_info)
        
    def onRegionMoved(self, region):
        if self.tab_widget.currentIndex() == 0:  # 編輯模式
            self.region_functions.on_region_moved(region)
        else:  # 新增模式
            self.add_mode.on_region_moved(region)
        
    def onRegionResized(self, region):
        if self.tab_widget.currentIndex() == 0:  # 編輯模式
            self.region_functions.on_region_resized(region)
        else:  # 新增模式
            self.add_mode.on_region_resized(region)
        
    def playAudio(self):
        self.audio_functions.play_audio()
        
    def updateAudio(self):
        self.audio_functions.update_audio()
        
    def onTabChanged(self, index):
        """處理分頁切換事件"""
        # 設置是否處於新增模式
        self.image_viewer.set_add_mode(index == 1)
        
        # 清除未保存的框
        if hasattr(self.image_viewer, 'regions'):
            self.image_viewer.regions = [region for region in self.image_viewer.regions 
                                    if not region.get('new_created', False)]
            self.image_viewer.selected_region = None
        
        if self.book_data and self.page_combo.currentIndex() >= 0:
            self.loadPage(self.page_combo.currentIndex())
            
    def saveChanges(self):
        """保存變更"""
        if self.tab_widget.currentIndex() == 0:  # 編輯模式
            # 執行保存
            result = self.region_functions.save_changes()
            
            if result:
                # 保存成功後，重要：讓界面顯示保存後的座標
                # 更新页面数据中的矩形对象，确保生效
                current_page = self.page_combo.currentIndex()
                page_keys = list(self.book_data.pages.keys())
                if current_page >= 0 and current_page < len(page_keys):
                    page_key = page_keys[current_page]
                    page_data = self.book_data.pages[page_key]
                    
                    # 更新页面中的 rect 属性 - 使用保存的座標值重新生成 rect
                    for elem in page_data:
                        if 'X1' in elem and 'Y1' in elem and 'X2' in elem and 'Y2' in elem:
                            elem['rect'] = QRectF(
                                elem['X1'],
                                elem['Y1'],
                                elem['X2'] - elem['X1'],
                                elem['Y2'] - elem['Y1']
                            )
                
                # 強制重繪
                self.image_viewer.update()
                
                # 顯示成功消息
                QMessageBox.information(self, "成功", "變更已保存")
        else:  # 新增模式
            if self.add_mode.save_regions():
                # 重要：更新页面数据中的 rect 属性
                current_page = self.page_combo.currentIndex()
                page_keys = list(self.book_data.pages.keys())
                if current_page >= 0 and current_page < len(page_keys):
                    page_key = page_keys[current_page]
                    page_data = self.book_data.pages[page_key]
                    
                    # 更新页面中的 rect 属性
                    for elem in page_data:
                        if 'X1' in elem and 'Y1' in elem and 'X2' in elem and 'Y2' in elem:
                            elem['rect'] = QRectF(
                                elem['X1'],
                                elem['Y1'],
                                elem['X2'] - elem['X1'],
                                elem['Y2'] - elem['Y1']
                            )
                
                # 強制界面立即更新
                self.image_viewer.update()
                
                # 顯示成功消息
                QMessageBox.information(self, "成功", "變更已保存")
            else:
                QMessageBox.warning(self, "錯誤", "保存失敗")

    def onFixYChanged(self, state):
        """處理固定Y軸核取方塊狀態變更"""
        self.image_viewer.set_fix_y_enabled(state)