from PyQt5.QtWidgets import QWidget
from PyQt5.QtCore import Qt, QRectF, QPointF, pyqtSignal
from PyQt5.QtGui import QPainter, QImage, QColor, QPen, QBrush, QCursor
from src.utils.history_manager import HistoryManager, HistoryAction

class ImageViewer(QWidget):
    regionSelected = pyqtSignal(object)
    regionMoved = pyqtSignal(object)
    regionResized = pyqtSignal(object)
    newRegionCreated = pyqtSignal(QRectF)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.image = None
        self.current_scale = 1.0
        self.regions = []
        self.selected_region = None
        self.dragging = False
        self.resize_handle = None
        self.drag_start_pos = None
        self.original_rect = None
        self.min_scale = 0.1
        self.max_scale = 5.0
        self.image_offset = QPointF(0, 0)  # 圖片偏移量
        self.last_cursor = None  # 記錄上一次的游標狀態
        self.panning = False  # 是否正在平移圖片
        self.drawing_new_region = False
        self.drawing_start_pos = None
        self.current_drawing_rect = None
        self.is_add_mode = False  # 用於標記是否處於新增模式
        self.fix_y_enabled = False  # 是否啟用固定Y軸功能
        
        # 設置接受滑鼠追蹤
        self.setMouseTracking(True)
        
    def get_control_point(self, rect, pos, point_size=12):
        """檢查是否點擊到控制點，返回控制點位置"""
        points = [
            ('topLeft', rect.topLeft()),
            ('topRight', rect.topRight()),
            ('bottomRight', rect.bottomRight()),
            ('bottomLeft', rect.bottomLeft())
        ]
        
        for handle, point in points:
            if abs(pos.x() - point.x()) <= point_size and abs(pos.y() - point.y()) <= point_size:
                return handle
        return None
        
    def load_image(self, image_path):
        """載入圖片並自動調整縮放比例"""
        self.image = QImage(image_path)
        if self.image.isNull():
            print(f'Failed to load image: {image_path}')
            return
            
        # 計算適當的縮放比例
        self.calculate_initial_scale()
        self.image_offset = QPointF(0, 0)  # 重置偏移量
        self.update()
        
    def calculate_initial_scale(self):
        """計算適合視窗的初始縮放比例"""
        if not self.image or not self.width() or not self.height():
            return
            
        # 計算寬度和高度的縮放比例
        scale_w = self.width() / self.image.width()
        scale_h = self.height() / self.image.height()
        
        # 使用較小的縮放比例以確保圖片完全顯示
        self.current_scale = min(scale_w, scale_h) * 0.9  # 留些邊距
        self.current_scale = max(min(self.current_scale, self.max_scale), self.min_scale)
        
    def resizeEvent(self, event):
        """視窗大小改變時重新計算縮放比例"""
        super().resizeEvent(event)
        self.calculate_initial_scale()
        
    def set_regions(self, regions):
        """設置文字框列表"""
        self.regions = regions
        # 保持選中狀態
        if self.selected_region and self.selected_region.get('new_created', False):
            self.regions.append(self.selected_region)
        else:
            self.selected_region = next((r for r in regions if r.get('selected', False)), None)
            
        # 立即強制更新顯示
        self.update()
        
    def refresh_regions(self):
        """重新整理區域顯示狀態"""
        # 確保每個區域的顯示狀態正確
        for region in self.regions:
            # 確保顯示正確的選中狀態
            region['selected'] = (region == self.selected_region)
            # 移除new_created屬性
            if 'new_created' in region and not region['new_created']:
                del region['new_created']
                
        # 強制重繪
        self.update()
        
    def add_region(self, rect):
        """添加新的文字框並設置為選中狀態"""
        region = {
            'rect': rect,
            'selected': True,
            'new_created': True
        }
        self.regions.append(region)
        self.selected_region = region
        self.update()
        return region
        
    def set_add_mode(self, enabled):
        """設置是否處於新增模式"""
        self.is_add_mode = enabled
        self.setCursor(Qt.ArrowCursor)  # 保持標準游標
        
    def set_fix_y_enabled(self, enabled):
        """設置是否啟用固定Y軸功能"""
        self.fix_y_enabled = bool(enabled)
        print(f"固定Y軸功能已{'啟用' if self.fix_y_enabled else '停用'}")
        
    def paintEvent(self, event):
        if not self.image:
            return
            
        painter = QPainter(self)
        # 設置抗鋸齒
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        painter.setRenderHint(QPainter.RenderHint.SmoothPixmapTransform)
        
        # 繪製圖片
        scaled_width = int(self.image.width() * self.current_scale)
        scaled_height = int(self.image.height() * self.current_scale)
        x = int((self.width() - scaled_width) // 2 + self.image_offset.x())
        y = int((self.height() - scaled_height) // 2 + self.image_offset.y())
        painter.drawImage(x, y, self.image.scaled(scaled_width, scaled_height))
        
        # 繪製文字框
        for region in self.regions:
            # 確定文字框是否為選中狀態
            is_selected = (region == self.selected_region or 
                        region.get('selected', False) or 
                        region.get('new_created', False))
            
            if is_selected:
                pen = QPen(QColor(0, 255, 0), 2)  # 選中狀態為綠色
                brush = QBrush(QColor(255, 255, 0, 50))  # 半透明的黃色填充
            else:
                pen = QPen(QColor(0, 0, 255), 1)  # 未選中狀態為藍色
                brush = QBrush(Qt.BrushStyle.NoBrush)
                
            # 繪製文字框
            if 'rect' in region:
                # 確保 rect 是有效的 QRectF 對象
                if hasattr(region['rect'], 'isValid') and region['rect'].isValid():
                    rect = self.image_to_screen_rect(region['rect'])
                    painter.setPen(pen)
                    painter.setBrush(brush)
                    painter.drawRect(rect)
                    
                    # 如果是被選中的文字框，繪製文字標籤
                    if is_selected:
                        text = region.get('text', '')
                        if text:
                            painter.setPen(QPen(QColor(0, 0, 0)))
                            painter.drawText(int(rect.topLeft().x()), int(rect.topLeft().y() - 5), text)
                        
            # 如果是選中狀態，繪製控制點
            if is_selected and 'rect' in region and hasattr(region['rect'], 'isValid') and region['rect'].isValid():
                self.draw_control_points(painter, self.image_to_screen_rect(region['rect']))
        
        # 如果正在繪製新的文字框，繪製預覽
        if self.drawing_new_region and self.current_drawing_rect:
            pen = QPen(QColor(0, 255, 0), 2, Qt.DashLine)  # 虛線邊框
            brush = QBrush(QColor(0, 255, 0, 50))  # 半透明填充
            painter.setPen(pen)
            painter.setBrush(brush)
            
            # 轉換座標並繪製
            screen_rect = self.image_to_screen_rect(self.current_drawing_rect)
            painter.drawRect(screen_rect)
                
    def draw_control_points(self, painter, rect):
        """繪製控制點"""
        point_size = 12
        painter.setPen(QPen(QColor(255, 0, 0), 1))  # 紅色邊框
        painter.setBrush(QBrush(QColor(255, 255, 255)))  # 白色填充
        
        # 繪製四個角的控制點
        points = [
            rect.topLeft(),
            rect.topRight(),
            rect.bottomRight(),
            rect.bottomLeft()
        ]
        
        for point in points:
            x = point.x() - point_size/2
            y = point.y() - point_size/2
            painter.drawRect(int(x), int(y), point_size, point_size)
            
    def image_to_screen_coords(self, pos):
        """將圖片座標轉換為屏幕座標"""
        x = pos.x() * self.current_scale + (self.width() - self.image.width() * self.current_scale) // 2 + self.image_offset.x()
        y = pos.y() * self.current_scale + (self.height() - self.image.height() * self.current_scale) // 2 + self.image_offset.y()
        return QPointF(x, y)
        
    def screen_to_image_coords(self, pos):
        """將屏幕座標轉換為圖片座標"""
        x = (pos.x() - (self.width() - self.image.width() * self.current_scale) // 2 - self.image_offset.x()) / self.current_scale
        y = (pos.y() - (self.height() - self.image.height() * self.current_scale) // 2 - self.image_offset.y()) / self.current_scale
        return QPointF(x, y)
        
    def image_to_screen_rect(self, rect):
        """將圖片矩形轉換為屏幕矩形"""
        top_left = self.image_to_screen_coords(rect.topLeft())
        bottom_right = self.image_to_screen_coords(rect.bottomRight())
        return QRectF(top_left, bottom_right)
        
    def wheelEvent(self, event):
        """處理滾輪縮放"""
        if not self.image:
            return
            
        new_cursor = Qt.CursorShape.SizeVerCursor if event.angleDelta().y() > 0 else Qt.CursorShape.SizeAllCursor
        if self.last_cursor != new_cursor:
            self.setCursor(new_cursor)
            self.last_cursor = new_cursor
        # 獲取鼠標位置
        mouse_pos = event.pos()
        
        # 計算鼠標在圖片中的相對位置
        old_pos = self.screen_to_image_coords(mouse_pos)
        
        # 計算新的縮放比例
        factor = 1.1 if event.angleDelta().y() > 0 else 0.9
        new_scale = self.current_scale * factor
        
        # 限制縮放範圍
        if self.min_scale <= new_scale <= self.max_scale:
            self.current_scale = new_scale
            
            # 計算新的鼠標位置
            new_pos = self.screen_to_image_coords(mouse_pos)
            
            # 調整偏移量以保持鼠標位置不變
            delta = new_pos - old_pos
            self.image_offset += QPointF(delta.x() * self.current_scale, delta.y() * self.current_scale)
            
            self.update()
            
    def mousePressEvent(self, event):
        """處理滑鼠按下事件"""
        pos = event.pos()
        
        if event.button() == Qt.LeftButton:
            # 先檢查是否點擊到控制點（如果已有選中的片段）
            if self.selected_region and not self.is_add_mode:
                screen_rect = self.image_to_screen_rect(self.selected_region['rect'])
                handle = self.get_control_point(screen_rect, pos)
                if handle:
                    print(f"Clicked on resize handle: {handle}")
                    self.resize_handle = handle
                    self.drag_start_pos = pos
                    self.original_rect = self.selected_region['rect'].translated(0, 0)
                    self.dragging = False  # 確保不會同時當作拖曳
                    event.accept()
                    return
                    
            # 檢查是否點擊到現有的文字框
            clicked_on_region = False
            for region in self.regions:
                screen_rect = self.image_to_screen_rect(region['rect'])
                if screen_rect.contains(pos):
                    # 選擇文字框
                    self.selected_region = region
                    if not self.is_add_mode:
                        self.dragging = True  # 開始拖動
                    self.drag_start_pos = pos
                    self.original_rect = region['rect'].translated(0, 0)  # 複製原始矩形
                    clicked_on_region = True
                    self.regionSelected.emit(region)
                    break
                    
            if not clicked_on_region and self.is_add_mode:
                # 在新增模式下，開始繪製新的文字框前清除未保存的框
                self.regions = [region for region in self.regions if not region.get('new_created', False)]
                self.drawing_new_region = True
                self.drawing_start_pos = self.screen_to_image_coords(pos)
                self.current_drawing_rect = None
                self.selected_region = None
                event.accept()
                self.update()  # 確保立即更新顯示
                return
            elif not clicked_on_region:
                self.selected_region = None
                self.regionSelected.emit(None)
                
        elif event.button() == Qt.MouseButton.RightButton:
            self.panning = True
            self.drag_start_pos = pos
            self.setCursor(Qt.CursorShape.ClosedHandCursor)
            
        self.update()

    def mouseMoveEvent(self, event):
        """處理滑鼠移動事件"""
        # 語法護理
        pos = event.pos()
        
        if self.drawing_new_region and self.drawing_start_pos:
            # 計算當前繪製的矩形
            current_pos = self.screen_to_image_coords(event.pos())
            self.current_drawing_rect = QRectF(
                self.drawing_start_pos,
                current_pos
            ).normalized()  # normalized() 確保矩形的寬高為正值
            
            # 發出座標更新信號
            self.regionSelected.emit({
                'rect': self.current_drawing_rect,
                'is_drawing': True  # 標記這是繪製中的狀態
            })
            
            self.update()
            event.accept()
            return

        if self.panning and self.drag_start_pos:
            # 計算移動距離
            new_cursor = Qt.CursorShape.SizeAllCursor
            if self.last_cursor != new_cursor:
                self.setCursor(new_cursor)
                self.last_cursor = new_cursor
            delta = event.pos() - self.drag_start_pos
            self.image_offset += QPointF(delta.x(), delta.y())
            self.drag_start_pos = event.pos()
            self.update()
            return
            
        if not self.selected_region:
            new_cursor = Qt.CursorShape.ArrowCursor
            if self.last_cursor != new_cursor:
                self.setCursor(new_cursor)
                self.last_cursor = new_cursor
            return

        # 檢查是否在控制點上
        screen_rect = self.image_to_screen_rect(self.selected_region['rect'])
        # 如果沒有拖動或調整大小，還可以檢查游標是否在控制點上
        if not self.dragging and not self.resize_handle:
            handle = self.get_control_point(screen_rect, event.pos())
            if handle:
                new_cursor = Qt.CursorShape.CrossCursor
                if self.last_cursor != new_cursor:
                    self.setCursor(new_cursor)
                    self.last_cursor = new_cursor
                return
            
        # 檢查是否在文字框內
        if screen_rect.contains(event.pos()):
            new_cursor = Qt.CursorShape.SizeAllCursor if self.dragging else Qt.CursorShape.PointingHandCursor
            if self.last_cursor != new_cursor:
                self.setCursor(new_cursor)
                self.last_cursor = new_cursor
        else:
            new_cursor = Qt.CursorShape.ArrowCursor
            if self.dragging:
                new_cursor = Qt.CursorShape.SizeAllCursor
            elif self.resize_handle:
                new_cursor = Qt.CursorShape.CrossCursor
            if self.last_cursor != new_cursor:
                self.setCursor(new_cursor)
                self.last_cursor = new_cursor
            
        # 計算座標移動
        if not self.drag_start_pos:
            return
            
        # 計算移動距離
        delta = pos - self.drag_start_pos
        scaled_delta = QPointF(
            delta.x() / self.current_scale,
            delta.y() / self.current_scale
        )
        
        if self.resize_handle:  # 調整文字框大小
            new_rect = QRectF(self.original_rect)  # 創建一個新的 QRectF
            
            # 如果啟用了固定Y軸功能，我們需要特殊處理Y座標
            if self.fix_y_enabled:
                if self.resize_handle == 'topLeft':
                    # 只改變X軸，保持Y軸不變
                    new_rect.setLeft(self.original_rect.left() + scaled_delta.x())
                elif self.resize_handle == 'topRight':
                    # 只改變X軸，保持Y軸不變
                    new_rect.setRight(self.original_rect.right() + scaled_delta.x())
                elif self.resize_handle == 'bottomRight':
                    # 只改變X軸，保持Y軸不變
                    new_rect.setRight(self.original_rect.right() + scaled_delta.x())
                elif self.resize_handle == 'bottomLeft':
                    # 只改變X軸，保持Y軸不變
                    new_rect.setLeft(self.original_rect.left() + scaled_delta.x())
            else:
                # 原本的調整大小邏輯
                if self.resize_handle == 'topLeft':
                    new_rect.setTopLeft(self.original_rect.topLeft() + scaled_delta)
                elif self.resize_handle == 'topRight':
                    new_rect.setTopRight(self.original_rect.topRight() + scaled_delta)
                elif self.resize_handle == 'bottomRight':
                    new_rect.setBottomRight(self.original_rect.bottomRight() + scaled_delta)
                elif self.resize_handle == 'bottomLeft':
                    new_rect.setBottomLeft(self.original_rect.bottomLeft() + scaled_delta)
            
            # 確保寬高不為負
            if new_rect.width() > 0 and new_rect.height() > 0:
                # 記錄舊值，用於記錄日誌
                old_rect = QRectF(self.selected_region['rect'])
                
                # 更新選中區域的 rect
                self.selected_region['rect'] = new_rect
                
                # 同步更新與此選中區域關聯的元素座標（如果有 element_index）
                element_index = self.selected_region.get('element_index')
                if element_index is not None:
                    current_page_index = self.parent().page_combo.currentIndex() if hasattr(self.parent(), 'page_combo') else -1
                    if current_page_index >= 0 and hasattr(self.parent(), 'book_data'):
                        page = self.parent().book_data.get_page(current_page_index)
                        if page and element_index < len(page):
                            element = page[element_index]
                            if 'X1' in element and 'Y1' in element and 'X2' in element and 'Y2' in element:
                                # 直接更新元素的座標值
                                element['X1'] = int(new_rect.x())
                                element['Y1'] = int(new_rect.y())
                                element['X2'] = int(new_rect.x() + new_rect.width())
                                element['Y2'] = int(new_rect.y() + new_rect.height())
                                # 更新 rect 屬性
                                element['rect'] = QRectF(
                                    element['X1'],
                                    element['Y1'],
                                    element['X2'] - element['X1'],
                                    element['Y2'] - element['Y1']
                                )
                
                # 輸出日誌
                print(f"調整大小: {old_rect} -> {new_rect}")
                self.regionResized.emit(self.selected_region)
        
        elif self.dragging:  # 移動整個文字框
            new_rect = self.original_rect.translated(scaled_delta.x(), scaled_delta.y())
            
            # 記錄舊值，用於記錄日誌
            old_rect = QRectF(self.selected_region['rect'])
            
            # 更新選中區域的 rect
            self.selected_region['rect'] = new_rect
            
            # 同步更新與此選中區域關聯的元素座標（如果有 element_index）
            element_index = self.selected_region.get('element_index')
            if element_index is not None:
                current_page_index = self.parent().page_combo.currentIndex() if hasattr(self.parent(), 'page_combo') else -1
                if current_page_index >= 0 and hasattr(self.parent(), 'book_data'):
                    page = self.parent().book_data.get_page(current_page_index)
                    if page and element_index < len(page):
                        element = page[element_index]
                        if 'X1' in element and 'Y1' in element and 'X2' in element and 'Y2' in element:
                            # 直接更新元素的座標值
                            element['X1'] = int(new_rect.x())
                            element['Y1'] = int(new_rect.y())
                            element['X2'] = int(new_rect.x() + new_rect.width())
                            element['Y2'] = int(new_rect.y() + new_rect.height())
                            # 更新 rect 屬性
                            element['rect'] = QRectF(
                                element['X1'],
                                element['Y1'],
                                element['X2'] - element['X1'],
                                element['Y2'] - element['Y1']
                            )
            
            # 輸出日誌
            print(f"移動: {old_rect} -> {new_rect}")
            self.regionMoved.emit(self.selected_region)
        
        self.update()
 
    def mouseReleaseEvent(self, event):
        """處理滑鼠放開事件"""
        if self.drawing_new_region and event.button() == Qt.LeftButton:
            if self.current_drawing_rect and \
            self.current_drawing_rect.width() > 10 and \
            self.current_drawing_rect.height() > 10:  # 確保繪製的矩形夠大
                # 添加新文字框並設置為選中狀態
                new_region = {
                    'rect': self.current_drawing_rect,
                    'selected': True,
                    'new_created': True
                }
                self.regions.append(new_region)  # 添加到 regions 列表
                self.selected_region = new_region  # 設置為選中狀態
                
                # 發出新區域創建的信號
                self.newRegionCreated.emit(self.current_drawing_rect)
                # 發送選擇信號
                self.regionSelected.emit(new_region)
            
            # 重置繪製狀態
            self.drawing_new_region = False
            self.drawing_start_pos = None
            self.current_drawing_rect = None
            self.update()
            event.accept()
            return
            
        if event.button() == Qt.MouseButton.RightButton:
            self.panning = False
            new_cursor = Qt.CursorShape.ArrowCursor
            if self.last_cursor != new_cursor:
                self.setCursor(new_cursor)
                self.last_cursor = new_cursor
        elif event.button() == Qt.MouseButton.LeftButton:
            self.dragging = False
            self.resize_handle = None
            self.drag_start_pos = None
            self.original_rect = None