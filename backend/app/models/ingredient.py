"""Ingredient model."""

from . import db


class Ingredient(db.Model):
    """A known ingredient with risk data."""
    __tablename__ = 'ingredients'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(255), unique=True, nullable=False, index=True)
    normalized_name = db.Column(db.String(255), nullable=False, index=True)
    description = db.Column(db.Text, nullable=True)
    type = db.Column(db.Enum(
        'PRESERVATIVE', 'COLORANT', 'EMULSIFIER', 'FRAGRANCE',
        'SURFACTANT', 'ACID', 'ALLERGEN', 'SWEETENER', 'ANTIOXIDANT',
        'THICKENER', 'FLAVOR', 'VITAMIN', 'MINERAL', 'OIL', 'OTHER',
        name='ingredient_type'
    ), nullable=False, default='OTHER')
    risk_score = db.Column(db.Float, nullable=False, default=0.0)  # 0-10
    risk_level = db.Column(db.Enum(
        'SAFE', 'LOW', 'MODERATE', 'HIGH', 'DANGEROUS',
        name='risk_level'
    ), nullable=False, default='SAFE')
    common_aliases = db.Column(db.Text, nullable=True)  # comma-separated aliases
    source = db.Column(db.String(100), nullable=True)  # e.g. "FDA", "EWG", "manual"

    # Relationships
    product_ingredients = db.relationship('ProductIngredient', backref='ingredient')

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'normalized_name': self.normalized_name,
            'description': self.description,
            'type': self.type,
            'risk_score': self.risk_score,
            'risk_level': self.risk_level,
            'common_aliases': self.common_aliases,
        }
