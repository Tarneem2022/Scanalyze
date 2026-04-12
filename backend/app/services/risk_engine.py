"""Safety risk evaluation engine.

Computes overall product safety scores based on ingredient risks
and user-specific preferences (allergies, avoided ingredients).
"""

from ..models import db, Product, ProductIngredient, Ingredient, UserPreference, AnalysisResult
from .normalizer import normalize_name


def evaluate_product(product: Product, user_id: int) -> AnalysisResult:
    """Run the full safety analysis pipeline on a product for a given user.

    Algorithm:
    1. Score each ingredient individually (0-10 risk)
    2. Calculate weighted base score (100 - avg_risk * 10)
    3. Apply user preference penalties (allergies, avoided)
    4. Generate alerts
    5. Classify overall safety (SAFE/MODERATE/UNSAFE)
    """
    # Load user preferences
    prefs = UserPreference.query.filter_by(user_id=user_id).first()
    user_allergies = []
    user_avoided = []
    if prefs:
        user_allergies = [normalize_name(a) for a in prefs.allergies]
        user_avoided = [normalize_name(a) for a in prefs.avoided_ingredients]

    # Analyze each ingredient
    ingredient_details = []
    risk_scores = []
    alerts = []
    total_risk = 0.0
    classified_count = 0

    for pi in product.product_ingredients:
        detail = {
            'raw_name': pi.raw_name,
            'is_classified': pi.is_classified,
            'risk_score': 5.0,  # default for unclassified
            'risk_level': 'UNKNOWN',
            'type': 'OTHER',
            'description': None,
        }

        if pi.is_classified and pi.ingredient:
            ing = pi.ingredient
            detail['risk_score'] = ing.risk_score
            detail['risk_level'] = ing.risk_level
            detail['type'] = ing.type
            detail['description'] = ing.description
            detail['matched_name'] = ing.name
            risk_scores.append(ing.risk_score)
            classified_count += 1
        else:
            # Unclassified ingredient gets neutral risk
            detail['risk_level'] = 'UNKNOWN'
            risk_scores.append(5.0)

        total_risk += detail['risk_score']

        # Check against user preferences
        normalized = normalize_name(pi.raw_name)

        # Also check matched ingredient name
        check_names = [normalized]
        if pi.is_classified and pi.ingredient:
            check_names.append(pi.ingredient.normalized_name)
            if pi.ingredient.common_aliases:
                check_names.extend(
                    a.strip().lower() for a in pi.ingredient.common_aliases.split(',')
                )

        # Allergy check
        for allergy in user_allergies:
            if any(allergy in cn or cn in allergy for cn in check_names):
                alerts.append({
                    'severity': 'DANGER',
                    'type': 'ALLERGY',
                    'ingredient': pi.raw_name,
                    'message': f'⚠️ ALLERGY ALERT: "{pi.raw_name}" matches your allergy "{allergy}"',
                })
                break

        # Avoided ingredient check
        for avoided in user_avoided:
            if any(avoided in cn or cn in avoided for cn in check_names):
                alerts.append({
                    'severity': 'WARNING',
                    'type': 'AVOIDED',
                    'ingredient': pi.raw_name,
                    'message': f'⚡ AVOIDED: "{pi.raw_name}" is in your avoided ingredients list',
                })
                break

        # High-risk ingredient alert
        if detail['risk_score'] >= 7.0 and pi.is_classified:
            alerts.append({
                'severity': 'WARNING',
                'type': 'HIGH_RISK',
                'ingredient': pi.raw_name,
                'message': f'🔴 HIGH RISK: "{pi.raw_name}" has a risk score of {detail["risk_score"]}/10',
            })

        ingredient_details.append(detail)

    # Calculate base safety score
    num_ingredients = len(product.product_ingredients)
    if num_ingredients > 0:
        avg_risk = total_risk / num_ingredients
        base_score = 100.0 - (avg_risk * 10.0)
    else:
        base_score = 50.0  # No ingredients = uncertain

    # Apply preference penalties
    allergy_count = sum(1 for a in alerts if a['type'] == 'ALLERGY')
    avoided_count = sum(1 for a in alerts if a['type'] == 'AVOIDED')

    score = base_score
    score -= allergy_count * 30.0  # Heavy penalty for allergens
    score -= avoided_count * 15.0  # Moderate penalty for avoided

    # Clamp to [0, 100]
    score = max(0.0, min(100.0, score))

    # Classify
    if score >= 70:
        safety_class = 'SAFE'
    elif score >= 40:
        safety_class = 'MODERATE'
    else:
        safety_class = 'UNSAFE'

    # Add summary alert if many unclassified ingredients
    unclassified = num_ingredients - classified_count
    if unclassified > 0:
        pct = (unclassified / num_ingredients * 100) if num_ingredients > 0 else 0
        alerts.append({
            'severity': 'INFO',
            'type': 'UNCLASSIFIED',
            'ingredient': None,
            'message': f'ℹ️ {unclassified} ingredient(s) ({pct:.0f}%) could not be identified in our database',
        })

    # Create and save the analysis result
    result = AnalysisResult(
        product_id=product.id,
        user_id=user_id,
        overall_score=round(score, 1),
        safety_class=safety_class,
    )
    result.alerts = alerts
    result.ingredient_details = ingredient_details

    db.session.add(result)
    db.session.commit()

    return result
