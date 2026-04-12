"""Database models package."""

from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

from .user import User
from .product import Product
from .ingredient import Ingredient
from .product_ingredient import ProductIngredient
from .analysis import AnalysisResult
from .preference import UserPreference
from .favorite import Favorite
from .history import History

__all__ = [
    'db', 'User', 'Product', 'Ingredient', 'ProductIngredient',
    'AnalysisResult', 'UserPreference', 'Favorite', 'History',
]
