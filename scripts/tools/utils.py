import os
import json
from datetime import datetime
from typing import Optional
import soundfile as sf
from PIL import Image
from models import BookData, Page, TextElement, Coordinates, Metadata

class BookDataManager:
    def __init__(self, json_path: str):
        self.json_path = json_path
        self.book_data: Optional[BookData] = None
        self.base_path = os.path.dirname(os.path.dirname(json_path))
        
    def load_data(self) -> BookData:
        """載入JSON檔案並解析為BookData物件"""
        with open(self.json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            self.book_data = BookData(**data)
            return self.book_data
            
    def save_data(self) -> None:
        """保存BookData物件到JSON檔案"""
        if not self.book_data:
            raise ValueError("No data to save")
            
        # 更新時間戳
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.book_data.metadata.updateTime = current_time
        
        # 建立暫存檔案
        temp_path = self.json_path + '.tmp'
        try:
            with open(temp_path, 'w', encoding='utf-8') as f:
                json.dump(self.book_data.__dict__, f, ensure_ascii=False, indent=2)
                
            # 成功寫入後替換原檔案
            os.replace(temp_path, self.json_path)
        except Exception as e:
            if os.path.exists(temp_path):
                os.remove(temp_path)
            raise e
            
    def verify_resources(self) -> bool:
        """驗證相關資源檔案是否存在"""
        if not self.book_data:
            return False
            
        book_id = self.book_data.metadata.bookId
        
        for page in self.book_data.pages:
            # 驗證圖片檔案
            image_path = os.path.join(self.base_path, 'books', book_id, page.image)
            if not os.path.exists(image_path):
                print(f"Missing image: {image_path}")
                return False
                
            # 驗證音檔
            for element in page.elements:
                audio_path = os.path.join(self.base_path, 'processed_audio', 
                                        book_id, element.audioFile)
                if not os.path.exists(audio_path):
                    print(f"Missing audio: {audio_path}")
                    return False
                    
        return True
        
    def get_image_size(self, page_number: int) -> tuple[int, int]:
        """獲取指定頁面圖片的尺寸"""
        if not self.book_data:
            raise ValueError("No data loaded")
            
        page = next((p for p in self.book_data.pages if p.pageNumber == page_number), None)
        if not page:
            raise ValueError(f"Page {page_number} not found")
            
        image_path = os.path.join(self.base_path, 'books', 
                                 self.book_data.metadata.bookId, page.image)
        with Image.open(image_path) as img:
            return img.size
            
    def validate_coordinates(self, coordinates: Coordinates, 
                           image_width: int, image_height: int) -> bool:
        """驗證座標是否在有效範圍內"""
        return (0 <= coordinates.x1 < coordinates.x2 <= image_width and
                0 <= coordinates.y1 < coordinates.y2 <= image_height)
                
    def play_audio(self, audio_file: str) -> None:
        """播放音檔"""
        if not self.book_data:
            raise ValueError("No data loaded")
            
        audio_path = os.path.join(self.base_path, 'processed_audio',
                                 self.book_data.metadata.bookId, audio_file)
        data, samplerate = sf.read(audio_path)
        # TODO: 實現音檔播放功能