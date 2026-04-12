"""Ingredients routes - list and search known ingredients."""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from ..models import Ingredient

ingredients_bp = Blueprint('ingredients', __name__)


@ingredients_bp.route('', methods=['GET'])
@jwt_required()
def list_ingredients():
    """List all known ingredients. Supports search filtering.

    Query params:
    - search: filter by name (optional)
    - type: filter by type (optional)
    - limit: max results (default 50)
    """
    search = request.args.get('search', '').strip()
    ing_type = request.args.get('type', '').strip().upper()
    limit = min(int(request.args.get('limit', 50)), 200)

    query = Ingredient.query

    if search:
        query = query.filter(Ingredient.name.ilike(f'%{search}%'))

    if ing_type:
        query = query.filter_by(type=ing_type)

    query = query.order_by(Ingredient.name).limit(limit)
    ingredients = query.all()

    return jsonify({
        'ingredients': [ing.to_dict() for ing in ingredients],
        'count': len(ingredients),
    }), 200
