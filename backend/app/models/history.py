"""History model."""

from datetime import datetime, timezone
from . import db


class History(db.Model):
    """Track which products a user has analyzed."""
    __tablename__ = 'history'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey('products.id'), nullable=False)
    analysis_id = db.Column(db.Integer, db.ForeignKey('analysis_results.id'), nullable=True)
    viewed_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationship to product (not defined via backref on Product to avoid clutter)
    product = db.relationship('Product', backref='history_entries')

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'product_id': self.product_id,
            'analysis_id': self.analysis_id,
            'product': self.product.to_dict() if self.product else None,
            'analysis': self.analysis.to_dict() if self.analysis else None,
            'viewed_at': self.viewed_at.isoformat() if self.viewed_at else None,
        }
