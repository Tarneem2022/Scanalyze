"""Product model."""

from datetime import datetime, timezone
from . import db


class Product(db.Model):
    """A product analyzed by the system (from API or OCR)."""
    __tablename__ = 'products'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    barcode = db.Column(db.String(50), unique=True, nullable=True, index=True)
    name = db.Column(db.String(500), nullable=False)
    brand = db.Column(db.String(255), nullable=True)
    image_url = db.Column(db.Text, nullable=True)
    category = db.Column(db.String(255), nullable=True)
    source = db.Column(db.Enum('API', 'OCR', name='product_source'), nullable=False, default='API')
    raw_ingredients_text = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    product_ingredients = db.relationship('ProductIngredient', backref='product',
                                         cascade='all, delete-orphan')
    analyses = db.relationship('AnalysisResult', backref='product', cascade='all, delete-orphan')
    favorites = db.relationship('Favorite', backref='product', cascade='all, delete-orphan')

    def to_dict(self):
        return {
            'id': self.id,
            'barcode': self.barcode,
            'name': self.name,
            'brand': self.brand,
            'image_url': self.image_url,
            'category': self.category,
            'source': self.source,
            'raw_ingredients_text': self.raw_ingredients_text,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'ingredients': [pi.to_dict() for pi in self.product_ingredients],
        }
