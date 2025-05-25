from dataclasses import dataclass
from typing import List, Any, Optional
from PyQt5.QtCore import QRectF

@dataclass
class HistoryAction:
    """歷史操作記錄"""
    action_type: str  # 'move' 或 'resize'
    region_id: str
    old_rect: QRectF
    new_rect: QRectF

class HistoryManager:
    def __init__(self, max_history: int = 50):
        self.history: List[HistoryAction] = []
        self.current_index: int = -1
        self.max_history = max_history
        
    def add_action(self, action: HistoryAction) -> None:
        """添加新的操作到歷史記錄"""
        # 如果當前不在歷史記錄末尾，刪除之後的記錄
        if self.current_index < len(self.history) - 1:
            self.history = self.history[:self.current_index + 1]
            
        # 添加新操作
        self.history.append(action)
        self.current_index = len(self.history) - 1
        
        # 如果超出最大歷史記錄數，刪除最舊的記錄
        if len(self.history) > self.max_history:
            self.history = self.history[-self.max_history:]
            self.current_index = len(self.history) - 1
        
    def can_undo(self) -> bool:
        """是否可以撤銷"""
        return self.current_index >= 0
        
    def can_redo(self) -> bool:
        """是否可以重做"""
        return self.current_index < len(self.history) - 1
        
    def undo(self) -> Optional[HistoryAction]:
        """撤銷操作"""
        if not self.can_undo():
            return None
            
        action = self.history[self.current_index]
        self.current_index -= 1
        return action
        
    def redo(self) -> Optional[HistoryAction]:
        """重做操作"""
        if not self.can_redo():
            return None
            
        self.current_index += 1
        return self.history[self.current_index]
        
    def clear(self) -> None:
        """清空歷史記錄"""
        self.history.clear()
        self.current_index = -1