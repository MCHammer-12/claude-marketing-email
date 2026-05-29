# Copy Craft for Email

Email-specific copy guidance. **Combine with the `stop-slop` skill** for
general anti-AI-tell rules — that skill catches em dashes, formulaic
structures, filler phrases, passive voice, vague declaratives, and more. Run
its checks before delivering any copy.

This file adds email-specific patterns the general rules don't cover.

## The hard rules

1. **No em dashes.** Period. (`stop-slop` rule.) Use a comma, a colon, or
   split into two sentences. Em dashes are the #1 visual AI-tell in
   marketing copy.
2. **Straight quotes, not smart quotes.** `"` and `'`, not `"` `"` or `'` `'`.
   Email rendering across clients mangles smart quotes inconsistently. Type
   them straight.
3. **Sentence case for everything**, including buttons and headlines, unless
   the brand's house style is explicitly Title Case. "Shop the sale" beats
   "Shop The Sale" 99% of the time.
4. **No exclamation points in the headline.** One per email max, in the body
   if at all. Brands that earn excitement don't need the punctuation.
5. **No emoji as bullets or filler.** Allowed sparingly in the subject line
   if it actually signals something (🚨 for a real urgent restock notice, not
   for a Tuesday newsletter).
6. **Numbers as digits.** "20% off" not "twenty percent off." "3 left" not
   "three left." Faster to scan.
7. **No semicolons.** They appear in two places: legal copy and AI-generated
   text. Marketing emails are neither.

## Subject lines

- 30–50 characters. Gmail clips around 60 desktop / 35 mobile.
- One of three modes per email:
  - **Curiosity** — "This is the one." (works for established brands)
  - **Benefit** — "20% off tees, this week only."
  - **Specificity** — "Your usual roast is back in stock."
  Don't try to do all three at once.
- Avoid: "Don't miss out," "Limited time," "Last chance" (unless literally
  true), "Hey [name]" (unless personalized further than just the name).
- Test it on mobile preview before shipping.

## Preheader text

- 35–90 characters. The line that appears after the subject in the inbox
  list.
- It **extends** the subject, never repeats it. If the subject is "20% off
  tees," the preheader is "Through Sunday — your size is back." Not "20%
  off this week!"
- If you leave it blank, the email client will pull the first sentence of
  the body, which is usually awful. Always set it.

## Body copy

- **Above the fold** (first ~600px) must answer: what is this? Why care?
  What's the action? The recipient may never scroll.
- **One idea per section.** If a `text` block is trying to do two things,
  split it.
- **Concrete > abstract.** "Our 100% organic Pima cotton tee in eight new
  colors" beats "premium quality apparel options."
- **Show, don't sell.** Real customer quote > vague claim ("loved by
  thousands"). Real product detail > "amazing quality." Real photo > stock.
- **Length:** 50–150 words for promo emails, 200–400 for newsletters,
  20–60 for transactional. If you're at 500+, you've written a blog post.

## CTAs

- **Verb-first, value-clear, 2–4 words.** "Shop the sale." "Read the story."
  "Reserve your seat." "Claim my code."
- **One primary CTA per email.** Secondary CTAs are buttons too but visually
  subordinate (lighter color, smaller, lower in the layout).
- **First person ("Claim my code") slightly outperforms second person
  ("Claim your code")** in some segments — worth A/B testing but not a
  universal rule.
- **Avoid:** "Click here," "Learn more," "Submit," "Get started," "Find
  out more." All vague.

## Personalization

- `{{ customer.first_name }}` greetings: fine when the email is otherwise
  conversational; off-brand when the brand is luxury or minimalist.
- Never use a personalization token unless you have a fallback for missing
  data (and the fallback is graceful: "Hi friend" not "Hi {{firstName}}").
- "Hey [first name]" is overused. Vary the greeting if you use one at all.

## Mobile-first writing

- ~60% of email opens are mobile. Write for the small screen.
- Short paragraphs (1–3 lines on desktop = 2–6 lines on mobile).
- Front-load the value in every paragraph — readers scan, they don't read.
- The CTA must be tappable: at least 44×44pt touch target, comfortable
  whitespace around it.

## What "sounds like a real merchant"

A real merchant's email sounds like the brand's social media post, not like
a press release. If you'd never read it out loud, rewrite.

A real merchant uses the brand's actual vocabulary — product names, real
collection names, real city/origin references. Not "our products" or "our
collection."

A real merchant occasionally breaks the rules. Perfect-grammar copy reads
templated. A single intentional sentence fragment in the right spot makes
the whole thing feel human. (One. Not three.)

## Forbidden phrases (general)

These mark AI-generated marketing copy across every segment.

**The universal three verbs to never use as openers or CTAs:**

- "Discover" (any form: discover, discovering, discovery)
- "Unlock" (any form)
- "Embrace" (any form)

These appeared as AI-tells in every single brand archetype researched. If
your copy contains any of them, rewrite. They're the most reliable
single-word AI detectors in marketing email.

**Phrases:**

- "Discover our amazing products"
- "Unlock the power of..."
- "Embrace the new..." / "Embrace your..."
- "Elevate your routine/style/wardrobe/space"
- "Pivotal," "meticulous," "robust," "comprehensive," "seamless," "leverage"
- "Picture this:" / "Imagine this:"
- "Not just X, it's Y" (contrastive setup)
- "At [brand], we believe..."
- "We're so excited to..."
- "Without further ado"
- "Game-changing," "revolutionary," "next-level"
- "Welcome to the future of..."

Segment-specific forbidden phrases live in each
`best-practices/<archetype>.md` file.

## Self-check before emitting

1. Did I use any em dashes, semicolons, or smart quotes? (Remove them.)
2. Is the headline under 8 words and free of exclamation points?
3. Does the CTA start with a verb and avoid "click/learn/submit"?
4. Does the preheader extend the subject rather than repeat it?
5. Is the above-the-fold content self-sufficient if no one scrolls?
6. Did I use a real product name / brand specific somewhere?
7. Would I read this copy out loud without cringing?

If any answer is no, rewrite that piece.
