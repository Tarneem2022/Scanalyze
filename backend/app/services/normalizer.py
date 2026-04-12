"""Ingredient name normalization service.

Handles cleaning, alias resolution, and fuzzy matching of ingredient names
to match them against the curated database.
"""

import re
from difflib import SequenceMatcher
from ..models import db, Ingredient


# Common aliases mapping (subset - most are in the DB's common_aliases field)
STATIC_ALIASES = {
    'aqua': 'water',
    'eau': 'water',
    'ascorbic acid': 'vitamin c',
    'tocopherol': 'vitamin e',
    'retinol': 'vitamin a',
    'sodium chloride': 'salt',
    'sucrose': 'sugar',
    'fructose': 'sugar',
    'dextrose': 'sugar',
    'glucose': 'sugar',
    'corn syrup': 'high fructose corn syrup',
    'citric acid': 'citric acid',
    'e100': 'curcumin',
    'e101': 'riboflavin',
    'e102': 'tartrazine',
    'e110': 'sunset yellow',
    'e120': 'carmine',
    'e122': 'carmoisine',
    'e124': 'ponceau 4r',
    'e129': 'allura red',
    'e131': 'patent blue v',
    'e132': 'indigo carmine',
    'e133': 'brilliant blue',
    'e150a': 'caramel color',
    'e150d': 'caramel color',
    'e160a': 'beta carotene',
    'e160b': 'annatto',
    'e170': 'calcium carbonate',
    'e200': 'sorbic acid',
    'e202': 'potassium sorbate',
    'e210': 'benzoic acid',
    'e211': 'sodium benzoate',
    'e220': 'sulfur dioxide',
    'e250': 'sodium nitrite',
    'e252': 'potassium nitrate',
    'e270': 'lactic acid',
    'e300': 'ascorbic acid',
    'e301': 'sodium ascorbate',
    'e306': 'tocopherol',
    'e322': 'lecithin',
    'e330': 'citric acid',
    'e331': 'sodium citrate',
    'e332': 'potassium citrate',
    'e338': 'phosphoric acid',
    'e339': 'sodium phosphate',
    'e340': 'potassium phosphate',
    'e341': 'calcium phosphate',
    'e400': 'alginic acid',
    'e401': 'sodium alginate',
    'e406': 'agar',
    'e407': 'carrageenan',
    'e410': 'locust bean gum',
    'e412': 'guar gum',
    'e414': 'acacia gum',
    'e415': 'xanthan gum',
    'e420': 'sorbitol',
    'e421': 'mannitol',
    'e422': 'glycerol',
    'e440': 'pectin',
    'e450': 'diphosphates',
    'e460': 'cellulose',
    'e466': 'carboxymethyl cellulose',
    'e471': 'mono- and diglycerides of fatty acids',
    'e472e': 'mono- and diacetyltartaric acid esters',
    'e500': 'sodium bicarbonate',
    'e501': 'potassium carbonate',
    'e503': 'ammonium carbonate',
    'e509': 'calcium chloride',
    'e516': 'calcium sulfate',
    'e551': 'silicon dioxide',
    'e621': 'monosodium glutamate',
    'e631': 'disodium inosinate',
    'e635': 'disodium ribonucleotides',
    'e950': 'acesulfame potassium',
    'e951': 'aspartame',
    'e952': 'cyclamate',
    'e954': 'saccharin',
    'e955': 'sucralose',
    'e960': 'steviol glycosides',
    'e965': 'maltitol',
    'e967': 'xylitol',
    'msg': 'monosodium glutamate',
    'bht': 'butylated hydroxytoluene',
    'bha': 'butylated hydroxyanisole',
    'tbhq': 'tertiary butylhydroquinone',
    'edta': 'ethylenediaminetetraacetic acid',
    'sls': 'sodium lauryl sulfate',
    'sles': 'sodium laureth sulfate',
    'peg': 'polyethylene glycol',
}


