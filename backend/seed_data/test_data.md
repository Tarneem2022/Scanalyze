# Scanalyze — Test Data

All barcodes below have been verified against the live backend. They fetch real products from OpenFoodFacts.

## Test Account

| Field | Value |
|---|---|
| Email | `test@scanalyze.com` |
| Password | `test123` |
| Name | Test User |

---

## ✅ Verified Barcodes (Food Products)

| Barcode | Product | Brand | Ingredients | Score | Safety |
|---|---|---|---|---|---|
| `5449000000996` | Coca-Cola Original | Coca-Cola | 8 | 53.1 | ⚠️ MODERATE |
| `5449000131805` | Coca-Cola Zero Sugar | Coca-Cola | 12 | 49.6 | ⚠️ MODERATE |
| `3017620422003` | Nutella | Ferrero | 9 | 61.7 | ⚠️ MODERATE |
| `5000159461122` | Snickers | Snickers | 17 | 65.9 | ⚠️ MODERATE |
| `5000159484695` | Twix Ice Cream | Twix | 33 | 52.3 | ⚠️ MODERATE |
| `7622210449283` | Prince Goût Chocolat | LU / Mondelez | 21 | 66.0 | ⚠️ MODERATE |
| `3017760000109` | Le Véritable Petit Beurre | LU | 16 | 50.0 | ⚠️ MODERATE |
| `7613034626844` | Chocapic Cereals | Nestlé | 19 | 59.2 | ⚠️ MODERATE |
| `4000417025005` | Marzipan Dark Chocolate | Ritter SPORT | 15 | 58.3 | ⚠️ MODERATE |
| `3046920028363` | Fondente Deciso (Dark Choc 70%) | Lindt Excellence | 5 | 80.0 | ✅ SAFE |
| `8001505005592` | Nocciolata (Hazelnut Spread) | Rigoni Di Asiago | 11 | 64.1 | ⚠️ MODERATE |
| `8410376026962` | Digestive Oats Choc | Gullón | 17 | 60.9 | ⚠️ MODERATE |
| `5060292302201` | Potato Snacks | Popchips | 21 | 68.8 | ⚠️ MODERATE |
| `40822938` | Fanta Orange | Fanta | 3 | 50.0 | ⚠️ MODERATE |

---

## 🧪 Test Scenarios

### Scenario 1: Basic Barcode Scan
1. Scan/enter barcode `3046920028363` (Lindt Dark Chocolate)
2. **Expected**: Score **80.0** — ✅ **SAFE** (only 5 simple ingredients)

### Scenario 2: Complex Product
1. Scan/enter barcode `5000159484695` (Twix Ice Cream)
2. **Expected**: Score **52.3** — ⚠️ **MODERATE** (33 ingredients, many additives)

### Scenario 3: Allergy Alerts
1. Go to **Profile** → Add "milk" as allergy + "palm oil" as avoided
2. Scan barcode `3017620422003` (Nutella)
3. **Expected**: Score drops to **~16.7** — 🔴 **UNSAFE**
4. **Alerts should show**:
   - 🔴 ALLERGY: "skimmed milk powder" matches allergy "milk"
   - ⚡ AVOIDED: "palm oil" is in avoided ingredients
5. Remove allergies afterwards in Profile to reset

### Scenario 4: OCR Input
1. Go to **OCR Capture**
2. Enter this text manually (or photograph a label):
   ```
   Water, Sugar, Citric Acid, Sodium Benzoate, Aspartame,
   Acesulfame Potassium, Caramel Color, Phosphoric Acid
   ```
3. **Expected**: Most ingredients classified, several moderate/high risk alerts for Sodium Benzoate, Aspartame, Phosphoric Acid

### Scenario 5: Product Comparison
1. Go to **Compare**
2. Enter barcode 1: `3046920028363` (Lindt, ~80 score)
3. Enter barcode 2: `5449000000996` (Coca-Cola, ~53 score)
4. **Expected**: Side-by-side comparison, "Product 1 is safer", difference ~27 points

### Scenario 6: OCR with Dangerous Ingredients
1. Go to **OCR Capture**
2. Enter:
   ```
   Water, Sodium Lauryl Sulfate, Methylparaben,
   Propylparaben, Fragrance, Triclosan, Formaldehyde
   ```
3. **Expected**: Very low score (likely 🔴 UNSAFE), multiple HIGH_RISK alerts for Triclosan (8/10), Formaldehyde (9/10)

---

## 🔢 OCR Test Texts

### Food Product (moderate risk)
```
Enriched wheat flour, water, sugar, palm oil, salt, yeast,
mono- and diglycerides of fatty acids, calcium propionate,
citric acid, soy lecithin, ascorbic acid
```

### Cosmetic Product (high risk)
```
Aqua, Sodium Laureth Sulfate, Cocamidopropyl Betaine,
Sodium Chloride, Fragrance, Methylparaben, Propylparaben,
Dimethicone, Citric Acid, Sodium Benzoate, EDTA
```

### Clean Product (low risk)
```
Water, Aloe Vera, Glycerol, Hyaluronic Acid, Niacinamide,
Jojoba Oil, Shea Butter, Tocopherol, Citric Acid
```

---

## ❌ Barcodes That Won't Work (Not in OpenFoodFacts/OpenBeautyFacts)
These return 404 — useful for testing error handling:
- `8710398527844`
- `80177241`
- `5053990156009`
- `0000000000000`
- `1234567890123`
