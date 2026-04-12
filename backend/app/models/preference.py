"""User preferences model."""

import json
from datetime import datetime, timezone
from . import db


class UserPreference(db.Model):
    """Stores user allergen/avoidance preferences."""
    __tablename__ = 'user_preferences'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), unique=True, nullable=False)
    allergies_json = db.Column(db.Text, nullable=True)  # JSON array of ingredient names
    avoided_ingredients_json = db.Column(db.Text, nullable=True)  # JSON array
    custom_ingredients_json = db.Column(db.Text, nullable=True)  # JSON array of user-defined
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc),
                           onupdate=lambda: datetime.now(timezone.utc))

    @property
    def allergies(self):
        if self.allergies_json:
            return json.loads(self.allergies_json)
        return []

    @allergies.setter
    def allergies(self, value):
        self.allergies_json = json.dumps(value)

    @property
    def avoided_ingredients(self):
        if self.avoided_ingredients_json:
            return json.loads(self.avoided_ingredients_json)
        return []

    @avoided_ingredients.setter
    def avoided_ingredients(self, value):
        self.avoided_ingredients_json = json.dumps(value)

    @property
    def custom_ingredients(self):
        if self.custom_ingredients_json:
            return json.loads(self.custom_ingredients_json)
        return []

    @custom_ingredients.setter
    def custom_ingredients(self, value):
        self.custom_ingredients_json = json.dumps(value)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'allergies': self.allergies,
            'avoided_ingredients': self.avoided_ingredients,
            'custom_ingredients': self.custom_ingredients,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
