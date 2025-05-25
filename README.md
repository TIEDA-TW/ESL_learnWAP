# 兒童美語點讀跟讀 Web App

本專案是一款基於 Flutter Web 的兒童英語學習應用，專為台灣兒童美語協會設計，結合「點讀」、「跟讀錄音」、「進度追蹤」等功能，支援線上互動學習與本地資料儲存。適用於桌面與行動裝置瀏覽器。

---

## 目錄結構

```bash
click_to_read_MGX/
├── .dart_tool/                   # Flutter 構建與編譯中間文件
├── .gitignore
├── README.md                     # 說明文件
├── app_error.log                 # 執行錯誤記錄
├── assets/                       # 靜態資源
│   ├── Book_data/                # 各冊課本 JSON 資料
│   ├── Books/                    # 課本圖片
│   │   ├── V1/                   # V1教材圖片
│   │   ├── P1/                   # P1教材圖片
│   │   └── ...                   # 其他教材圖片
│   ├── audio/                    # 音頻文件
│   │   ├── en/                   # 英語音頻
│   │   └── zh/                   # 中文音頻
│   ├── fonts/                    # 字型
│   ├── images/                   # 圖片
│   ├── packages/                 # 套件資源
│   └── ...
├── build/                        # Flutter Web 構建輸出
├── canvaskit/                    # WebGL/CanvasKit 執行檔
├── flutter.js                    # Flutter Web 啟動腳本
├── flutter_bootstrap.js
├── flutter_service_worker.js     # PWA 離線快取
├── github page更新流程.docx      # 部署說明
├── index.html                    # 主頁面模板
├── lib/                          # Dart 原始碼
│   ├── config/                   # 設定檔
│   │   └── app_config.dart       # 應用配置
│   ├── constants/                # 常數定義
│   │   └── book_constants.dart   # 教材管理常數
│   ├── main.dart                 # 程式進入點
│   ├── models/                   # 資料模型
│   ├── screens/                  # 各功能頁面
│   ├── services/                 # 業務邏輯/本地存取/用戶/語音等服務
│   ├── utils/                    # 工具與輔助函式
│   └── widgets/                  # 自訂 UI 元件
├── main.dart.js                  # 編譯後 JS 主程式
├── manifest.json                 # PWA 設定
├── pubspec.yaml                  # 依賴與資源配置
├── pubspec.lock                  # 依賴鎖定
├── scripts/                      # 建置/部署腳本
│   └── tools/                    # 工具腳本
├── version.json                  # 版本資訊
└── web/                          # Flutter Web 靜態資源
    ├── index.html
    └── manifest.json
```

---

## 主要功能

- **點讀功能**：
  - 點擊課文、單字或圖片，自動播放標準發音。
- **跟讀錄音**：
  - 用戶可錄製自己的發音，並即時回放對照。
- **進度追蹤**：
  - 透過本地儲存自動記錄學習進度與單字掌握情況。
- **多課本支援**：
  - 支援多冊課本切換，資料以 JSON 格式儲存於 assets/Book_data/。
- **多平台支援**：
  - 可於桌面、平板、手機等多種瀏覽器執行。
- **PWA 支援**：
  - 支援安裝為桌面/行動裝置應用，具離線快取能力。

---

## 安裝與執行

1. **環境需求**：

   - Flutter 3.0.0 以上
   - Dart 3.0.0 以上

2. **安裝依賴**：

   ```bash
   flutter pub get
   ```

3. **本地執行（Web）**：

   ```bash
   flutter run -d chrome
   ```

4. **建置 Web 版本**：
   ```bash
   flutter build web
   ```
   產出於 `build/web/` 目錄，可部署至 GitHub Pages 或其他靜態主機。

---

## 教材管理指南

本系統採用集中式教材管理，使修改教材變得簡單高效。所有教材相關配置都集中在 `lib/constants/book_constants.dart` 文件中。

### 1. 新增或移除教材

若要調整可用教材，只需修改 `BookConstants` 類中的 `enabledBooks` 列表：

```dart
static const List<String> enabledBooks = [
  // V系列 (基礎教材)
  'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'V8', 'V9',

  // P系列 (入門教材) -
  'P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'P9',


  // T系列 (主題教材) -
  'T1-1', 'T1-2', 'T1-3', 'T1-4', 'T1-5',
  'T2-1', 'T2-2', 'T2-3', 'T2-4', 'T2-5',
  'T3-1', 'T3-2', 'T3-3', 'T3-4', 'T3-5'
];
```

