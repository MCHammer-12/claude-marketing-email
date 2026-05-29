# Best Practices — Archetype Selector

## How to use
1. Read the merchant's description (what they sell, brand voice cues, price points, hero categories).
2. Match to the best archetype below. When two clearly apply, load both files and reconcile per the "When multiple apply" rules.
3. If none clearly fit, use the default heuristic at the bottom.
4. Only load files you'll actually use — don't preload the whole directory.

## Archetypes

- **apparel-fashion.md** — clothing, basics, denim, streetwear, lifestyle athleisure (e.g. Everlane, Madewell, Buck Mason, Alo Yoga). Lifestyle-driven, not performance-driven.
- **beauty-skincare.md** — cosmetics, skincare, fragrance, haircare, men's grooming (e.g. Glossier, Drunk Elephant, Fenty, Harry's).
- **jewelry-accessories.md** — fine and demi-fine jewelry, watches, bags, sunglasses, leather goods (e.g. Mejuri, Catbird, AUrate, Cuyana, Warby Parker).
- **luxury-premium.md** — any segment positioned premium: >$200 hero items, white-glove tone, restrained promo cadence (e.g. Aesop, Khaite, Buck Mason's premium line). Load alongside the category file.
- **food-beverage.md** — food, drinks, snacks, coffee, CPG ingestibles excluding supplements (e.g. Magic Spoon, Olipop, Trade Coffee, Graza).
- **supplements-wellness.md** — vitamins, supplements, fitness recovery, mental wellness, telehealth (e.g. Athletic Greens, Ritual, Hims/Hers, Seed).
- **pet-supplies.md** — pet food, treats, toys, accessories, vet/Rx (e.g. Chewy, The Farmer's Dog, BARK, Wild One).
- **subscription-box.md** — monthly boxes, replenishment programs, curated subscriptions (e.g. Birchbox, FabFitFun, Bespoke Post, Dollar Shave Club).
- **home-furniture.md** — home goods, decor, furniture, kitchenware, bedding, tabletop (e.g. Parachute, Brooklinen, Burrow, Caraway, Made In).
- **outdoor-sporting.md** — outdoor gear, sporting goods, performance running/cycling/hiking, technical apparel (e.g. Patagonia, REI, Tracksmith, Bandit, Cotopaxi, On Running).

## When multiple apply
- A premium-positioned beauty brand (e.g. Augustinus Bader) → load both `beauty-skincare.md` AND `luxury-premium.md`. Beauty wins on layout; luxury wins on voice.
- A subscription apparel box (e.g. Stitch Fix-style) → load both `subscription-box.md` AND `apparel-fashion.md`. Subscription wins on cadence and lifecycle structure; apparel wins on imagery and copy.
- A performance athleisure brand (e.g. Tracksmith, Bandit) → load `outdoor-sporting.md` only — performance voice differs meaningfully from lifestyle athleisure.
- A premium kitchenware or furniture brand → `home-furniture.md` already covers premium positioning in this category; don't also load `luxury-premium.md` unless price point is genuinely luxury-tier (>$1,000 hero items).
- A pet supplement or pet food brand → `pet-supplies.md` wins. Pet voice dominates regardless of subcategory.
- A food brand with a subscription model (e.g. Trade Coffee) → load both `food-beverage.md` AND `subscription-box.md`. Food wins on voice; subscription wins on lifecycle email types.

## Default heuristic
If none of the above clearly fit, load `apparel-fashion.md` as the default. Its conversational voice, lifestyle imagery defaults, and balanced promo cadence generalize well across most DTC categories. Note this fallback in any output so the human reviewer can correct if needed.
