# Block Schemas

Per-block-type required fields for AI-generated emails.

**CRITICAL — universal enum casing.** Every Redo enum is declared as
`KEY = "value"`. The **wire format is the lowercase value**, not the
identifier. The enum identifier
names (e.g. `LEFT/CENTER/RIGHT`, `IMAGE/LOGO/TEXT`) — they're misleading; the
server rejects them. Always use the lowercase value column from the enum
reference below.

## Common fields (every block)

```
type:           "header" | "text" | "button" | "image" | "spacer" |
                "line" | "menu" | "socials" | "discount" | "column"
sectionPadding: { top, right, bottom, left }   // integers, top=bottom, left=right
sectionColor:   "#RRGGBB"                       // hex
blockId:        <added by skill after generation, do NOT generate inline>
```

## Universal enum reference

| Enum                          | Wire values                                            |
| ----------------------------- | ------------------------------------------------------ |
| `Alignment` (horizontal)      | `"left"` \| `"center"` \| `"right"`                    |
| `VerticalAlignment` (column)  | `"top"` \| `"center"` \| `"bottom"`                    |
| `EmailHeaderType`             | `"image"` \| `"logo"` \| `"text"`                      |
| `SocialIconColor`             | `"black"` \| `"white"` \| `"gray"`                     |
| `ButtonLinkType`              | `"web-page"` \| `"dynamic-variable"`                   |
| `Size` (image/line padding)   | `"small"` \| `"medium"` \| `"large"` \| `"custom"`     |
| `EmailBuilderFontWeight`      | `"normal"` \| `"bold"`                                 |
| `SchemaType` (template)       | `"marketing_email"` (lowercase)                        |
| `TemplateType` (template)     | `"default"` \| `"transactional"`                       |
| `SocialPlatform` (socials)    | `"apple"`, `"discord"`, `"facebook"`, `"github"`, `"google"`, `"instagram"`, `"linkedin"`, `"pinterest"`, `"reddit"`, `"snapchat"`, `"tiktok"`, `"twitter"`, `"youtube"` |

---

## `header`

Email headers — logo, image, or text at the top.

```
headerType:       "image" | "logo" | "text"
layout:           "left" | "center" | "right"
sectionColor:     "#RRGGBB"
imageUrl:         "<URL or empty string>"
text:             "<header text>"
textColor:        "#RRGGBB"
fontSize:         <px integer>
fontFamily:       "<email-safe font>"
logoHeight:       <px integer>
imageHeight:      <px integer>
altText:          "<optional alt>"
clickthroughUrl:  "<link URL>"
```

---

## `text`

Paragraphs, headlines, body copy.

```
textColor:    "#RRGGBB"
fontSize:     <px integer>
fontFamily:   "<email-safe font>"
sectionColor: "#RRGGBB"
linkColor:    "#RRGGBB"
text:         "<HTML string, see below>"
```

**Text formatting rules:**

- Wrap every line in `<p>` tags. No `<h1>`/`<h2>`/`<h3>`.
- Sizing: `<span style="font-size: Xpx;">`.
- Alignment: `<p style="text-align: center|left|right;">`.
- Links: `<a href="...">` inside the `<p>`.
- Bold/italic: `<strong>`/`<em>` inside the `<span>`.

Examples:

```html
<p><span style="font-size: 24px;">This is a LARGE line of text</span></p>
<p><span style="font-size: 16px;">This is a medium line of text with</span> <strong style="font-size: 16px;">bold</strong> <span style="font-size: 16px;">and</span> <em style="font-size: 16px;">italic</em> <span style="font-size: 16px;">text</span></p>
<p style="text-align: right;"><span style="font-size: 12px;">This is a right aligned small line of text</span></p>
<p style="text-align: center;"><span style="font-size: 8px;">This is a center aligned</span> <a href="https://www.google.com" rel="noopener noreferrer" target="_blank" style="font-size: 8px;">link</a></p>
```

**IMPORTANT:** Consecutive `text` blocks with the same `sectionColor` should be
merged into a single block (multiple `<p>` tags in one `text` field). Only
split when backgrounds differ or there's an obvious separator block between
them.

---

## `button`

Single CTA.

