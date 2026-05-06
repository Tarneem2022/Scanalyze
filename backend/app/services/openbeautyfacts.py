"""OpenBeautyFacts API client.

Retrieves cosmetic/beauty product data by barcode from OpenBeautyFacts.
API docs: https://world.openbeautyfacts.org/
"""

import requests

BASE_URL = 'https://world.openbeautyfacts.org/api/v2/product'
TIMEOUT = 15  # seconds


def fetch_product(barcode: str) -> dict | None:
    """Fetch a cosmetic product from OpenBeautyFacts by barcode.

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

        # Extract ingredients text
        ingredients_text = (
            product.get('ingredients_text_en')
            or product.get('ingredients_text')
            or ''
        )

        # Extract structured ingredients
        structured_ingredients = []
        for ing in product.get('ingredients', []):
            name = ing.get('text', '') or ing.get('id', '').replace('en:', '')
            if name:
                structured_ingredients.append(name)

        # Extract categories - prefer hierarchy (full list) over plain categories
        cats_list = []
        categories_hierarchy = product.get('categories_hierarchy', [])
        if categories_hierarchy:
            for cat in categories_hierarchy:
                if ':' in cat:
                    cat = cat.split(':', 1)[1]
                cats_list.append(cat.replace('-', ' ').title())
        else:
            raw_cats = product.get('categories', '')
            if raw_cats:
                for cat in raw_cats.split(','):
                    cat = cat.strip()
                    if ':' in cat:
                        cat = cat.split(':', 1)[1]
                    cats_list.append(cat.replace('-', ' ').title())
        category_str = ', '.join(cats_list)

        result = {
            'barcode': barcode,
            'name': product.get('product_name_en') or product.get('product_name') or 'Unknown Product',
            'brand': product.get('brands') or '',
            'image_url': product.get('image_front_url') or product.get('image_url') or '',
            'category': category_str,
            'ingredients_text': ingredients_text,
            'structured_ingredients': structured_ingredients,
            'source': 'openbeautyfacts',
        }

        return result

    except requests.RequestException:
        return None
