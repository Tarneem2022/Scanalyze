"""Seed the ingredients database with curated data."""

import json
import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app
from app.models import db, Ingredient
from app.services.normalizer import normalize_name


def seed_ingredients():
    """Seed ingredients from JSON file."""
    app = create_app()

    seed_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ingredients.json')

    with open(seed_file, 'r', encoding='utf-8') as f:
        ingredients_data = json.load(f)

    with app.app_context():
        added = 0
        skipped = 0

        for item in ingredients_data:
            # Check if already exists
            existing = Ingredient.query.filter_by(name=item['name']).first()
            if existing:
                skipped += 1
                continue

            ingredient = Ingredient(
                name=item['name'],
                normalized_name=normalize_name(item['name']),
                description=item.get('description', ''),
                type=item['type'],
                risk_score=item['risk_score'],
                risk_level=item['risk_level'],
                common_aliases=item.get('aliases', ''),
                source='seed_data',
            )
            db.session.add(ingredient)
            added += 1

        db.session.commit()
        print(f'Seeding complete: {added} added, {skipped} skipped (already exist)')
        print(f'Total ingredients in database: {Ingredient.query.count()}')


if __name__ == '__main__':
    seed_ingredients()
