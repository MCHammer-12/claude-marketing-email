---
name: create-redo-email
description: >-
  Generate a Redo email template from a freeform description and import it into
  a merchant's Redo account. Use when asked to create, build, or design a
  marketing email for Redo (for example, "make an email for our summer sale",
  "design a 20% off email", "create a newsletter for new arrivals"). Generates
  valid EmailTemplate JSON matching Redo's builder schema, then posts it to the
  createEmailTemplate RPC. The resulting template is flow-usable — it can be
  wired into an automation's send_email step. Inputs are an email description
  and a valid merchant session JWT for a user with the MANAGE_TEMPLATES
  marketing permission. Returns the URL to open the new template in the Redo
  builder.
---

# Create Redo Email

Generate a marketing email template from a description and save it into a
merchant's Redo account. Goes through the existing `createEmailTemplate` RPC.
The returned `EmailTemplate._id` is flow-usable — it can be referenced from
a `send_email` step in any automation. No code changes, no DB writes beyond
what the merchant could do themselves.

**Note on the two-templates trap.** Redo has two collections — `EmailTemplate`
(renderable, flow-usable) and `SavedEmailTemplate` (a library wrapper). This
skill uses `createEmailTemplate` so the output is always flow-usable. If a
merchant separately wants the template to appear in their "Saved templates"
library, they can save it from the builder, or we call
`createSavedEmailTemplate` as a follow-up step. See the two-templates
trap section at the end of this file for the full distinction.

## Inputs to collect

1. **Email description** — what the email is for. Freeform, e.g. "20% off
   summer sale for sustainable t-shirts, friendly tone, hero image, single
   CTA." If brief, ask the user to expand on tone, products, hero imagery,
   discount details, etc. before generating.
2. **Session JWT** — read from `~/.redo/jwt`, where the user stores it once;
   never ask them to paste it into the chat (see INSTALL.md). Must be issued
   for a user with `MarketingPermissions.MANAGE_TEMPLATES`.
3. **Template name** (optional) — defaults to a short title derived from the
   description (e.g. `Summer Sale 20% Off`). Always confirm with the user.
4. **Subject line** (optional) — defaults to a derived subject. Confirm with
   the user.
5. **Outreach intent** (optional) — one of `DISCOUNT`, `ANNOUNCEMENT`,
   `SHOWCASE`, `NEWSLETTER`, `BRAND_STORY`, `SALE`, `SOCIAL_PROOF`,
   `INFORMATIONAL`. Infer from the description if not given; use it to bias
   layout and copy.
6. **Brand colors** (optional) — primary, accent, background. Defaults:
   `#ffffff` (email bg), `#f5f5f5` (content bg), `#1E90FF` (link).
7. **Brand font** (optional) — defaults to `Arial`. Must be an email-safe font
   (Arial, Helvetica, Georgia, Times New Roman, Verdana, Tahoma, Trebuchet MS,
   Courier New).

## Pre-flight checks (BEFORE any API call)

**Load the token from the user's local store — never ask the user to paste the
JWT into the chat, and never echo it** (no `echo "$TOKEN"`, no `curl -v`). It
must stay out of the conversation. If `~/.redo/jwt` is missing, stop and tell
the user to run `connect.sh` from the claude-marketing-email repo (details in
INSTALL.md); do not accept a pasted token.

```bash
TOKEN="$(cat ~/.redo/jwt)"   # Keychain alt: security find-generic-password -s redo-jwt -w
```

Shell state doesn't persist between commands, so re-set `TOKEN` at the start of
every block that calls the API. Decode and check the payload — prints only the
claims, never the token:

```bash
cut -d. -f2 ~/.redo/jwt | base64 -d 2>/dev/null | jq '{aud, exp, sub}'
```

Verify:

- `aud` is `mcht/<teamId>` — capture the `teamId` for the builder URL later.
- `exp` (unix seconds) is in the future.

If either fails, stop and tell the user.

## Endpoint summary

Prod merchant server is `https://app-server.getredo.com` (NOT `app.getredo.com`
or `api.getredo.com`). All requests:

- `Authorization: <jwt>` (raw token, NO `Bearer ` prefix)
- `Content-Type: application/json`
- Body wrapped: `{"input": {...}}`

### Write

```
POST https://app-server.getredo.com/marketing-rpc/createEmailTemplate
{
  "input": {
    "team": "<teamId from JWT aud>",
    "name": "...",
    "subject": "...",
    "templateType": "default",
    "category": "Marketing",
    "schemaType": "marketing_email",
    "emailBackgroundColor": "#ffffff",
    "contentBackgroundColor": "#f5f5f5",
    "linkColor": "#1E90FF",
    "sections": [ ... ]
  }
}
```

