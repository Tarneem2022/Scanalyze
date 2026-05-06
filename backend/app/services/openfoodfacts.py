"""OpenFoodFacts API client.

Retrieves food product data by barcode from the OpenFoodFacts database.
API docs: https://wiki.openfoodfacts.org/API
"""

import requests

BASE_URL = 'https://world.openfoodfacts.org/api/v2/product'
TIMEOUT = 15  # seconds


def fetch_product(barcode: str) -> dict | None:
    """Fetch a product from OpenFoodFacts by barcode.

    Returns a normalized dict with product info, or None if not found.
    """
    try:
        url = f'{BASE_URL}/{barcode}.json'
        response = requests.get(url, timeout=TIMEOUT, headers={
            'User-Agent': 'Scanalyze/1.0 (product safety analyzer)'
        })

        if response.status_code != 200:
            return None

        data = response.json()

        if data.get('status') != 1:
            return None

        product = data.get('product', {})

        # Extract ingredients text - prioritize English
        ingredients_text = (
            product.get('ingredients_text_en')
            or product.get('ingredients_text')
            or product.get('ingredients_text_fr')
            or ''
        )

        # Extract structured ingredients list
        structured_ingredients = []
        for ing in product.get('ingredients', []):
            name = ing.get('text', '') or ing.get('id', '').replace('en:', '')
            if name:
                structured_ingredients.append(name)

        # Build normalized result
        result = {
            'barcode': barcode,
            'name': product.get('product_name_en') or product.get('product_name') or 'Unknown Product',
            'brand': product.get('brands') or product.get('brand_owner') or '',
            'image_url': product.get('image_front_url') or product.get('image_url') or '',
            'category': _extract_category(product),
            'ingredients_text': ingredients_text,
            'structured_ingredients': structured_ingredients,
            'nutriscore_grade': product.get('nutriscore_grade'),
            'nova_group': product.get('nova_group'),
            'source': 'openfoodfacts',
        }

        return result

    except requests.RequestException:
        return None


def _extract_category(product: dict) -> str:
    """Extract all categories from product data, cleaning language prefixes."""
    categories_list = []
    
    # Try categories hierarchy first
    categories = product.get('categories_hierarchy', [])
    if categories:
        for cat in categories:
            if ':' in cat:
                cat = cat.split(':', 1)[1]
            categories_list.append(cat.replace('-', ' ').title())
        return ', '.join(categories_list)

    # Fallback to categories string
    cats = product.get('categories', '')
    if cats:
        for cat in cats.split(','):
            cat = cat.strip()
            if ':' in cat:
                cat = cat.split(':', 1)[1]
            categories_list.append(cat.replace('-', ' ').title())
        return ', '.join(categories_list)

    return ''
