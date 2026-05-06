"""Product routes - barcode lookup and OCR submission."""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..models import db, Product, ProductIngredient
from ..services import openfoodfacts, openbeautyfacts
from ..services.normalizer import parse_ingredients_text, normalize_name, match_ingredient

products_bp = Blueprint('products', __name__)


@products_bp.route('/barcode/<barcode>', methods=['GET'])
def get_product_by_barcode(barcode):
    """Look up a product by barcode.

    Search order:
    1. Local database (used for caching)
    2. OpenFoodFacts API
    3. OpenBeautyFacts API
    """
    # 1. Check local DB first
    product = Product.query.filter_by(barcode=barcode).first()
    if product:
        # Refresh categories from API to ensure we have the latest full list
        off_data = openfoodfacts.fetch_product(barcode)
        if off_data and off_data.get('category'):
            if product.category != off_data['category']:
                product.category = off_data['category']
                db.session.commit()
            return jsonify({'product': product.to_dict(), 'source': 'database'}), 200
        obf_data = openbeautyfacts.fetch_product(barcode)
        if obf_data and obf_data.get('category'):
            if product.category != obf_data['category']:
                product.category = obf_data['category']
                db.session.commit()
            return jsonify({'product': product.to_dict(), 'source': 'database'}), 200
        # If API fetch fails, just return cached product
        return jsonify({'product': product.to_dict(), 'source': 'database'}), 200

    # 2. Try OpenFoodFacts
    off_data = openfoodfacts.fetch_product(barcode)
    if off_data:
        product = _create_product_from_api(off_data)
        return jsonify({'product': product.to_dict(), 'source': 'openfoodfacts'}), 200

    # 3. Try OpenBeautyFacts
    obf_data = openbeautyfacts.fetch_product(barcode)
    if obf_data:
        product = _create_product_from_api(obf_data)
        return jsonify({'product': product.to_dict(), 'source': 'openbeautyfacts'}), 200

    return jsonify({'error': 'Product not found', 'barcode': barcode}), 404


@products_bp.route('/ocr', methods=['POST'])
@jwt_required()
def create_ocr_product():
    """Create a product from OCR-extracted ingredient text.

    Expected JSON body:
    {
        "name": "My Product" (optional),
        "ingredients_text": "water, sugar, salt, ..."
    }
    """
    data = request.get_json()

    if not data:
        return jsonify({'error': 'Request body is required'}), 400

    ingredients_text = data.get('ingredients_text', '').strip()
    if not ingredients_text:
        return jsonify({'error': 'ingredients_text is required'}), 400

    name = data.get('name', '').strip() or 'OCR Scanned Product'

    # Create the product
    product = Product(
        name=name,
        source='OCR',
        raw_ingredients_text=ingredients_text,
    )
    db.session.add(product)
    db.session.flush()

    # Parse and classify ingredients
    raw_names = parse_ingredients_text(ingredients_text)
    _classify_and_link_ingredients(product, raw_names)

    db.session.commit()

    return jsonify({'product': product.to_dict()}), 201


@products_bp.route('/<int:product_id>', methods=['GET'])
@jwt_required()
def get_product(product_id):
    """Get a product by its ID."""
    product = Product.query.get(product_id)
    if not product:
        return jsonify({'error': 'Product not found'}), 404

    return jsonify({'product': product.to_dict()}), 200


def _create_product_from_api(api_data: dict) -> Product:
    """Create a Product + linked ingredients from API data."""
    product = Product(
        barcode=api_data['barcode'],
        name=api_data['name'],
        brand=api_data.get('brand', ''),
        image_url=api_data.get('image_url', ''),
        category=api_data.get('category', ''),
        source='API',
        raw_ingredients_text=api_data.get('ingredients_text', ''),
    )
    db.session.add(product)
    db.session.flush()

    # Prefer text-based parsing (English) over structured ingredients
    # which may be in the product's native language
    ingredients_text = api_data.get('ingredients_text', '')
    raw_names = parse_ingredients_text(ingredients_text) if ingredients_text else []
    if not raw_names:
        raw_names = api_data.get('structured_ingredients', [])

    _classify_and_link_ingredients(product, raw_names)

    db.session.commit()
    return product


def _classify_and_link_ingredients(product: Product, raw_names: list[str]):
    """Normalize, match, and link ingredient names to a product."""
    for raw_name in raw_names:
        raw_name = raw_name.strip()
        if not raw_name:
            continue

        matched, is_exact = match_ingredient(raw_name)

        pi = ProductIngredient(
            product_id=product.id,
            raw_name=raw_name,
            ingredient_id=matched.id if matched else None,
            is_classified=matched is not None,
        )
        db.session.add(pi)