def normalize_name(raw_name: str) -> str:
    """Clean and normalize an ingredient name.

    Steps:
    1. Lowercase
    2. Remove parenthetical content (e.g., "(E330)")
    3. Strip special characters
    4. Remove common modifiers (low-fat, organic, etc.)
    5. Trim whitespace
    6. Resolve known aliases
    """
    if not raw_name:
        return ''

    name = raw_name.lower().strip()

    # Remove parenthetical content like (E330), (from milk), etc.
    name = re.sub(r'\([^)]*\)', '', name)

    # Remove bracket content like [soya]
    name = re.sub(r'\[[^\]]*\]', '', name)

    # Remove percentage/concentration info like "0.1%", "13%"
    name = re.sub(r'\d+\.?\d*\s*%', '', name)

    # Remove special characters but keep hyphens and spaces
    name = re.sub(r'[^\w\s\-]', '', name)

    # Remove common modifiers/adjectives that don't affect ingredient identity
    modifiers = [
        r'\b(organic|natural|pure|raw|refined|unrefined)\b',
        r'\b(low-fat|lowfat|low fat|nonfat|non-fat|fat-free|fatfree)\b',
        r'\b(skimmed|skim|whole|semi-skimmed|semi skimmed)\b',
        r'\b(powdered|powder|dried|dry|concentrated|concentrate)\b',
        r'\b(enriched|fortified|bleached|unbleached|hydrogenated)\b',
        r'\b(dehydrated|freeze-dried|frozen|fresh|canned)\b',
        r'\b(modified|hydrolyzed|hydrolysed|partially|fully)\b',
        r'\b(extra virgin|virgin|cold-pressed|cold pressed|expeller pressed)\b',
        r'\b(in|en|with|from|contains|and|or|of|the|a|an)\b',
    ]
    for mod in modifiers:
        name = re.sub(mod, '', name, flags=re.IGNORECASE)

    # Collapse whitespace
    name = re.sub(r'\s+', ' ', name).strip()

    # Check static aliases
    if name in STATIC_ALIASES:
        name = STATIC_ALIASES[name]

    return name


def parse_ingredients_text(text: str) -> list[str]:
    """Parse a raw ingredients string into individual ingredient names.

    Handles various separator formats:
    - Comma-separated: "water, sugar, salt"
    - Semicolon-separated: "water; sugar; salt"
    - Period-separated: "water. sugar. salt"
    - Nested parenthetical groups: "wheat flour (wheat, calcium)"
    """
    if not text:
        return []

    # Remove common prefixes
    text = re.sub(r'^ingredients?\s*:\s*', '', text, flags=re.IGNORECASE)

    # Replace semicolons and periods used as separators
    text = text.replace(';', ',')

    # Handle nested parenthetical groups - flatten them
    # "wheat flour (wheat, calcium carbonate)" → keep the main item and sub-items
    result = []
    depth = 0
    current = ''

    for char in text:
        if char == '(':
            depth += 1
            current += char
        elif char == ')':
            depth -= 1
            current += char
        elif char == ',' and depth == 0:
            item = current.strip()
            if item:
                # Remove parenthetical sub-ingredients from the main item
                clean = re.sub(r'\([^)]*\)', '', item).strip()
                if clean:
                    result.append(clean)
                # Also extract sub-ingredients
                for match in re.finditer(r'\(([^)]+)\)', item):
                    sub_items = match.group(1).split(',')
                    for sub in sub_items:
                        sub = sub.strip()
                        if sub and not sub.startswith('E') and len(sub) > 1:
                            result.append(sub)
            current = ''
        else:
            current += char

    # Don't forget the last item
    item = current.strip().rstrip('.')
    if item:
        clean = re.sub(r'\([^)]*\)', '', item).strip()
        if clean:
            result.append(clean)

    return [r for r in result if len(r) > 1]


def match_ingredient(raw_name: str, threshold: float = 0.80) -> tuple[Ingredient | None, bool]:
    """Try to match a raw ingredient name to a database ingredient.

    Returns:
        Tuple of (matched_ingredient, is_exact_match)
        If no match found, returns (None, False)
    """
    normalized = normalize_name(raw_name)
    if not normalized:
        return None, False

    # 1. Exact match on normalized_name
    exact = Ingredient.query.filter_by(normalized_name=normalized).first()
    if exact:
        return exact, True

    # 2. Check aliases in database
    all_ingredients = Ingredient.query.all()
    for ing in all_ingredients:
        if ing.common_aliases:
            aliases = [a.strip().lower() for a in ing.common_aliases.split(',')]
            if normalized in aliases:
                return ing, True

    # 3. Fuzzy match
    best_match = None
    best_score = 0.0

    for ing in all_ingredients:
        score = SequenceMatcher(None, normalized, ing.normalized_name).ratio()
        if score > best_score:
            best_score = score
            best_match = ing

        # Also check against name
        score2 = SequenceMatcher(None, normalized, ing.name.lower()).ratio()
        if score2 > best_score:
            best_score = score2
            best_match = ing

    if best_score >= threshold:
        return best_match, False

    return None, False
