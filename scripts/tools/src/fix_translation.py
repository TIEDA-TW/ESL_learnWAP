import json
import os
import shutil
from datetime import datetime

def fix_translation_source():
    """
    修正翻譯文字匯入來源，使用Chinese_Audio_File而不是中文翻譯欄位
    """
    base_dir = "D:\\click_to_read"
    book_data_dir = os.path.join(base_dir, "assets", "Book_data")
    models_dir = os.path.join(base_dir, "lib", "models")
    services_dir = os.path.join(base_dir, "lib", "services")
    screens_dir = os.path.join(base_dir, "lib", "screens", "improved")
    
    # 備份原始文件
    backup_dir = os.path.join(base_dir, "backup", f"translation_fix_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
    os.makedirs(backup_dir, exist_ok=True)
    
    # 備份模型文件
    book_models_path = os.path.join(models_dir, "book_models.dart")
    if os.path.exists(book_models_path):
        shutil.copy2(book_models_path, os.path.join(backup_dir, "book_models.dart"))
        print(f"已備份 {book_models_path} 到 {backup_dir}")
    
    # 處理JSON數據文件，添加從音頻文件中提取的翻譯
    for file_name in os.listdir(book_data_dir):
        if file_name.endswith(".json"):
            json_path = os.path.join(book_data_dir, file_name)
            
            # 備份數據文件
            shutil.copy2(json_path, os.path.join(backup_dir, file_name))
            print(f"已備份 {json_path} 到 {backup_dir}")
            
            # 讀取JSON數據
            with open(json_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # 更新數據：從Chinese_Audio_File提取翻譯
            for item in data:
                if "Chinese_Audio_File" in item and item["Chinese_Audio_File"]:
                    audio_file = item["Chinese_Audio_File"]
                    # 從音頻文件名提取翻譯文字
                    if audio_file.startswith("zh_"):
                        translation_text = audio_file[3:]  # 移除前缀 "zh_"
                        if translation_text.lower().endswith(".mp3"):
                            translation_text = translation_text[:-4]  # 移除後缀 ".mp3"
                        
                        # 更新中文翻譯
                        if "中文翻譯" in item:
                            if item["中文翻譯"] != translation_text:
                                print(f"更新翻譯: {item['中文翻譯']} -> {translation_text}")
                                item["中文翻譯"] = translation_text
            
            # 保存更新後的數據
            with open(json_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"已更新 {json_path} 中的翻譯數據")
    
    # 部署新的模型文件
    fixed_models_path = os.path.join(models_dir, "book_models_fixed.dart")
    # 檢查固定模型文件是否已存在，如果不存在則從目前已生成的文件複製
    if not os.path.exists(fixed_models_path):
        print(f"錯誤: 找不到修正後的模型文件 {fixed_models_path}")
        return False
    
    # 更新引用
    files_to_update = [
        os.path.join(services_dir, "book_service.dart"),
        os.path.join(screens_dir, "reader_screen.dart")
    ]
    
    for file_path in files_to_update:
        if os.path.exists(file_path):
            # 備份原始文件
            shutil.copy2(file_path, os.path.join(backup_dir, os.path.basename(file_path)))
            print(f"已備份 {file_path} 到 {backup_dir}")
            
            # 讀取文件內容
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 更新引用
            content = content.replace(
                "import '../models/book_models.dart';", 
                "import '../models/book_models_fixed.dart';"
            )
            content = content.replace(
                "import '../../models/book_models.dart' as models;", 
                "import '../../models/book_models_fixed.dart' as models;"
            )
            
            # 保存更新後的文件
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"已更新 {file_path} 中的引用")
    
    print("翻譯來源修正完成！")
    return True

if __name__ == "__main__":
    fix_translation_source()
