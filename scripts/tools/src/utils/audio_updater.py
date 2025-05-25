import os
import shutil
import gc
import time
from datetime import datetime
import soundfile as sf
from PyQt5.QtWidgets import QFileDialog, QMessageBox
from PyQt5.QtMultimedia import QMediaPlayer

class AudioUpdater:
    def __init__(self, book_data):
        self.book_data = book_data
        self.supported_formats = ['.wav', '.mp3', '.ogg']
        self.current_player = None
        self.update_callback = None
        
    def set_update_callback(self, callback):
        """設置更新完成後的回調函數"""
        self.update_callback = callback
        
    def update_audio(self, page_index: int, element_index: int) -> bool:
        """更新指定元素的音檔"""
        try:
            # 1. 停止播放並釋放資源
            if hasattr(self, 'current_player') and self.current_player:
                self.current_player.stop()
                self.current_player = None
            gc.collect()
            
            # 2. 獲取元素資訊
            page = self.book_data.get_page(page_index)
            if not page or 'elements' not in page:
                raise ValueError("無效的頁面索引")
                
            element = page['elements'][element_index]
            original_filename = element['audioFile']
            
            # 3. 準備路徑
            book_id = self.book_data.get_book_id()
            target_dir = os.path.join(
                os.path.dirname(os.path.dirname(self.book_data.json_path)),
                'processed_audio',
                book_id
            )
            os.makedirs(target_dir, exist_ok=True)
            
            original_path = os.path.join(target_dir, original_filename)
            temp_path = os.path.join(target_dir, f"temp_{original_filename}")
            
            # 4. 選擇新音檔
            file_dialog = QFileDialog()
            file_dialog.setFileMode(QFileDialog.ExistingFile)
            file_dialog.setNameFilter("Audio Files (*.wav *.mp3 *.ogg)")
            
            if not file_dialog.exec_():
                return False
                
            new_audio_file = file_dialog.selectedFiles()[0]
            if not new_audio_file:
                return False
                
            # 5. 驗證格式
            file_ext = os.path.splitext(new_audio_file)[1].lower()
            if file_ext not in self.supported_formats:
                QMessageBox.warning(None, "格式錯誤", 
                                  f"不支援的音檔格式: {file_ext}\n" +
                                  f"支援的格式: {', '.join(self.supported_formats)}")
                return False
            
            # 6. 驗證並複製新檔案
            try:
                # 先驗證新音檔
                with sf.SoundFile(new_audio_file) as _:
                    pass
                
                # 複製到臨時位置
                shutil.copy2(new_audio_file, temp_path)
                
            except Exception as e:
                if os.path.exists(temp_path):
                    os.remove(temp_path)
                raise Exception(f"新音檔無效: {str(e)}")
            
            # 7. 安全替換檔案
            max_retries = 3
            for retry in range(max_retries):
                try:
                    # 如果原檔案存在，先等待一下再刪除
                    if os.path.exists(original_path):
                        time.sleep(0.2)
                        os.remove(original_path)
                    
                    # 重命名臨時檔案
                    time.sleep(0.2)
                    os.rename(temp_path, original_path)
                    break
                    
                except Exception as e:
                    if retry == max_retries - 1:
                        if os.path.exists(temp_path):
                            os.remove(temp_path)
                        raise e
                    time.sleep(0.5)  # 重試前等待更長時間
            
            # 8. 更新元素資訊並保存
            element['updateTime'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            if not self.book_data.save():
                raise Exception("保存 JSON 檔案失敗")
            
            # 9. 執行回調並通知
            if self.update_callback:
                self.update_callback(page_index, element_index)
            
            QMessageBox.information(None, "成功", "音檔更新成功！")
            return True
            
        except Exception as e:
            QMessageBox.critical(None, "錯誤", f"更新音檔時發生錯誤：{str(e)}")
            return False
            
    def validate_audio_file(self, file_path: str) -> bool:
        """驗證音檔是否有效"""
        try:
            if not os.path.exists(file_path):
                return False
                
            file_ext = os.path.splitext(file_path)[1].lower()
            if file_ext not in self.supported_formats:
                return False
                
            with sf.SoundFile(file_path) as _:
                return True
                
        except Exception:
            return False