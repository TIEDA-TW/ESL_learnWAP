from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List, Optional

@dataclass
class Coordinates:
    x1: int
    y1: int
    x2: int
    y2: int

@dataclass
class TextElement:
    text: str
    category: str
    audioFile: str
    coordinates: Coordinates
    id: str
    createTime: str
    updateTime: str

@dataclass
class Page:
    image: str
    pageNumber: int
    elements: List[TextElement]
    createTime: str
    updateTime: str

@dataclass
class Metadata:
    bookId: str
    bookName: str
    totalPages: int
    version: str
    createTime: str
    updateTime: str

@dataclass
class BookData:
    pages: List[Page]
    metadata: Metadata