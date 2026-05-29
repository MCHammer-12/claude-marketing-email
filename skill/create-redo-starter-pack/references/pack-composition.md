# Starter Pack Composition

Per-flow content briefs, exact step shapes, wait conversions, and cadences
for each automation in the starter pack. All flows are Marketing-category
and share the `customerEmail` / `customerFullName` recipient field names.

## Wait-step conversions (READ FIRST)

The scheduler uses `waitStepSeconds(step)`: it prefers `numSeconds`; if
absent it reads `numDays * SECONDS_IN_A_DAY`. So **any hour/minute wait
must set `numSeconds`** or it's silently interpreted as days.

| Intended wait | numDays | numSeconds | timeUnit |
| --- | --- | --- | --- |
| 1 hour | 1 | 3600 | `"Hours"` |
| 4 hours | 4 | 14400 | `"Hours"` |
| 23 hours | 23 | 82800 | `"Hours"` |
| 24 hours | 1 | 86400 | `"Days"` (or 24 / 86400 / Hours) |
| 2 days | 2 | 172800 | `"Days"` |
| 3 days | 3 | 259200 | `"Days"` |

For day waits the welcome flow proved `numSeconds` is optional (numDays
suffices). For hour waits include `numSeconds` always. Setting all three
fields consistently is the safe habit.

`timeUnit` is PascalCase (`"Days"` / `"Hours"` / `"Minutes"`) — the one
non-lowercase enum in the flow API.

## Recipient field names (all marketing triggers)

```
emailAddressFieldName:  "customerEmail"
recipientNameFieldName: "customerFullName"
```

These hold across every marketing trigger. Do not use `email` / `firstName`
for recipient fields; that convention is wrong/untested and won't resolve at
send time.

---

## 1. Welcome series

Defer to the `create-redo-welcome-automation` skill — it produces exactly
this flow (3 emails, Day 0 / 2 / 5, discount block, email_signup trigger).
Don't reimplement; invoke that skill's workflow as step one of the pack.

Trigger: `email_signup` (or `email_signup_shopify`) / `email_marketing_signup`.

---

## 2. Abandoned cart

Trigger: `cart_abandoned` / `marketing_cart_abandonment` / `Marketing`.
2 emails: a nudge at 1 hour, a stronger reminder at 24 hours.

### Content briefs

