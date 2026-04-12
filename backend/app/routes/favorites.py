"""Favorites routes."""

from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..models import db, Favorite

favorites_bp = Blueprint('favorites', __name__)


@favorites_bp.route('', methods=['GET'])
@jwt_required()
def get_favorites():
    """Get the current user's favorite products."""
    user_id = int(get_jwt_identity())

    favs = (
        Favorite.query
        .filter_by(user_id=user_id)
        .order_by(Favorite.created_at.desc())
        .all()
    )

    return jsonify({
        'favorites': [f.to_dict() for f in favs],
        'count': len(favs),
    }), 200


@favorites_bp.route('/<int:product_id>', methods=['POST'])
@jwt_required()
def add_favorite(product_id):
    """Add a product to favorites."""
    user_id = int(get_jwt_identity())

    # Check if already favorited
    existing = Favorite.query.filter_by(user_id=user_id, product_id=product_id).first()
    if existing:
        return jsonify({'message': 'Already in favorites'}), 200

    fav = Favorite(user_id=user_id, product_id=product_id)
    db.session.add(fav)
    db.session.commit()

    return jsonify({
        'message': 'Added to favorites',
        'favorite': fav.to_dict(),
    }), 201


@favorites_bp.route('/<int:product_id>', methods=['DELETE'])
@jwt_required()
def remove_favorite(product_id):
    """Remove a product from favorites."""
    user_id = int(get_jwt_identity())

    fav = Favorite.query.filter_by(user_id=user_id, product_id=product_id).first()
    if not fav:
        return jsonify({'error': 'Not in favorites'}), 404

    db.session.delete(fav)
    db.session.commit()

    return jsonify({'message': 'Removed from favorites'}), 200