```
buttonText:    "<call to action>"
fillColor:     "#RRGGBB"
strokeColor:   "#RRGGBB"
textColor:     "#RRGGBB"
fontFamily:    "<email-safe font>"
fontSize:      <px integer>
cornerRadius:  <px integer>
strokeWeight:  <px integer>
alignment:     "left" | "center" | "right"
linkType:      "web-page" | "dynamic-variable"   // "web-page" for normal URLs
buttonLink:    "<URL, may be empty>"
padding:       { top, right, bottom, left }       // in px
```

**Notes:**

- `fontFamily` is REQUIRED.
- `linkType` is REQUIRED. Use `"web-page"` for any normal URL CTA.
- Button does NOT take `width` / `height` — sizing comes from `padding` and
  the optional `fullWidth` boolean.
- Optional fields: `as` (`"button" | "a"`), `buttonType` (`"button" | "submit" | "reset"`),
  `fullWidth` (boolean), `schemaFieldName`.

Minimum working button:

```json
{
  "type": "button",
  "sectionColor": "#FFFFFF",
  "sectionPadding": { "top": 16, "right": 32, "bottom": 24, "left": 32 },
  "buttonText": "Shop the sale",
  "fillColor": "#FF3D8A",
  "strokeColor": "#FF3D8A",
  "textColor": "#FFFFFF",
  "fontFamily": "Arial",
  "fontSize": 16,
  "cornerRadius": 4,
  "strokeWeight": 0,
  "alignment": "center",
  "linkType": "web-page",
  "buttonLink": "",
  "padding": { "top": 12, "right": 24, "bottom": 12, "left": 24 }
}
```

Copy guidance: action verbs ("Shop the sale", "Reserve your seat"). Avoid
"Click here", "Learn more" unless contextually right.

---

## `image`

Standalone image.

```
imageUrl:           "<URL>"                          // the <img src>
sectionColor:       "#RRGGBB"
padding:            { top, right, bottom, left }    // REQUIRED, in px
horizontalPadding:  "small" | "medium" | "large" | "custom"   // REQUIRED
verticalPadding:    "small" | "medium" | "large" | "custom"   // REQUIRED
showCaption:        false | true
caption:            "<text, optional>"
altText:            "<text, optional>"
clickthroughUrl:    "<URL, optional>"
aspectRatio:        <number, optional>              // 3:2 → 1.5, NOT a string
```

**Notes:**

- `padding`, `horizontalPadding`, `verticalPadding` are all REQUIRED, in
  addition to the common `sectionPadding`.
- For literal pixel control (the common case), set `horizontalPadding` and
  `verticalPadding` to `"custom"` and put the actual numbers in `padding`.
- `aspectRatio` is a number, not a string. Convert "3:2" → `1.5`, "16:9" →
  `1.78`, "4:5" → `0.8`, "1:1" → `1.0`.
- Optional: `clickthroughLinkType` (same `ButtonLinkType` enum as `button`),
  `imageSourceType` (`ImageType` enum), `croppedImageUrl`, `cropConfig`,
  `cropConfigV2`.
- `sectionPadding` should almost always be `{0, 0, 0, 0}` for images — the
  block's own `padding` controls the spacing.

Minimum working hero image:

```json
{
  "type": "image",
  "sectionColor": "#FFFFFF",
  "sectionPadding": { "top": 0, "right": 0, "bottom": 0, "left": 0 },
  "imageUrl": "https://placehold.co/600x400?text=Replace+me",
  "padding": { "top": 0, "right": 0, "bottom": 0, "left": 0 },
  "horizontalPadding": "custom",
  "verticalPadding": "custom",
  "showCaption": false,
  "aspectRatio": 1.5
}
```

---

## `spacer`

Vertical space.

```
height:       <px integer>
sectionColor: "#RRGGBB"
```

---

## `line`

Horizontal divider.

```
color:              "#RRGGBB"
sectionColor:       "#RRGGBB"
padding:            { top, right, bottom, left }
horizontalPadding:  "small" | "medium" | "large" | "custom"   // REQUIRED
verticalPadding:    "small" | "medium" | "large" | "custom"   // REQUIRED
```

Same `"custom"` + `padding` pattern as `image` when you want literal pixels.

---

## `menu`

Horizontal navigation row.

```
menuItems:      [ { id: "<unique>", label: "<HTML>" }, ... ]
linkColor:      "#RRGGBB"
sectionColor:   "#RRGGBB"
alignment:      "left" | "center" | "right"
fontFamily:     "<email-safe font>"
fontSize:       <px integer>
textColor:      "#RRGGBB"
stackOnMobile:  true | false                      // REQUIRED
```