**Email 1 (1 hour, "You left something"):** light, helpful, not pushy.
Remind them what's in the cart. One clear CTA back to the cart. No
discount (don't train discount-seeking). Headline ≤ 8 words. ~60-100
words body.

**Email 2 (24 hours, "Still thinking it over?"):** add a reason to act —
social proof (a review), low-stock urgency if real, or a help offer
("questions about sizing?"). Optionally a small incentive here if the
merchant wants one (ask). CTA back to cart.

Both emails: header/logo → hero or product-ish image → headline → short
body → CTA button → socials. Use the brand archetype.

### Flow step graph

```
trigger ──► wait(1h) ──► send_email_1 ──► wait(23h) ──► send_email_2 ──► end
```

```json
{
  "input": {
    "newFlow": {
      "team": "<teamId>",
      "name": "Abandoned Cart",
      "enabled": true,
      "schemaType": "marketing_cart_abandonment",
      "category": "Marketing",
      "createdByUserId": "<userId>",
      "steps": [
        {
          "id": "trigger",
          "type": "trigger",
          "schemaType": "marketing_cart_abandonment",
          "category": "Marketing",
          "key": "cart_abandoned",
          "nextId": "wait_1"
        },
        {
          "id": "wait_1",
          "type": "wait",
          "numDays": 1,
          "numSeconds": 3600,
          "timeUnit": "Hours",
          "nextId": "send_email_1"
        },
        {
          "id": "send_email_1",
          "type": "send_email",
          "templateId": "<EmailTemplate _id, cart email 1>",
          "emailAddressFieldName": "customerEmail",
          "recipientNameFieldName": "customerFullName",
          "nextId": "wait_2"
        },
        {
          "id": "wait_2",
          "type": "wait",
          "numDays": 23,
          "numSeconds": 82800,
          "timeUnit": "Hours",
          "nextId": "send_email_2"
        },
        {
          "id": "send_email_2",
          "type": "send_email",
          "templateId": "<EmailTemplate _id, cart email 2>",
          "emailAddressFieldName": "customerEmail",
          "recipientNameFieldName": "customerFullName",
          "nextId": "end"
        },
        { "id": "end", "type": "do_nothing" }
      ]
    },
    "setIndex": true
  }
}
```

---

## 3. Browse abandonment

Trigger: `browse_abandoned` / `marketing_browse_abandonment` / `Marketing`.
1 email at 4 hours. Lowest intent (they only viewed, didn't add to cart),
so softer and later than cart.

### Content brief

**Email 1 (4 hours, "Saw you looking"):** gentle, discovery-framed. "Still
curious about [category]?" Show the viewed product or the category. Lead
with the product's appeal, not urgency. One CTA back to the product/PLP.
No discount. Headline ≤ 8 words. ~60-90 words.

### Flow step graph

```
trigger ──► wait(4h) ──► send_email_1 ──► end
```

```json
{
  "input": {
    "newFlow": {
      "team": "<teamId>",
      "name": "Browse Abandonment",
      "enabled": true,
      "schemaType": "marketing_browse_abandonment",
      "category": "Marketing",
      "createdByUserId": "<userId>",
      "steps": [
        {
          "id": "trigger",
          "type": "trigger",
          "schemaType": "marketing_browse_abandonment",
          "category": "Marketing",
          "key": "browse_abandoned",
          "nextId": "wait_1"
        },
        {
          "id": "wait_1",
          "type": "wait",
          "numDays": 4,
          "numSeconds": 14400,
          "timeUnit": "Hours",
          "nextId": "send_email_1"
        },
        {
          "id": "send_email_1",
          "type": "send_email",
          "templateId": "<EmailTemplate _id, browse email>",
          "emailAddressFieldName": "customerEmail",
          "recipientNameFieldName": "customerFullName",
          "nextId": "end"
        },
        { "id": "end", "type": "do_nothing" }
      ]
    },
    "setIndex": true
  }
}
```

---

## 4. Checkout abandonment (opt-in)

Trigger: `checkout_abandoned` / `marketing_checkout_abandonment` /
`Marketing`. 2 emails: 1 hour, 24 hours. Highest intent (they entered
checkout), so the most direct of the three abandonment flows.

### Content briefs

**Email 1 (1 hour, "Almost there"):** they were one step from buying.
Remove friction — restate what they're getting, reassure (free returns,
secure checkout), one CTA straight back to checkout. No discount. ~60-90
words.

**Email 2 (24 hours, "Your order is waiting"):** stronger urgency. Cart
may expire / stock moving. Optional incentive (ask the merchant). CTA back
to checkout.

### Flow step graph

Identical shape to Abandoned Cart, with `schemaType:
"marketing_checkout_abandonment"` and `key: "checkout_abandoned"`.

```
trigger ──► wait(1h) ──► send_email_1 ──► wait(23h) ──► send_email_2 ──► end
```

(Copy the Abandoned Cart JSON above; swap the two trigger fields and the
flow name to "Checkout Abandonment".)

### Overlap warning

If both cart AND checkout abandonment run, a shopper who entered checkout
fires both. Redo has skip-condition fields (`isCartAbandoned`,
`isCheckoutAbandoned`) to dedupe, set on the trigger step's
`skipConditions`. Wiring those is a v2 enhancement — not in this skill
yet. For v1, tell the merchant to pick one of cart/checkout unless they
explicitly want both and understand the overlap.

---

## Cadence rationale

- **Cart 1h / 24h, checkout 1h / 24h** — highest-intent recovery windows.
  First touch within the hour catches the "got distracted" abandons;
  24h catches the "sleep on it" deliberators. Beyond 48h, recovery rates
  fall off fast.
- **Browse 4h** — lower intent, so don't pounce. 4h feels like a helpful
  reminder, not surveillance. A single touch is enough; multi-email browse
  flows annoy more than they convert.
- **No discount on abandonment by default** — leading with a coupon trains
  customers to abandon on purpose. Lead with the product and friction
  removal; add an incentive only on the second touch if the merchant wants
  one.

## Template generation note

Every email here is generated with `create-redo-email`'s full pipeline:
the brand archetype (picked once for the whole pack), the anti-slop
generation prompt, copy-craft rules, and the 10 AI-supported block types.
The abandonment emails are shorter and more focused than a welcome email —
one job each (recover the cart / checkout / browse). Don't pad them.
