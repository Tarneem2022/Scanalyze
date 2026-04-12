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

        result = {
            'barcode': barcode,
            'name': product.get('product_name_en') or product.get('product_name') or 'Unknown Product',
            'brand': product.get('brands') or '',
            'image_url': product.get('image_front_url') or product.get('image_url') or '',
            'category': product.get('categories', '').split(',')[0].strip() if product.get('categories') else '',
            'ingredients_text': ingredients_text,
            'structured_ingredients': structured_ingredients,
            'source': 'openbeautyfacts',
        }

        return result

    except requests.RequestException:
        return None
