## 應用程式說明

本應用程式是一個教材座標調整工具，使用 PyQt5 框架開發，旨在幫助使用者調整教材中文字框的座標和音訊資訊。

### 主要功能

- **載入 JSON 檔案：** 載入包含書籍資料的 JSON 檔案，其中包含圖片路徑、文字框座標、音訊檔案等資訊。
- **顯示圖片：** 顯示教材圖片，並允許使用者縮放和平移圖片。
- **文字框編輯：** 允許使用者選擇、移動和調整文字框的大小。
- **音訊播放：** 播放與選定文字框相關聯的音訊檔案。
- **編輯模式：** 提供編輯模式，用於修改文字框的類別、座標和音訊資訊。
- **新增模式：** 提供新增模式，用於繪製新的文字框，並設定文字內容、類別和音訊檔案。
- **儲存變更：** 將所有變更儲存回 JSON 檔案。

### 模組結構

- **main.py：** 應用程式的入口點，負責創建 QApplication 實例和主窗口。
- **src/main_window.py：** 應用程式的主窗口，包含圖片顯示區域、文字框編輯區域和控制面板。
- **src/widgets/image_viewer.py：** 用於顯示圖片和處理區域選擇的自定義 Widget。
- **src/utils/book_data.py：** 用於載入和管理書籍資料的類別。
- **src/audio_functions.py：** 包含音訊播放和更新功能的類別。
- **src/page_functions.py：** 包含頁面載入和管理功能的類別。
- **src/region_functions.py：** 包含區域（文字框）編輯和儲存功能的類別。
- **src/add_mode_window.py：** 實現新增模式窗口的類別。

### 文件資料夾整體架構

```
.
├── coordinate_editor.py
├── main.py
├── models.py
├── README.md
├── rename_functions.py
├── requirements.txt
├── utils.py
└── src
    ├── __init__.py
    ├── add_mode_window.py
    ├── audio_functions.py
    ├── main_window_temp.py
    ├── main_window.py
    ├── page_functions.py
    └── region_functions.py
        └── utils
            ├── __init__.py
            ├── audio_updater.py
            ├── book_data.py
            └── history_manager.py
        └── widgets
            ├── __init__.py
            └── image_viewer.py
```

### 使用方法

1. 啟動應用程式。
2. 點擊「載入 JSON 檔案」按鈕，選擇包含書籍資料的 JSON 檔案。
3. 使用頁面選擇器選擇要編輯的頁面。
4. 在編輯模式下，可以選擇現有的文字框，並修改其類別、座標和音訊資訊。
5. 在新增模式下，可以繪製新的文字框，並設定文字內容、類別和音訊檔案。
6. 點擊「保存變更」按鈕，將所有變更儲存回 JSON 檔案。

### 注意事項

- 確保 JSON 檔案的格式正確，並且包含所有必要的資訊。
- 音訊檔案必須存在於指定的路徑中。
- 在新增文字框時，必須先繪製文字框，然後才能設定文字內容和音訊檔案。
