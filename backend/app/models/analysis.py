"""Analysis result model."""

import json
from datetime import datetime, timezone
from . import db


class AnalysisResult(db.Model):
    """Stores the safety analysis result for a product."""
    __tablename__ = 'analysis_results'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    product_id = db.Column(db.Integer, db.ForeignKey('products.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    overall_score = db.Column(db.Float, nullable=False)  # 0-100
    safety_class = db.Column(db.Enum('SAFE', 'MODERATE', 'UNSAFE', name='safety_class'),
                             nullable=False)
    alerts_json = db.Column(db.Text, nullable=True)  # JSON array of alert objects
    ingredient_details_json = db.Column(db.Text, nullable=True)  # JSON array
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    history_entries = db.relationship('History', backref='analysis', cascade='all, delete-orphan')

    @property
    def alerts(self):
        if self.alerts_json:
            return json.loads(self.alerts_json)
        return []

    @alerts.setter
    def alerts(self, value):
        self.alerts_json = json.dumps(value)

    @property
    def ingredient_details(self):
        if self.ingredient_details_json:
            return json.loads(self.ingredient_details_json)
        return []

    @ingredient_details.setter
    def ingredient_details(self, value):
        self.ingredient_details_json = json.dumps(value)

    def to_dict(self):
        return {
            'id': self.id,
            'product_id': self.product_id,
            'user_id': self.user_id,
            'overall_score': self.overall_score,
            'safety_class': self.safety_class,
            'alerts': self.alerts,
            'ingredient_details': self.ingredient_details,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