**Body shape — the input IS the template.** Unlike `createSavedEmailTemplate`,
there's no outer wrapper with `name`/`source`/`isGenerating`. Do NOT include
`_id` (the input schema is `emailTemplateSchema.omit({_id: true})`; the
server generates one and returns it).

Response: `{"output": <EmailTemplate>}` where `output._id` is the
EmailTemplate ID. HTTP 4xx on error. **Capture `output._id`** — this is the
ID merchants use when wiring the template into a `send_email` step.

### Builder URL (to return to the user)

```
https://app.getredo.com/stores/<teamId>/marketing/email-sms/templates/email/<templateId>
```

No `?type=savedTemplate` query param — that was specific to the
SavedEmailTemplate route. For a bare EmailTemplate the route resolves
without it.

## Workflow

1. **Collect and confirm inputs.** Show the user the resolved name, subject,
   intent, and color/font choices. Wait for confirmation before generating.
2. **Pick the brand archetype.** Read
   [references/best-practices/_index.md](references/best-practices/_index.md)
   to choose the file(s) that match the merchant's segment, then load the
   matching archetype file(s). That file gives you voice/tone, layout norms,
   reference brands, and segment-specific anti-patterns. **Cite the
   archetype back to the user** ("Treating this as an apparel-fashion
   brand — confirm or correct.") before generating.
3. **Generate sections.** Build the email's `sections` array following the
   rules in [Generating sections](#generating-sections) below, the segment
   guidance from step 2, and the copy rules in
   [references/copy-craft.md](references/copy-craft.md). Also apply the
   `stop-slop` skill's checks to all prose.
4. **Wrap into a full EmailTemplate.** See [Template shape](#template-shape).
5. **Show the user the generated JSON** (or a summary — section types, copy
   highlights, color choices, brand-archetype tells you avoided). Wait for
   "go" confirmation before writing.
6. **POST** to `createEmailTemplate`. Capture `output._id` from the
   response — this is the flow-usable `EmailTemplate._id`.
7. **Return the builder URL** to the user. Surface the section count, the
   `EmailTemplate._id` (for any future flow wiring), and any placeholder
   image URLs they need to replace in the builder.

## Generating sections

The `sections` array follows Redo's `EmailBlockType` schema. **Only these 10
block types are allowed** in AI-generated emails for v1:

| type       | use                                           |
| ---------- | --------------------------------------------- |
| `header`   | Logo or text at the top                       |
| `text`     | Paragraphs, headlines, body copy              |
| `button`   | Single CTAs                                   |
| `image`    | Standalone image                              |
| `spacer`   | Vertical whitespace                           |
| `line`     | Horizontal divider                            |
| `menu`     | Horizontal nav link row                       |
| `socials`  | Social media icon row                         |
| `discount` | Discount/promo code display block             |
| `column`   | Multi-column layout (contains other sections) |

(`shoppable-products` is supported by Redo's schema and `supportedSectionTypes`
but is excluded from v1 — too many required fields with strict typing,
deserves its own focused pass.)

**Hard rules:**

- Every section needs `type` and `sectionPadding: {top, right, bottom, left}`
  in pixels. `top` MUST equal `bottom`, `left` MUST equal `right`.
- Every section needs `sectionColor` (hex string).
- **Universal enum casing — wire format is the LOWERCASE string literal value,
  NOT the TypeScript enum identifier.** Redo's source declares enums like
  `LEFT = "left"`. The server expects `"left"`. This applies to *every*
  enum-valued field: `alignment`, `layout`, `headerType`, `iconColor`,
  `linkType`, `productSelectionType`, `size`, `fontWeight`, `schemaType`,
  etc. The enum identifier names (e.g. `LEFT`, `CENTER`) — they're misleading; use the values.
- `column` blocks have a `columns: [...]` array of nested sections. **You
  cannot nest a `column` inside a `column`.**
- `image` blocks should have `sectionPadding` of 0 on all sides almost always.
- All colors are hex strings starting with `#`.
- `blockId` is added by this skill after generation — do NOT generate
  `blockId` values inline; the skill assigns a fresh 24-char hex ObjectId to
  each section (including nested `columns[*]`).
- `text` block content uses HTML-rich strings, NOT markdown. Each line wraps
  in `<p>` tags. Sizing uses inline `<span style="font-size: Xpx;">`. Do not
  use `<h1>`/`<h2>`/`<h3>` — use `<p>` + `<span>`. Links are `<a>` tags inside
  the `<p>`.

See [references/block-schemas.md](references/block-schemas.md) for per-block
required fields, the full enum reference, and verified examples.

### Generation prompt

Use this system prompt when generating the sections. It combines Redo's
email-builder schema requirements with anti-AI-slop guidance adapted from
Anthropic's frontend-aesthetics cookbook and design-led email tooling
(Klaviyo, Stripo, Litmus). Do not water it down — the specificity is what
keeps the output from feeling templated.

```
You are an expert email designer producing JSON for Redo's email builder. You
tend to converge toward generic, "on-distribution" outputs — purple-blue
gradients, symmetric grids, "Discover our amazing products," stock-photo
placeholders, single-weight Inter type. That is the AI-slop aesthetic. Avoid
it. Make a distinctive email that surprises and delights.

STEP 1 — Visual direction (think before you JSON)
Before emitting any JSON, internally decide:
  - mood — one short phrase ("warm Sunday morning", "midnight launch", ...)
  - palette — exactly 3 colors (background, dominant, accent); accent is used
    ONLY for the primary CTA
  - type pairing — one bold display family (allowed: Georgia, Trebuchet MS,
    Tahoma) for headlines + one body family (Arial, Helvetica, Verdana). Use
    weight extremes for contrast (e.g. 700 vs 400), not adjacent weights.
  - hero treatment — one hero image OR one big typographic statement, never
    both
  - CTA voice — verb-first, 2-4 words, value-clear

STEP 2 — Self-check (yes to all five before emitting)
  1. Would a recipient know what this email is about in 3 seconds?
  2. Is there exactly one primary CTA above the fold (i.e. in the first
     viewport)?
  3. Does my palette use a dominant color + ONE accent, not evenly-distributed?
  4. Did I avoid every word and pattern in the FORBIDDEN list below?
  5. Does the copy sound like a real merchant wrote it, not a template?

STEP 3 — Emit the JSON
Output a JSON object with a top-level "sections" key — an array of section
objects. Schema rules:
  - Allowed types ONLY: header, text, button, image, spacer, line, menu,
    socials, discount, column.
  - Every section: `type`, `sectionPadding` ({top, right, bottom, left} —
    integers, top=bottom and left=right), `sectionColor` (hex).
  - No `column` inside `column`.
  - `text`: HTML in <p> tags. Sizing via <span style="font-size: Xpx;">. No
    <h1>/<h2>/<h3>. Links: <a> inside <p>.
  - Do NOT include `blockId` — the system assigns it.
  - Fonts: Arial, Helvetica, Georgia, Times New Roman, Verdana, Tahoma,
    Trebuchet MS, Courier New only.
  - ALL enum-valued fields use lowercase wire values:
      alignment / layout: "left" | "center" | "right"
      headerType: "image" | "logo" | "text"
      iconColor (socials): "black" | "white" | "gray"
      linkType (button): "web-page" | "dynamic-variable"
      fontWeight (discount): "normal" | "bold"
      column.alignment (vertical): "top" | "center" | "bottom"
      Size enum (image/line h+v padding): "small" | "medium" | "large" | "custom"
    See references/block-schemas.md for the full enum reference.

HARD NUMERIC CONSTRAINTS
  - Max 3 colors total in the design.
  - Headline: ≤ 8 words.
  - Body line: 14–16px, line-height feels relaxed (use generous sectionPadding
    rather than line-height tricks the builder doesn't support).
  - Headline size: 24–32px; subhead 18–20px; CTA text ≥ 16px.
  - Min 4.5:1 contrast between text and background, and between CTA fill and
    its surrounding sectionColor.
  - Horizontal sectionPadding: 24–48px on content sections; image sections
    use 0/0/0/0.
  - One hero image max. One primary CTA above the fold.
  - Mobile-first: every `column` block has `stackOnMobile: true`.

FORBIDDEN — never use any of these
  Copy (see references/copy-craft.md for the full list and the per-segment
  forbidden phrases in best-practices/<archetype>.md):
    - Em dashes anywhere. Use commas, colons, or split into two sentences.
    - "Click here", "Learn more", "Submit", "Get started" (as bare CTAs with
      no value statement)
    - "Discover", "Unlock", "Elevate", "Pivotal", "Meticulous", "Seamless"
    - "Our amazing products", "Welcome to the future of...", "Powered by AI"
    - Exclamation points in the headline
    - Emoji used as bullet markers
    - Semicolons, smart quotes (use straight " and ' instead)
  Visuals:
    - Purple-to-blue gradients on white
    - Pastel-only palettes with no clear accent
    - Three equal-width feature cards in a row
    - 50/50 columns where both halves carry equal weight
    - Generic stock-photo placeholders ("hands holding phone", "diverse team
      around laptop")
    - Uniform border-radius and padding on every element
    - Filler sections added just to take up space

BRAND CONSISTENCY
  - Use the provided brand colors EXACTLY. Do not invent new colors.
  - Match the provided brand voice (or default to: plain English, active
    voice, short sentences, warm-and-human, subtle over noisy).
  - If the description names real products, use those product names. Never
    write "Product A / Product B."

LAYOUT — the proven arc (deviate only with reason)
  Hero (logo + headline + primary CTA)
  → Body block(s) (1-3 supporting sections; mix of text, image, column)
  → Secondary CTA (optional, visually subordinate)
  → Trust/social proof (review snippet, press logo, ...) — only if real
  → Footer (socials + unsubscribe + address — most of footer is added
    server-side, you usually only need a `socials` block at the bottom)

INPUTS
  Description: <user's freeform description>
  Intent: <DISCOUNT|ANNOUNCEMENT|SHOWCASE|NEWSLETTER|BRAND_STORY|SALE|SOCIAL_PROOF|INFORMATIONAL>
  Brand colors: <primary, accent, background>
  Brand font: <font family>
  Real product names / hero imagery references / discount details: <from user>
```

**Why the prompt is this opinionated.** The Anthropic frontend-aesthetics
cookbook is explicit that LLMs default to "on-distribution" choices
(generic fonts, predictable layouts, timid palettes) and that the only
effective counter is naming the anti-patterns and forcing a
reason-before-emit step. Klaviyo and Stripo's AI email tools both inject
merchant palette/voice as hard constraints rather than trusting the model's
defaults. The forbidden-copy list comes from documented AI-tell patterns in
marketing email (Tabular, Litmus, Really Good Emails trend reports).

### Image handling (v1 limitation)

This skill does NOT generate images. When the user requests an AI-generated
image (e.g. "create an image of a soccer ball going into a goal"):

1. Use a placeholder URL: `https://placehold.co/600x400?text=Replace+me`
2. Tell the user in the final summary which image fields are placeholders and
   how to replace them in the builder.

For user-supplied image URLs, use them directly in the `imageUrl` field.

## Template shape

The `createEmailTemplate` input IS the template (no outer wrapper). Required
top-level fields:

```json
{
  "team": "<teamId from JWT aud>",
  "name": "<template name>",
  "subject": "<subject line>",
  "templateType": "default",
  "category": "Marketing",
  "schemaType": "marketing_email",
  "emailBackgroundColor": "#ffffff",
  "contentBackgroundColor": "#f5f5f5",
  "linkColor": "#1E90FF",
  "sections": [ ... generated sections with blockIds ... ]
}
```

Notes:
- **Do NOT include `_id`.** The input schema is
  `emailTemplateSchema.omit({_id: true})`. Server generates it and returns
  it as `output._id`.
- `templateType: "default"` (not `"transactional"` — that's reserved for
  order confirmations, shipping, etc.).
- `category: "Marketing"` and `schemaType: "marketing_email"` are the
  marketing-campaign defaults. **`schemaType` is lowercase** — it's the wire
  value, not the TS enum identifier.
- **Include `team`.** The handler injects it from the JWT, but include it
  in the body anyway — matches what the frontend does and survives any
  server-side validation that runs before injection. Parse from JWT `aud`
  (the value after the `mcht/` prefix).
- Do NOT include `createdAt`/`updatedAt` — server-generated.
- `address` is optional; omit unless the user provides one.

**Each section's `blockId`** is still required — generate a fresh 24-char
hex ObjectId per section (and per nested `columns[*]`). This is unchanged
from the prior body shape; only the top-level wrapping changed.

### Generating ObjectIds

Use 24 lowercase hex characters. Example bash:

```bash
openssl rand -hex 12
```

Or in Node:

```js
import { randomBytes } from "node:crypto";
randomBytes(12).toString("hex");
```

## Constructing the request

Example end-to-end shell, assuming you've already generated `sections.json`:

```bash
TOKEN='<paste session JWT>'
TEAM_ID='<from JWT aud>'
mkdir -p /tmp/redo-email
cd /tmp/redo-email

# Build the request body — no _id, input IS the template
jq --arg team "$TEAM_ID" \
   --arg name "Summer Sale 20% Off" \
   --arg subject "Sun's out - 20% off everything" \
   '{
     input: {
       team: $team,
       name: $name,
       subject: $subject,
       templateType: "default",
       category: "Marketing",
       schemaType: "marketing_email",
       emailBackgroundColor: "#ffffff",
       contentBackgroundColor: "#f5f5f5",
       linkColor: "#1E90FF",
       sections: .
     }
   }' sections.json > body.json

# POST
curl -sS -X POST 'https://app-server.getredo.com/marketing-rpc/createEmailTemplate' \
  -H "Authorization: $TOKEN" \
  -H 'Content-Type: application/json' \
  --data-binary @body.json \
  -o response.json -w "HTTP %{http_code}\n"

# Extract EmailTemplate _id and build the builder URL
TEMPLATE_ID=$(jq -r '.output._id' response.json)
echo "https://app.getredo.com/stores/$TEAM_ID/marketing/email-sms/templates/email/$TEMPLATE_ID"
```

## Errors

| Symptom                                | Cause                                                              | Fix                                                                       |
| -------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| HTTP 401/403                           | Token expired, wrong team, or missing `MANAGE_TEMPLATES` permission | Re-issue token from a user with the right permission                      |
| HTTP 400 + Zod error mentioning an enum | Used the TS enum identifier (e.g. `"CENTER"`) instead of the wire value (`"center"`) | Lowercase the value. See enum reference in [references/block-schemas.md](references/block-schemas.md) |
| HTTP 400 + Zod error mentioning unknown field `template` / `source` | Wrapped the body in `{ template: {...}, name, source, isGenerating }` (that's the `createSavedEmailTemplate` shape) | The `createEmailTemplate` input IS the template — no outer wrapper |
| HTTP 400 + Zod error mentioning `_id` | Included `_id` in the input | Drop it. Server generates and returns it as `output._id`. |
| HTTP 400 + Zod error                   | Template JSON didn't match `emailTemplateSchema`                   | Diff the offending field against [references/block-schemas.md](references/block-schemas.md) and regenerate |
| HTTP 500 "Failed to create email template" | Suspect: Shopify-product-sync or similar side-effect throw when the team has a malformed `storeUrl`. Seen on test teams without a real Shopify connection: the first call succeeds, subsequent ones fail opaquely with no Zod error. | Retest on a properly-provisioned Shopify-connected store. |
| HTTP 500 (opaque) on first POST | Missing `team` field (Mongoose-required, server-injected but include defensively) | Include `team` in the body — parse from JWT `aud` |
| HTTP 404 on `POST /marketing-rpc/...`  | Wrong host                                                         | Use `app-server.getredo.com`, NOT `app.getredo.com` or `api.getredo.com`  |
| Template ID doesn't work in a `send_email` step (builder shows empty card) | The merchant grabbed a `SavedEmailTemplate._id` from somewhere instead of an `EmailTemplate._id` | This skill returns the correct `EmailTemplate._id`. If a merchant is wiring an arbitrary template into a flow, confirm they're using the EmailTemplate ID, not the SavedEmailTemplate wrapper ID. |
| Generated email looks templated/AI     | Generic copy, symmetric layout, stock-photo-feel                   | Push back on the description, request specifics (brand voice, real products, named hero shot) |

## Reference

- Block schemas (per-type required fields + enum reference): [references/block-schemas.md](references/block-schemas.md)
- Copy craft rules (em dashes, subject lines, CTAs): [references/copy-craft.md](references/copy-craft.md)
- Brand archetype selector + per-archetype best practices: [references/best-practices/_index.md](references/best-practices/_index.md)
- Example template (top-level shape + per-section field presence): [references/example-template.json](references/example-template.json)
- Companion skill for prose review: `stop-slop` (catches em dashes, formulaic structures, passive voice, vague declaratives)
- Permission required: `MarketingPermissions.MANAGE_TEMPLATES`

### The two-templates trap (so you don't fall in)

Redo has two collections for email content. They look similar from the
outside; they are not interchangeable.

| RPC | Collection | Wired into flows? |
| --- | --- | --- |
| `createEmailTemplate` | `EmailTemplate` | **Yes** — `send_email.templateId` resolves here |
| `createSavedEmailTemplate` | `SavedEmailTemplate` (wraps a denormalized copy of an EmailTemplate) | No — empty cards in builder, "Template not found" at send time |

This skill uses `createEmailTemplate` so the output is always flow-usable.
If a merchant explicitly wants the template in their "Saved templates"
library (a UI nicety, separate from the flow surface), call
`createSavedEmailTemplate` as a follow-up with the same template body
wrapped in `{ template, name, source: "uploaded", isGenerating: false }`.
