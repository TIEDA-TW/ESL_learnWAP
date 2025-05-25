from datetime import datetime
from PyQt5.QtWidgets import QMessageBox
from PyQt5.QtCore import QRectF
import json
import os

class RegionFunctions:
    def __init__(self, main_window):
        self.main_window = main_window
        
    def on_region_selected(self, region):
        """文字框選擇改變時的處理函數"""
        self.main_window.selected_element = region
        
        if region:
            print(f"Region selected: {region}")
            if 'rect' in region and region['rect'] is not None:
                rect = region['rect']
                # 更新座標資訊
                self.main_window.coord_label.setText(
                    f'X1: {rect.x():.0f}, Y1: {rect.y():.0f}\n'
                    f'X2: {rect.x() + rect.width():.0f}, Y2: {rect.y() + rect.height():.0f}'
                )
                print(f"Updated coordinate display for rect: {rect}")
            else:
                print(f"Selected region has no valid rect: {region}")
                self.main_window.coord_label.setText('X1: -, Y1: -\nX2: -, Y2: -')
                
            # 更新文字內容
            text = region.get("text", region.get("Text", ""))
            self.main_window.text_input.setText(text)
            print(f"Updated text content: {text}")
            
            # 更新中文翻譯，優先使用「中文翻譯」欄位
            chinese_translation = region.get("中文翻譯", "")
            # 如果「中文翻譯」欄位為空，才使用 text 作為預設值
            if not chinese_translation:
                chinese_translation = text
            self.main_window.chinese_translation_input.setText(chinese_translation)
            print(f"Updated Chinese translation: {chinese_translation}")
        else:
            # 清空座標和文字資訊
            self.main_window.coord_label.setText('X1: -, Y1: -\nX2: -, Y2: -')
            self.main_window.text_input.setText('')
            self.main_window.chinese_translation_input.setText('')
            
    def on_region_moved(self, region):
        """文字框移動時的處理函數"""
        if region:
            rect = region['rect']
            # 更新座標資訊
            self.main_window.coord_label.setText(
                f'X1: {rect.x():.0f}, Y1: {rect.y():.0f}\n'
                f'X2: {rect.x() + rect.width():.0f}, Y2: {rect.y() + rect.height():.0f}'
            )
            
    def on_region_resized(self, region):
        """文字框大小調整時的處理函數"""
        if region:
            rect = region['rect']
            # 更新座標資訊
            self.main_window.coord_label.setText(
                f'X1: {rect.x():.0f}, Y1: {rect.y():.0f}\n'
                f'X2: {rect.x() + rect.width():.0f}, Y2: {rect.y() + rect.height():.0f}'
            )
            
    def save_changes(self):
        """保存變更"""
        if not self.main_window.book_data:
            print("No book data to save")
            return False

        current_page = self.main_window.page_combo.currentIndex()
        if current_page < 0:
            print("Invalid page index")
            return False

        try:
            print(f"開始保存變更到頁面 {current_page}")
            changes_made = 0
            page = self.main_window.book_data.get_page(current_page)
            
            if not page:
                print("No page data found")
                return False
                
            # 獲取當前文字內容和中文翻譯
            current_text = self.main_window.text_input.text()
            current_chinese_translation = self.main_window.chinese_translation_input.text()
            
            # 遍历所有元素并更新坐标
            for region in self.main_window.image_viewer.regions:
                element_index = region.get('element_index')
                if element_index is not None and element_index < len(page):
                    element = page[element_index]
                    if 'rect' in region and region['rect'] is not None:
                        rect = region['rect']
                        # 記錄更新前座標值
                        old_x1 = element.get('X1', 'N/A')
                        old_y1 = element.get('Y1', 'N/A')
                        old_x2 = element.get('X2', 'N/A')
                        old_y2 = element.get('Y2', 'N/A')
                        
                        # 更新元素的坐标 - 確保精確值轉換
                        element['X1'] = int(rect.x())
                        element['Y1'] = int(rect.y())
                        element['X2'] = int(rect.x() + rect.width())
                        element['Y2'] = int(rect.y() + rect.height())
                        
                        # 更新 JSON 中的 rect 屬性
                        element['rect'] = QRectF(
                            element['X1'],
                            element['Y1'],
                            element['X2'] - element['X1'],
                            element['Y2'] - element['Y1']
                        )
                        
                        # 輸出座標變更詳情
                        print(f"更新元素 {element_index} 座標:")
                        print(f"  原始座標: X1={old_x1}, Y1={old_y1}, X2={old_x2}, Y2={old_y2}")
                        print(f"  新座標: X1={element['X1']}, Y1={element['Y1']}, X2={element['X2']}, Y2={element['Y2']}")
                        changes_made += 1
                    
                    # 更新選中元素的文字內容和中文翻譯
                    if region == self.main_window.selected_element:
                        # 更新文字內容，確保使用正確的屬性名稱（Text或text）
                        if 'Text' in element:
                            old_text = element.get('Text', '')
                            element['Text'] = current_text
                            print(f"更新文字內容: '{old_text}' -> '{current_text}'")
                        elif 'text' in element:
                            old_text = element.get('text', '')
                            element['text'] = current_text
                            print(f"更新文字內容: '{old_text}' -> '{current_text}'")
                        else:
                            # 如果都沒有，預設使用'Text'
                            element['Text'] = current_text
                            print(f"新增文字內容: '{current_text}'")
                        
                        # 更新中文翻譯
                        old_chinese = element.get('中文翻譯', '')
                        element['中文翻譯'] = current_chinese_translation
                        print(f"更新中文翻譯: '{old_chinese}' -> '{current_chinese_translation}'")
                        changes_made += 1
            
            # 如果没有变更，显示消息
            if changes_made == 0:
                QMessageBox.information(self.main_window, "提示", "沒有需要保存的變更")
                return False
                
            # 先备份原始数据
            backup_path = self.main_window.book_data.json_path + '.bak'
            try:
                with open(self.main_window.book_data.json_path, 'r', encoding='utf-8') as f:
                    original_data = json.load(f)
                with open(backup_path, 'w', encoding='utf-8') as f:
                    json.dump(original_data, f, ensure_ascii=False, indent=2)
                print(f"建立備份檔案: {backup_path}")
            except Exception as e:
                print(f"無法建立備份: {str(e)}")
            
            # 處理元素，移除不能序列化的對象
            print("準備保存資料到JSON檔案...")
            data_to_save = []
            book_data = self.main_window.book_data
            
            # 從原始數據取得正確的頁面和元素結構
            pages_dict = {}
            
            # 取得所有頁面資料
            for page_key, page_data in book_data.pages.items():
                # 創建頁面的副本
                page_copy = []
                for elem in page_data:
                    # 創建元素的副本，並且排除 rect 屬性
                    elem_copy = {}
                    for key, value in elem.items():
                        if key != 'rect':  # 排除 rect 屬性
                            elem_copy[key] = value
                    page_copy.append(elem_copy)
                pages_dict[page_key] = page_copy
            
            # 將更改保存到JSON檔案
            try:
                # 使用 book_data 自己的保存方法，這會處理元素和頁面資料
                result = book_data.save()
                
                if result:
                    print(f"成功保存變更到 {book_data.json_path}")
                    
                    # 更新 UI 顯示
                    # 重要：確保每個元素都有 rect 屬性
                    for key, page_data in book_data.pages.items():
                        for elem in page_data:
                            if 'X1' in elem and 'Y1' in elem and 'X2' in elem and 'Y2' in elem and 'rect' not in elem:
                                elem['rect'] = QRectF(
                                    elem['X1'],
                                    elem['Y1'],
                                    elem['X2'] - elem['X1'],
                                    elem['Y2'] - elem['Y1']
                                )
                    
                    # 標記所有區域為已儲存
                    for region in self.main_window.image_viewer.regions:
                        # 重要：移除 new_created 屬性，代表已儲存
                        if 'new_created' in region:
                            del region['new_created']
                    
                    return True
                else:
                    print("保存失敗")
                    QMessageBox.critical(self.main_window, "錯誤", "保存失敗")
                    return False
                    
            except Exception as e:
                print(f"保存JSON時發生錯誤: {str(e)}")
                # 如果保存失敗且有備份，恢復原始檔案
                if os.path.exists(backup_path):
                    try:
                        os.replace(backup_path, self.main_window.book_data.json_path)
                        print(f"從備份檔案恢復: {backup_path}")
                    except Exception as restore_error:
                        print(f"從備份檔案恢復時發生錯誤: {str(restore_error)}")
                QMessageBox.critical(self.main_window, "錯誤", f"保存時發生錯誤：{str(e)}")
                return False
                
        except Exception as e:
            print(f"保存變更時發生錯誤: {str(e)}")
            QMessageBox.critical(self.main_window, "錯誤", f"保存時發生錯誤：{str(e)}")
            return False