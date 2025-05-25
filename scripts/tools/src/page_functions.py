from PyQt5.QtCore import QRectF

class PageFunctions:
    def __init__(self, main_window):
        self.main_window = main_window
        
    def load_page(self, page_index):
        """載入指定頁面"""
        if not self.main_window.book_data:
            print("No book data loaded in page_functions")
            return
            
        # 載入圖片
        image_path = self.main_window.book_data.get_image_path(page_index)
        if image_path:
            print(f'Loading image from: {image_path}')
            self.main_window.image_viewer.load_image(image_path)
        else:
            print(f"Failed to get image path for page {page_index}")
            
        # 載入文字框
        page = self.main_window.book_data.get_page(page_index)
        if page:
            print(f"Page loaded in page_functions with {len(page)} elements")
            elements = []
            current_category = self.main_window.category_combo.currentText()
            print(f"Current category: {current_category}")
            
            for i, elem in enumerate(page):
                # 注意: 新的JSON格式會有不同的大小寫
                if elem.get('Category', elem.get('category', '')) == current_category:
                    print(f"Processing element {i}: {elem.get('Text', elem.get('text', 'Unknown'))}")
                    
                    # 首先檢查是否已有將座標轉換為 QRectF
                    if 'rect' in elem and elem['rect'] is not None:
                        print(f"Using existing rect: {elem['rect']}")
                        rect = elem['rect']
                    # 否則從原始座標創建
                    elif all(k in elem for k in ['X1', 'Y1', 'X2', 'Y2']):
                        print(f"Creating rect from coordinates: X1={elem['X1']}, Y1={elem['Y1']}, X2={elem['X2']}, Y2={elem['Y2']}")
                        rect = QRectF(
                            elem['X1'],
                            elem['Y1'],
                            elem['X2'] - elem['X1'],
                            elem['Y2'] - elem['Y1']
                        )
                    # 兼容舊的 JSON 格式
                    elif 'coordinates' in elem and all(k in elem['coordinates'] for k in ['x1', 'y1', 'x2', 'y2']):
                        coords = elem['coordinates']
                        print(f"Creating rect from old format coordinates: {coords}")
                        rect = QRectF(
                            coords['x1'],
                            coords['y1'],
                            coords['x2'] - coords['x1'],
                            coords['y2'] - coords['y1']
                        )
                    else:
                        print(f"No valid coordinates found for element {i}")
                        continue
                        
                    # 兼容不同的屬性名稱
                    text = elem.get('Text', elem.get('text', ''))
                    category = elem.get('Category', elem.get('category', 'Word'))
                    audio_file = elem.get('English_Audio_File', elem.get('audioFile', ''))
                    chinese_translation = elem.get('中文翻譯', '')
                    
                    # 添加到元素列表
                    elements.append({
                        'rect': rect,
                        'text': text,
                        'category': category,
                        'audioFile': audio_file,
                        'element_index': i,
                        'id': elem.get('id', f"elem_{i}"),  # 確保有唯一ID
                        '中文翻譯': chinese_translation  # 添加中文翻譯欄位
                    })
                    print(f"Added element {i} to display list")
                    
            # 設置區域並更新顯示
            print(f"Setting {len(elements)} regions to display")
            self.main_window.image_viewer.set_regions(elements)
            
        # 更新頁碼標籤
        total_pages = self.main_window.book_data.get_total_pages()
        self.main_window.page_label.setText(f'第 {page_index + 1} 頁 / 共 {total_pages} 頁')
        
        # 更新翻頁按鈕狀態
        self.main_window.prev_button.setEnabled(page_index > 0)
        self.main_window.next_button.setEnabled(page_index < total_pages - 1)
        
    def on_page_changed(self, index):
        """頁面選擇改變時的處理函數"""
        if index >= 0:
            self.load_page(index)
            
    def prev_page(self):
        """上一頁"""
        current_index = self.main_window.page_combo.currentIndex()
        if current_index > 0:
            self.main_window.page_combo.setCurrentIndex(current_index - 1)
            
    def next_page(self):
        """下一頁"""
        current_index = self.main_window.page_combo.currentIndex()
        self.main_window.page_combo.setCurrentIndex(current_index + 1)
            
    def on_category_changed(self, category):
        """類別選擇改變時的處理函數"""
        current_index = self.main_window.page_combo.currentIndex()
        if current_index >= 0:
            self.load_page(current_index)