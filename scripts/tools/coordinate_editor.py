    def update_text_regions(self):
        """根據當前選擇的類別更新文字框顯示"""
        if not hasattr(self, 'elements'):
            return
            
        # 維護一個 elements 和當前選擇的類別
        filtered_elements = [elem for elem in self.elements if elem['category'] == self.category_combo.currentText()]
        
        # 如果存在選中的文字框，更新其座標資訊
        if self.selected_element:
            coords = self.selected_element['rect']
            self.coord_label.setText(f'X1: {coords.x():.0f}, Y1: {coords.y():.0f}\nX2: {coords.x() + coords.width():.0f}, Y2: {coords.y() + coords.height():.0f}')
            self.audio_label.setText(f'音檔: {self.selected_element["audioFile"]}')
        else:
            self.coord_label.setText('座標資訊：\nX1: -, Y1: -\nX2: -, Y2: -')
            self.audio_label.setText('音檔：未選擇')
            
        # 更新圖片顯示區域
        self.image_viewer.set_regions(filtered_elements)
        
    def load_json(self):
        file_dialog = QFileDialog()
        json_file, _ = file_dialog.getOpenFileName(
            self,
            "選擇JSON檔案",
            "D:/click_to_read_MGX/assets/Book_data",
            "JSON files (*.json)"
        )
        
        if json_file:
            try:
                with open(json_file, 'r', encoding='utf-8') as f:
                    self.json_data = json.load(f)
                    self.file_label.setText(os.path.basename(json_file))
                    
                    # 更新頁面下拉選單
                    self.page_combo.clear()
                    for page in self.json_data['pages']:
                        self.page_combo.addItem(f"第 {page['pageNumber']} 頁")
                    
                    # 載入第一頁
                    self.load_page(0)
            except Exception as e:
                print(f"載入JSON檔案時發生錯誤：{str(e)}")
    
    def save_changes(self):
        # TODO: 實現保存功能
        pass
        
    def prev_page(self):
        # TODO: 實現上一頁功能
        pass
        
    def next_page(self):
        # TODO: 實現下一頁功能
        pass
        
    def play_audio(self):
        # TODO: 實現音檔播放功能
        pass
        
    def update_audio(self):
        # TODO: 實現音檔更新功能
        pass
                
    def load_page(self, page_index):
        """載入指定頁面的圖片和資料"""
        if not hasattr(self, 'json_data'):
            return
            
        page = self.json_data['pages'][page_index]
        book_id = self.json_data['metadata']['bookId']
        
        # 更新頁碼標籤
        self.page_label.setText(f'第 {page_index + 1} 頁 / 共 {len(self.json_data["pages"])} 頁')
        
        # 載入圖片
        image_path = f'D:/click_to_read/assets/books/{book_id}/{page["image"]}'
        print(f'Loading image: {image_path}')
        self.image_viewer.load_image(image_path)
        
        # 載入頁面元素
        if 'elements' in page:
            # 將 elements 中的座標資訊轉換為 QRectF
            elements = []
            for elem in page['elements']:
                coords = elem['coordinates']
                rect = QRectF(
                    coords['x1'],
                    coords['y1'],
                    coords['x2'] - coords['x1'],
                    coords['y2'] - coords['y1']
                )
                elements.append({
                    'rect': rect,
                    'text': elem['text'],
                    'category': elem['category'],
                    'audioFile': elem['audioFile']
                })
            self.elements = elements
            
            # 根據當前選擇的類別過濾並顯示文字框
            self.update_text_regions()

def main():
    app = QApplication(sys.argv)
    # 設置應用程式樣式
    app.setStyle('Fusion')
    editor = CoordinateEditor()
    sys.exit(app.exec_())

if __name__ == '__main__':
    main()