`label` is typically a wrapped link:
`<p style="text-align: center;"><a href="..." style="font-size: 14px;">Shop</a></p>`

Optional: `itemSpacing` (number), `useCustomSpacing` (boolean).

---

## `socials`

Social media icon row.

```
socialLinks:  [ { id: "<unique>", platform: "<SocialPlatform>", url: "<URL>" }, ... ]
iconColor:    "black" | "white" | "gray"          // NOT DARK/LIGHT/BRAND
iconPadding:  <px integer>
alignment:    "left" | "center" | "right"
sectionColor: "#RRGGBB"
```

**Notes:**

- `iconColor` values are `"black" | "white" | "gray"`. `DARK/LIGHT/BRAND` do
  NOT exist in this enum.
- `socialLinks[*].platform` uses the `SocialPlatform` enum (lowercase, see
  table above).
- `socialLinks[*].source` is optional (`SocialItemSource`: `"custom" | "brandkit"`).
- Optional: `useBrandKitSocials` (boolean).

---

## `column`

Multi-column container.

```
columns:        [ <section objects>, ... ]
columnCount:    <integer, typically 2 or 3>
sectionColor:   "#RRGGBB"
gap:            <px integer>
stackOnMobile:  true | false                      // default true
alignment:      "top" | "center" | "bottom"       // VERTICAL alignment, lowercase
```

**Rules:**

- Cannot nest a `column` inside another `column`.
- `columns[*]` contains full section objects with their own `sectionPadding`,
  `sectionColor`, etc.
- `stackOnMobile: true` is the safe default (single column on mobile).
- Optional: `columnWidths` — array of percentages (each 0-100) summing to
  100, e.g. `[70, 30]` for a 70/30 split.

---

## `discount`

Discount/promo code display.

```
alignment:            "left" | "center" | "right"
fontFamily:           "<email-safe font>"
fontSize:             <px integer>
fontWeight:           "normal" | "bold"           // REQUIRED
textColor:            "#RRGGBB"
sectionColor:         "#RRGGBB"
blockBackgroundColor: "#RRGGBB"
```

The actual discount code is bound at render time via `schemaFieldName`
(server-managed) or `discountId` (set after the merchant links a discount in
the builder). The block displays whatever code the merchant has linked.

---

## `shoppable-products` (excluded from v1)

Interactive product cards. Supported by Redo's schema and listed in
`supportedSectionTypes` but excluded from v1 of the skill — too many required
fields with strict typing for the LLM to reliably produce. Add back once it
gets a focused test pass.

If you do produce one, the casing-fixed required fields are:

```
type:                       "shoppable-products"
productSelectionType:       "dynamic" | "static"            // MANUAL → "static"
manuallySelectedProducts:   [ { productId, variantId }, ... ]   // [] when dynamic
numberOfDynamicProducts:    <integer>                         // 0 when static
cardCornerRadiusPx:         <px integer>                      // REQUIRED
size:                       "sm" | "md" | "lg" | "xl"         // lowercase
alignment:                  "left" | "center" | "right"
imageAspectRatio:           <number>                          // REQUIRED, e.g. 1.0 for 1:1
provider:                   "shopify"                         // default, set explicitly
show:                       { image, title, price, description, button }
fontFamily:                 "<email-safe font>"
textColor:                  "#RRGGBB"
productButtons:             { hierarchy, override, fullWidth, text }
checkoutButton:             { hierarchy, override, fullWidth, text }
```

`override.font.fontWeight` likely uses the `fontWeights` enum from
`content-builder/element-schema.ts` — verify casing before use.

---

## Email-safe fonts

Use ONLY these (default to `Arial` when unspecified):

- Arial
- Helvetica
- Georgia
- Times New Roman
- Verdana
- Tahoma
- Trebuchet MS
- Courier New

## Mongoose vs. Zod drift

Some fields are required by Mongoose (`required: true` in the Mongoose
schema) but optional in the Zod input schema. The Zod check passes, then
Mongoose rejects with an opaque HTTP 500 (the `ValidationError` is
swallowed). Known case:

- **`template.team` on the embedded template.** Mongoose-required; not
  injected by the `createSavedEmailTemplate` handler. Always include it
  (parse from JWT `aud`).

If you get an opaque HTTP 500 after a Zod-valid POST, suspect Mongoose drift
first: a `required: true` field on the underlying schema that the
request omitted (most commonly `team`).
