"""History routes."""

from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..models import db, History

history_bp = Blueprint('history', __name__)


@history_bp.route('', methods=['GET'])
@jwt_required()
def get_history():
    """Get the current user's analysis history, most recent first."""
    user_id = int(get_jwt_identity())

    entries = (
        History.query
        .filter_by(user_id=user_id)
        .order_by(History.viewed_at.desc())
        .limit(100)
        .all()
    )

    return jsonify({
        'history': [entry.to_dict() for entry in entries],
        'count': len(entries),
    }), 200


@history_bp.route('/<int:history_id>', methods=['DELETE'])
@jwt_required()
def delete_history_entry(history_id):
    """Delete a history entry."""
    user_id = int(get_jwt_identity())

    entry = History.query.filter_by(id=history_id, user_id=user_id).first()
    if not entry:
        return jsonify({'error': 'History entry not found'}), 404

    db.session.delete(entry)
    db.session.commit()

    return jsonify({'message': 'History entry deleted'}), 200


@history_bp.route('/clear', methods=['DELETE'])
@jwt_required()
def clear_history():
    """Clear all history for the current user."""
    user_id = int(get_jwt_identity())

    History.query.filter_by(user_id=user_id).delete()
    db.session.commit()

    return jsonify({'message': 'History cleared'}), 200