### 2. 新增教材步驟

1. **準備資源文件**：

   - 創建教材圖片資料夾：`assets/Books/[教材ID]/`
   - 準備教材封面圖片：`[教材ID]_00-00.jpg`
   - 準備教材數據文件：`assets/Book_data/[教材ID]_book_data.json`
   - 準備英語音頻文件：`assets/audio/en/[教材ID]/`
   - 準備中文音頻文件：`assets/audio/zh/[教材ID]/`

2. **更新 pubspec.yaml**：

   ```yaml
   assets:
     - assets/Book_data/
     - assets/Books/[教材ID]/
     - assets/audio/en/[教材ID]/
     - assets/audio/zh/[教材ID]/
   ```

3. **更新教材列表**：
   在 `lib/constants/book_constants.dart` 中的 `enabledBooks` 列表添加新教材 ID。

4. **重新編譯應用**：
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

### 3. 移除教材步驟

1. **從 `enabledBooks` 列表中移除教材 ID**：

   ```dart
   // 例如，移除 P5-P9 和所有 T 系列教材
   static const List<String> enabledBooks = [
     'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'V8', 'V9',
     'P1', 'P2', 'P3', 'P4',
     // T系列和其他P系列已被移除
   ];
   ```

2. **可選：從資產目錄移除檔案**：

   - 移除相應的圖片資料夾、音頻資料夾和數據文件可以減小應用體積。

3. **可選：更新 pubspec.yaml**：

   - 如果完全移除某個系列教材，可以從 pubspec.yaml 的 assets 列表中移除相應的資料夾引用。

4. **重新編譯應用**：
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

---

## 系統架構與依賴關係

### 核心檔案依賴關係

```
BookConstants  <-----+
    ^                |
    |                |
AppConfig ------+    |
    ^           |    |
    |           v    v
StorageService ---> HomeScreen
    ^                |
    |                v
    +-----------> BookCard
```

### 檔案依賴說明

- `BookConstants` (lib/constants/book_constants.dart)

  - 集中管理所有教材列表和相關配置
  - 被 AppConfig, StorageService, HomeScreen, BookCard 等依賴

- `AppConfig` (lib/config/app_config.dart)

  - 依賴 BookConstants 獲取教材列表
  - 提供通用配置和路徑計算

- `StorageService` (lib/services/storage_service.dart)

  - 依賴 BookConstants 獲取有效教材列表
  - 處理資源加載和檢查

- `HomeScreen` (lib/screens/improved/home_screen.dart)

  - 依賴 BookConstants 顯示教材分類和列表
  - 依賴 StorageService 載入教材數據

- `BookCard` (lib/widgets/improved/book_card.dart)
  - 依賴 BookConstants 獲取教材顯示名稱和顏色
  - 依賴 StorageService 檢查資源

### 疑似冗餘或未使用的文件

以下文件可能是冗餘的或已不再使用，可考慮整理或移除：

1. `lib/config/book_config.dart` (如果存在) - 功能已被 book_constants.dart 取代
2. `lib/services/tts_service.dart` 和 `lib/services/improved/tts_service.dart` - 可能存在重複功能
3. `lib/widgets/material_management.dart` - 功能可能被新的教材管理系統取代
4. `lib/utils/book_utils.dart` 中的 `getAllBookIds()` - 功能與 StorageService 中的方法重複

---

## 主要技術棧與依賴

- Flutter Web
- Dart
- [audioplayers](https://pub.dev/packages/audioplayers)
- [record](https://pub.dev/packages/record)
- [flutter_tts](https://pub.dev/packages/flutter_tts)
- [shared_preferences](https://pub.dev/packages/shared_preferences)
- [google_fonts](https://pub.dev/packages/google_fonts)
- 其他 UI、檔案、CSV、PWA 相關套件

---

## 進階與可擴充功能

- **語音評分**：可串接第三方 API 評分用戶發音。
- **學習數據圖表**：以圖表呈現學習成效。
- **社交分享**：分享成果至社群平台。
- **多語系支援**：可擴充多國語言學習。

---

## 聲明

本專案僅供教學與學習用途，部分資源（如課本內容、圖片、音檔）版權歸原出版社與協會所有。

如需協助或有建議，請聯絡專案維護者。
#   E S L * L e a r n W A P 
 
 #   E S L * L e a r n W A P 
 
 #   E S L _ L e a r n W A P 
 
 
#   E S L _ l e a r n W A P  
 