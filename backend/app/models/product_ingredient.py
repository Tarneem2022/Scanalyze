"""Product-Ingredient junction table model."""

from . import db


class ProductIngredient(db.Model):
    """Links a product to its ingredients."""
    __tablename__ = 'product_ingredients'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    product_id = db.Column(db.Integer, db.ForeignKey('products.id'), nullable=False)
    ingredient_id = db.Column(db.Integer, db.ForeignKey('ingredients.id'), nullable=True)
    raw_name = db.Column(db.String(255), nullable=False)
    is_classified = db.Column(db.Boolean, nullable=False, default=False)

    def to_dict(self):
        ingredient_data = None
        if self.ingredient:
            ingredient_data = self.ingredient.to_dict()
        return {
            'id': self.id,
            'raw_name': self.raw_name,
            'is_classified': self.is_classified,
            'ingredient': ingredient_data,
        }
