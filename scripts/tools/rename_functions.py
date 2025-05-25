import re

def convert_to_camel_case(name):
    # 將底線式命名轉換為駝峰式命名
    components = name.split('_')
    # 確保所有組件的首字母大寫
    return ''.join(x.title() for x in components)

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    # 需要替換的函數名列表及其對應的新名稱
    name_mappings = {
        'init_ui': 'InitUI',
        'load_json': 'LoadJson',
        'load_page': 'LoadPage',
        'on_page_changed': 'OnPageChanged',
        'on_category_changed': 'OnCategoryChanged',
        'on_region_selected': 'OnRegionSelected',
        'on_region_moved': 'OnRegionMoved',
        'on_region_resized': 'OnRegionResized',
        'on_audio_updated': 'OnAudioUpdated',
        'update_audio': 'UpdateAudio',
        '_do_update_audio': 'DoUpdateAudio',
        'save_changes': 'SaveChanges'
    }

    # 進行替換
    for old_name, new_name in name_mappings.items():
        # 替換函數定義
        content = re.sub(
            f'def {old_name}\\(',
            f'def {new_name}(',
            content
        )
        
        # 替換函數調用
        content = re.sub(
            f'self\.{old_name}\\(',
            f'self.{new_name}(',
            content
        )
        
        # 替換函數名稱在其他地方的引用
        content = re.sub(
            f'self\.{old_name}',
            f'self.{new_name}',
            content
        )
        
        # 替換事件連接
        content = re.sub(
            f'connect\(self\.{old_name}\)',
            f'connect(self.{new_name})',
            content
        )

    # 保存更改
    with open(file_path, 'w', encoding='utf-8') as file:
        file.write(content)

if __name__ == '__main__':
    # 處理主窗口文件
    process_file('src/main_window.py')
    print('函數名稱更新完成！')