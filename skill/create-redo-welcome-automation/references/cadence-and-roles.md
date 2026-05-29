# Cadence and Per-Email Roles

## Default cadence: Day 0 / Day 2 / Day 5

Cumulative days from signup. Relative waits between sends: `0 → 2 → 3`.

### Why this cadence

Convergent benchmarks across the major ESP studies:

- **Klaviyo's welcome series benchmark** (2023 public data) — top-quartile
  ecom brands send 3–5 messages. Klaviyo's "Welcome Series" template
  default is Day 0 / Day 2 / Day 4. Conversion-per-recipient peaks at
  email 2.
- **Drip / Omnisend** — similar 3-message defaults at 0 / 2 / 5 days.
- **Litmus 2024 lifecycle report** — welcome emails get 4× higher
  click-through than promotional emails. Sending faster than 24 hours
  between messages compresses revenue per click (fatigue starts at ~24h
  between sends within a series).

The shape that matters:

- **Day 0 (immediate):** signup intent is fresh. Discount reveal lands.
- **Day 2:** before the discount fades from mind. Tie back to brand
  story.
- **Day 5:** before a 14-day discount expires. Urgency is real, not
  manufactured.

### When to deviate

- **Different discount expiration:** shift the urgency send to
  "(expiration days) − 9". So `expiration: 7` → urgency on Day 2 (and
  the 3rd email might just become the urgency one with no Day 5).
- **Slower-consideration verticals** (luxury furniture, B2B): stretch to
  Day 0 / Day 4 / Day 10. The trust-build matters more than urgency.
- **Wellness / supplements:** Day 0 / Day 3 / Day 7 — readers want time
  to absorb the brand story before buying.

### Avoid

- All three on Day 0 — unsubscribe spike.
- Past Day 10 — drift; recipients forget they signed up.
- More than 3 in the *initial* welcome — pivot subsequent sends to
  ongoing nurture (different automation, lower cadence).

## Per-email roles

Each email plays a distinct role. A welcome series where all three emails
say "Welcome! Here's 10% off!" feels like spam. The discount stays
constant; the framing changes.

### Email 1 — Day 0 — "Hello"

**Job:** confirm the signup, deliver brand identity, reveal the discount,
ask for one action.

**Structure (~150–200 words body):**
- Header / logo
- Hero image (lifestyle, on-brand)
- Headline: 5–7 words. Brand voice, not "Welcome to [Brand]!"
- 2–3 short paragraphs: who you are, what you make, why you exist (one
  beat each, not three full paragraphs)
- Discount block — prominent
- Primary CTA: "Shop the collection" / "Explore the line" / brand-voice
  equivalent
- Footer: socials

**Tone:** the most welcoming and personal email of the three. Sounds like
a direct message, not a corporate broadcast.

**Forbidden:**
- "Welcome to the [Brand] family!"
- "We're so excited to have you!"
- "At [Brand], we believe..."
- Multiple competing CTAs
- Listing every product collection

**On-brand example openers (vary by archetype):**
- Apparel: "Glad you found us."
- Beauty: "First things first — your code."
- Food: "Mouth, meet [Brand]."
- Luxury: "We're pleased you're here."
- Outdoor: "Welcome to the trail."

### Email 2 — Day 2 — "How it works"

**Job:** deepen brand connection. Educate. Build trust through specifics.
Re-mention the discount but quieter.

**Structure (~200–300 words):**
- Header / logo
- Image: behind-the-scenes / ingredients / materials / story (NOT another
  hero shot of the same product)
- Headline: about the brand or product mechanic, not "Welcome back!"
- Body: the story. Where you source from, how the product is made,
  what's different about your approach, who's behind it. Specific. Real
  names, real places, real numbers when possible.
- Secondary CTA: explore-the-collection / read-the-story / try-the-quiz
- Smaller discount mention near the bottom (one line, not a block) OR
  same discount block but visually subordinate
- Footer: socials

**Tone:** confident and specific. Show, don't sell.

**Forbidden:**
- "Welcome back!" (they didn't go anywhere)
- "Did you know..." (lecture opener)
- "We're proud to..." (humble-bragging)
- Repeating the discount block as the hero element

**Useful patterns:**
- Founder note (signed)
- Ingredient / material spotlight
- One real customer review (verified)
- Mini-FAQ (2-3 questions, the ones you actually get)

### Email 3 — Day 5 — "Last call"

**Job:** create real urgency around the discount expiration. Direct
action.

**Structure (~80–120 words — tightest of the three):**
- Header / logo
- Subject line specifically mentions the deadline
- Headline: deadline-driven, 5–8 words
- Tight body: the specifics. Days left, what they get, what happens if
  they wait
- Discount block — prominent again
- Primary CTA: deadline-led. "Claim your 10% — ends Friday" or "Shop
  before it's gone"
- Optional: 1-line "Need a hand picking?" + link to contact / quiz
- Footer: socials

**Tone:** clear, slightly urgent, never desperate. The deadline is the
fact, not the threat.

**Forbidden:**
- "Don't miss out!" (vague urgency)
- "Hurry!" (desperate)
- ALL-CAPS subject lines
- More than one exclamation mark in the entire email
- "Final reminder" (it's not — they'll get more emails after this)
- "We're sad to see you go" (premature; they haven't gone anywhere yet)

**Useful patterns:**
- "X days left on your welcome code" subject
- "Worth it for you?" framing (gives the reader agency)
- Real countdown phrasing ("Code expires [actual date]")

## Subject lines for the series

A pattern that works across archetypes — pair the brand-voice subject
with a deadline-aware preheader on email 3.

| Email | Subject pattern | Example (apparel) |
| ----- | --------------- | ----------------- |
| 1 | Brand-voice greeting | "Glad you're here" |
| 2 | Story or specific | "How we make the tee" |
| 3 | Deadline-led | "9 days left on your code" |

Subject-line length: 30–50 chars. Preheader: 35–90 chars. See
`create-redo-email/references/copy-craft.md` for the full subject /
preheader craft rules.

## Discount placement by email

| Email | Discount block position | Visual weight |
| ----- | ----------------------- | ------------- |
| 1 | Above the fold, after the hero text | High |
| 2 | Below the body story, before footer | Low (single line OK) |
| 3 | Above the fold, immediate after headline | Very high |
