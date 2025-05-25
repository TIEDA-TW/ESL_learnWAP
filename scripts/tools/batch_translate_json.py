import os
import json
from glob import glob
from time import sleep
import requests

# Google Translate API Key
API_KEY = "AIzaSyDuy6Ijh1wscpxg4f5bVCQ-mWUKlH7Wj9w"
TRANSLATE_URL = "https://translation.googleapis.com/language/translate/v2"

def ai_translate(text):
    params = {
        'q': text,
        'target': 'zh-TW',
        'format': 'text',
        'key': API_KEY
    }
    try:
        response = requests.post(TRANSLATE_URL, data=params)
        if response.status_code == 200:
            result = response.json()
            return result['data']['translations'][0]['translatedText']
        else:
            print(f"翻譯失敗: {response.text}")
            return text
    except Exception as e:
        print(f"翻譯 API 錯誤: {e}")
        return text

BOOK_DATA_DIR = os.path.join(os.path.dirname(__file__), '../../assets/Book_data')
json_files = glob(os.path.join(BOOK_DATA_DIR, '*.json'))

for file_path in json_files:
    print(f"處理檔案: {file_path}")
    with open(file_path, 'r', encoding='utf-8') as f:
        try:
            data = json.load(f)
        except Exception as e:
            print(f"讀取失敗: {e}")
            continue

    # 處理每一頁、每一區塊
    modified = False
    if isinstance(data, dict) and 'pages' in data:
        for page in data['pages']:
            if 'regions' in page:
                for region in page['regions']:
                    text = region.get('Text') or region.get('text')
                    if text:
                        zh = ai_translate(text)
                        if region.get('中文翻譯') != zh:
                            region['中文翻譯'] = zh
                            modified = True
    elif isinstance(data, list):
        for item in data:
            text = item.get('Text') or item.get('text')
            if text:
                zh = ai_translate(text)
                if item.get('中文翻譯') != zh:
                    item['中文翻譯'] = zh
                    modified = True
    else:
        print(f"不支援的 JSON 結構: {file_path}")
        continue

    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"已更新: {file_path}")
    else:
        print(f"無需更新: {file_path}")
    sleep(0.1)  # 避免API流量過大，可視情況調整

print("全部處理完成！") 