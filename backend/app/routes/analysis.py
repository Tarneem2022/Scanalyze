"""Analysis routes - safety evaluation and comparison."""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..models import db, Product, AnalysisResult, History
from ..services.risk_engine import evaluate_product

analysis_bp = Blueprint('analysis', __name__)


@analysis_bp.route('/analyze', methods=['POST'])
@jwt_required()
def analyze_product():
    """Run safety analysis on a product.

    Expected JSON body:
    {
        "product_id": 123
    }
    """
    user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data or 'product_id' not in data:
        return jsonify({'error': 'product_id is required'}), 400

    product_id = data['product_id']
    product = Product.query.get(product_id)

    if not product:
        return jsonify({'error': 'Product not found'}), 404

    # Run the safety analysis
    result = evaluate_product(product, user_id)

    # Auto-save to history
    history_entry = History(
        user_id=user_id,
        product_id=product.id,
        analysis_id=result.id,
    )
    db.session.add(history_entry)
    db.session.commit()

    return jsonify({
        'analysis': result.to_dict(),
        'product': product.to_dict(),
    }), 200


@analysis_bp.route('/<int:analysis_id>', methods=['GET'])
@jwt_required()
def get_analysis(analysis_id):
    """Get a specific analysis result."""
    user_id = int(get_jwt_identity())
    result = AnalysisResult.query.filter_by(id=analysis_id, user_id=user_id).first()

    if not result:
        return jsonify({'error': 'Analysis not found'}), 404

    product = Product.query.get(result.product_id)

    return jsonify({
        'analysis': result.to_dict(),
        'product': product.to_dict() if product else None,
    }), 200


@analysis_bp.route('/compare', methods=['POST'])
@jwt_required()
def compare_products():
    """Compare two products side by side.

    Expected JSON body:
    {
        "product_id_1": 123,
        "product_id_2": 456
    }
    """
    user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data:
        return jsonify({'error': 'Request body is required'}), 400

    pid1 = data.get('product_id_1')
    pid2 = data.get('product_id_2')

    if not pid1 or not pid2:
        return jsonify({'error': 'Both product_id_1 and product_id_2 are required'}), 400

    product1 = Product.query.get(pid1)
    product2 = Product.query.get(pid2)

    if not product1:
        return jsonify({'error': f'Product {pid1} not found'}), 404
    if not product2:
        return jsonify({'error': f'Product {pid2} not found'}), 404

    # Analyze both
    result1 = evaluate_product(product1, user_id)
    result2 = evaluate_product(product2, user_id)

    # Save both to history
    for product, result in [(product1, result1), (product2, result2)]:
        h = History(user_id=user_id, product_id=product.id, analysis_id=result.id)
        db.session.add(h)
    db.session.commit()

    return jsonify({
        'comparison': {
            'product_1': {
                'product': product1.to_dict(),
                'analysis': result1.to_dict(),
            },
            'product_2': {
                'product': product2.to_dict(),
                'analysis': result2.to_dict(),
            },
        }
    }), 200
