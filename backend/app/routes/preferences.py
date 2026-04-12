"""User preferences routes."""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..models import db, UserPreference

preferences_bp = Blueprint('preferences', __name__)


@preferences_bp.route('', methods=['GET'])
@jwt_required()
def get_preferences():
    """Get the current user's preferences."""
    user_id = int(get_jwt_identity())
    prefs = UserPreference.query.filter_by(user_id=user_id).first()

    if not prefs:
        # Create default preferences
        prefs = UserPreference(user_id=user_id)
        prefs.allergies = []
        prefs.avoided_ingredients = []
        prefs.custom_ingredients = []
        db.session.add(prefs)
        db.session.commit()

    return jsonify({'preferences': prefs.to_dict()}), 200


@preferences_bp.route('', methods=['PUT'])
@jwt_required()
def update_preferences():
    """Update the current user's preferences.

    Expected JSON body (all fields optional):
    {
        "allergies": ["peanut", "soy"],
        "avoided_ingredients": ["palm oil"],
        "custom_ingredients": [{"name": "my custom ing", "risk_score": 5}]
    }
    """
    user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data:
        return jsonify({'error': 'Request body is required'}), 400

    prefs = UserPreference.query.filter_by(user_id=user_id).first()

    if not prefs:
        prefs = UserPreference(user_id=user_id)
        db.session.add(prefs)

    if 'allergies' in data:
        prefs.allergies = data['allergies']

    if 'avoided_ingredients' in data:
        prefs.avoided_ingredients = data['avoided_ingredients']

    if 'custom_ingredients' in data:
        prefs.custom_ingredients = data['custom_ingredients']

    db.session.commit()

    return jsonify({
        'message': 'Preferences updated',
        'preferences': prefs.to_dict(),
    }), 200
