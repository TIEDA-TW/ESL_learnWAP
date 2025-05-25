from PyQt5.QtWidgets import QFileDialog, QMessageBox
from PyQt5.QtMultimedia import QMediaPlayer, QMediaContent
from PyQt5.QtCore import QUrl
import os
import json
import shutil
from datetime import datetime

class AudioFunctions:
    def __init__(self, main_window):
        self.main_window = main_window
        self.media_player = QMediaPlayer()
        
    def play_audio(self):
        """播放音檔"""
        if not self.main_window.selected_element or not self.main_window.book_data:
            print("No selected element or book data")
            return
            
        current_page = self.main_window.page_combo.currentIndex()
        if current_page < 0:
            print("Invalid page index")
            return
            
        # 先清除當前的媒體內容
        self.media_player.stop()
        self.media_player.setMedia(QMediaContent())
            
        try:
            # 直接使用選中元素的音檔資訊
            audio_file = self.main_window.selected_element.get("audioFile", 
                       self.main_window.selected_element.get("English_Audio_File", None))
            
            if not audio_file:
                print("No audio file specified in the selected element")
                return
                
            # 可能的音檔路徑
            possible_paths = [
                # 無視 book_id 的路徑
                os.path.join("D:/click_to_read/assets/audio/en", audio_file),
                # 使用 V1 或 V2 作為子目錄
                os.path.join("D:/click_to_read/assets/audio/en/V1", audio_file),
                os.path.join("D:/click_to_read/assets/audio/en/V2", audio_file),
            ]
            
            # 如果知道 book_id，也嘗試使用它
            if hasattr(self.main_window.book_data, 'book_id'):
                book_id = self.main_window.book_data.book_id
                possible_paths.append(os.path.join("D:/click_to_read/assets/audio/en", book_id, audio_file))
            
            # 嘗試所有可能的路徑
            audio_path = None
            for path in possible_paths:
                if os.path.exists(path):
                    audio_path = path
                    break
                    
            if audio_path:
                print(f'播放音檔: {audio_path}')
                self.media_player.setMedia(QMediaContent(QUrl.fromLocalFile(audio_path)))
                self.media_player.play()
            else:
                print(f'音檔不存在: {audio_file}, 嘗試了路徑: {possible_paths}')
        except Exception as e:
            print(f'播放音檔錯誤: {str(e)}')
            
    def update_audio(self):
        """更新音檔"""
        if not self.main_window.selected_element:
            print("No selected element")
            return
            
        try:
            current_page = self.main_window.page_combo.currentIndex()
            if current_page < 0:
                print("Invalid page index")
                return
                
            # 選擇新的音檔
            file_dialog = QFileDialog()
            audio_file, _ = file_dialog.getOpenFileName(
                None,
                "選擇音檔",
                "D:/click_to_read/assets/audio/",
                "Audio Files (*.wav *.mp3 *.ogg)"
            )
            
            if not audio_file:
                print("No audio file selected")
                return
            
            # 取得檔案名
            filename = os.path.basename(audio_file)
            print(f"Selected new audio file: {filename}")
            
            # 更新選定元素的音檔資訊
            self.main_window.selected_element['audioFile'] = filename
            self.main_window.selected_element['English_Audio_File'] = filename  # 同時更新两個屬性
            
            # 如果有原始 JSON 元素，也更新它
            page = self.main_window.book_data.get_page(current_page)
            if page:
                element_index = self.main_window.selected_element.get('element_index')
                if element_index is not None and element_index < len(page):
                    # 更新原始元素
                    orig_element = page[element_index]
                    orig_element['English_Audio_File'] = filename
                    if 'audioFile' in orig_element:
                        orig_element['audioFile'] = filename
                    print(f"Updated original JSON element: {orig_element}")
                    
            # 保存到 JSON 文件
            # 先备份原始文件
            backup_path = self.main_window.book_data.json_path + '.bak'
            try:
                with open(self.main_window.book_data.json_path, 'r', encoding='utf-8') as f:
                    original_data = json.load(f)
                with open(backup_path, 'w', encoding='utf-8') as f:
                    json.dump(original_data, f, ensure_ascii=False, indent=2)
                print(f"Created backup at {backup_path}")
            except Exception as e:
                print(f"Could not create backup: {str(e)}")
            
            # 处理元素，移除不能序列化的对象
            data_to_save = []
            for elem in self.main_window.book_data.elements:
                # 创建仅包含可序列化数据的副本
                elem_copy = {}
                for key, value in elem.items():
                    # 跳过rect属性，它是QRectF对象，不能被序列化
                    if key != 'rect':
                        elem_copy[key] = value
                data_to_save.append(elem_copy)
            
            try:
                with open(self.main_window.book_data.json_path, 'w', encoding='utf-8') as f:
                    json.dump(data_to_save, f, ensure_ascii=False, indent=2)
                print(f"Saved changes to {self.main_window.book_data.json_path}")
                
                # 更新数据引用
                self.main_window.book_data.elements = data_to_save
                
                # 重新加载页面以显示更新后的音频文件
                self.main_window.loadPage(current_page)
            except Exception as e:
                print(f"Error saving JSON: {str(e)}")
                # 如果保存失败且有备份，恢复原始文件
                if os.path.exists(backup_path):
                    try:
                        os.replace(backup_path, self.main_window.book_data.json_path)
                        print(f"Restored from backup {backup_path}")
                    except Exception as restore_error:
                        print(f"Error restoring from backup: {str(restore_error)}")
                QMessageBox.critical(None, "錯誤", f"保存時發生錯誤：{str(e)}")
            
            # 更新音檔標籤顯示
            self.main_window.audio_label.setText(f'音檔: {filename}')
            
            # 在預覽中播放新音檔
            self.play_audio()
            
            # 顯示成功消息
            QMessageBox.information(None, "成功", "音檔已更新")
                
        except Exception as e:
            QMessageBox.critical(None, "錯誤", f"更新音檔時發生錯誤：{str(e)}")

    def on_audio_updated(self, page_index, element_index):
        """音檔更新完成後的回調函數"""
        # 停止當前播放並清除媒體內容
        self.media_player.stop()
        self.media_player.setMedia(QMediaContent())
        
        # 重新載入當前頁面
        self.main_window.loadPage(page_index)
        
        # 重新選擇原來的文字框
        for region in self.main_window.image_viewer.regions:
            if region.get('element_index') == element_index:
                self.main_window.onRegionSelected(region)
                break