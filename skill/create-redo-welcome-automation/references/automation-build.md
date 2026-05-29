# Automation Build — RPC Playbook

RPC playbook for building a welcome automation end-to-end (rewritten
after live testing surfaced two big corrections — see "What
this supersedes" at the bottom).

## Endpoints

| RPC | Endpoint | Namespace note |
| --- | --- | --- |
| `createDiscount` | `https://app-server.getredo.com/marketing-rpc/createDiscount` | `/marketing-rpc/` |
| `createEmailTemplate` | `https://app-server.getredo.com/marketing-rpc/createEmailTemplate` | `/marketing-rpc/` |
| `createAdvancedFlow` | `https://app-server.getredo.com/rpc/createAdvancedFlow` | **`/rpc/`** — different namespace |

Headers: `Authorization: <jwt>` (raw, no `Bearer`), `Content-Type:
application/json`. Body: `{ "input": {...} }`. Response: `{ "output":
{...} }`. Enum values are lowercase string literals **except** `WaitTimeUnit`
which is PascalCase.

If you ever hit an RPC whose Zod input is `z.void()`, the wire format is
`{ "input": { "$$undefined": true } }` (not `{}` or `null`).

## 1. `createDiscount` (optional — skip if no real Shopify connection)

Detection: the team's `storeUrl` should match `*.myshopify.com`. If not
(e.g. a custom domain like `your-store.com`), this call returns HTTP 500 with `Invalid
Shopify domain for team <teamId>: "<storeUrl>" does not match expected
format`. Skip the step and warn the user.

```json
{
  "input": {
    "discountConfiguration": {
      "name": "Welcome 10% Off",
      "provider": "shopifyDiscount",
      "codeGenerationStrategy": { "strategy": "static", "code": "WELCOME10" },
      "expiration": { "expirationType": "expiration", "days": 14 },
      "discountSettings": {
        "settingsType": "SHOPIFY_BASIC",
        "discountValueType": "percentage",
        "discountValueAmount": 0.1,
        "combinesWith": {
          "orderDiscounts": false,
          "productDiscounts": true,
          "shippingDiscount": true
        },
        "appliesOncePerCustomer": true
      },
      "category": "MARKETING"
    }
  }
}
```

- `discountValueAmount: 0.1` = 10%. Stored as 0–1 decimal. **Not 10.**
- `strategy: "static"` = one shared code. `"dynamic"` = unique code per
  recipient (requires `settingsType: "DYNAMIC_RANGE"` — out of scope here).
- `expirationType: "expiration"` = expires X days after sending.

Capture `output._id` — used as `discountId` on the `discount` block in
each EmailTemplate.

## 2. `createEmailTemplate` × 3

**Use this, not `createSavedEmailTemplate`.** The two RPCs accept
similar-looking bodies but write to different collections; only
`EmailTemplate` documents are findable by `send_email.templateId`. The
prior version of this playbook got this wrong and the resulting
automation rendered empty cards.

Input is `emailTemplateSchema.omit({_id: true})` — the bare EmailTemplate
without the id. Include `team` defensively (the handler injects it from
the JWT, but matching the frontend's body is safer).

```json
{
  "input": {
    "team": "<teamId from JWT aud>",
    "name": "Welcome 1 — Hello",
    "subject": "Glad you're here",
    "templateType": "default",
    "category": "Marketing",
    "schemaType": "marketing_email",
    "emailBackgroundColor": "#FFFFFF",
    "contentBackgroundColor": "#FFFFFF",
    "linkColor": "#0F0F0F",
    "sections": [ ...full sections with blockIds... ]
  }
}
```

Section content rules — same as `create-redo-email`: lowercase enum
values, fresh 24-char hex `blockId` per section (including nested
`columns[*]`).

For a welcome series the `discount` block in each template should
reference the discount from step 1:

```json
{
  "type": "discount",
  "blockId": "<fresh ObjectId>",
  "discountId": "<output._id from step 1>",
  "sectionColor": "#FFFFFF",
  "sectionPadding": { "top": 8, "right": 32, "bottom": 32, "left": 32 },
  "alignment": "center",
  "fontFamily": "Verdana",
  "fontWeight": "bold",
  "fontSize": 22,
  "textColor": "#5a7969",
  "blockBackgroundColor": "#f2eced"
}
```

Response output is the bare `EmailTemplate`. Capture `output._id` — that's
the `templateId` for `send_email` steps in the flow.

**Known live-testing gotcha:** On test teams without a real Shopify
connection, the first `createEmailTemplate` succeeds but every subsequent
one returns HTTP 500 `{"error": "Failed to create email template"}` with
no Zod error. Tested with fresh blockIds / fresh names / minimal content /
90-sec gaps, repeatable. Hypothesis: a side-effect throw in the create
path (Shopify-product sync, marketing-cache update, plan-limit check)
fails on the malformed `storeUrl`. Worth retesting against a
Shopify-connected store before treating this as definitive.

## 3. `createAdvancedFlow` (the single-call automation create)

Endpoint: `https://app-server.getredo.com/rpc/createAdvancedFlow` — note
the `/rpc/` namespace (generic merchant), NOT `/marketing-rpc/`.

Input shape:

```ts
{
  newFlow: advancedFlowSchema_.omit({
    _id: true,
    createdAt: true,
    updatedAt: true,
    versionGroupId: true,
  }),
  setIndex: boolean
}
```

So `newFlow` is the full `AdvancedFlow` shape minus those four
server-generated fields. Required: `team`, `name`, `enabled`, `steps`,
`schemaType`, `category`. Optional: `createdByUserId`, `description`,
`index`, `publishedAt`, `metadata`, `__v`.

`setIndex: true` makes the server assign an ordering index.

### Full request body

```json
{
  "input": {
    "newFlow": {
      "team": "<teamId from JWT aud>",
      "name": "Welcome — 3-Part Series",
      "enabled": true,
      "schemaType": "email_marketing_signup",
      "category": "Marketing",
      "createdByUserId": "<userId from JWT sub>",
      "steps": [
        {
          "id": "trigger",
          "type": "trigger",
          "schemaType": "email_marketing_signup",
          "category": "Marketing",
          "key": "email_signup",
          "nextId": "send_email_1"
        },
        {
          "id": "send_email_1",
          "type": "send_email",
          "templateId": "<EmailTemplate _id for email 1>",
          "emailAddressFieldName": "customerEmail",
          "recipientNameFieldName": "customerFullName",
          "nextId": "wait_to_email_2"
        },
        {
          "id": "wait_to_email_2",
          "type": "wait",
          "numDays": 2,
          "timeUnit": "Days",
          "nextId": "send_email_2"
        },
        {
          "id": "send_email_2",
          "type": "send_email",
          "templateId": "<EmailTemplate _id for email 2>",
          "emailAddressFieldName": "customerEmail",
          "recipientNameFieldName": "customerFullName",
          "nextId": "wait_to_email_3"
        },
        {
          "id": "wait_to_email_3",
          "type": "wait",
          "numDays": 3,
          "timeUnit": "Days",
          "nextId": "send_email_3"
        },
        {
          "id": "send_email_3",
          "type": "send_email",
          "templateId": "<EmailTemplate _id for email 3>",
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

Response: `{ "output": { "id": "<new automationId>" } }`.

The flow ships with whatever `enabled` value you set. No separate
`setAutomationEnabled` call needed.

### Critical field-by-field

| Field | Value | Why |
| ----- | ----- | --- |
| `newFlow.schemaType` | `"email_marketing_signup"` | Top-level flow schema. **Different enum than the trigger's `key`.** |
| `newFlow.category` | `"Marketing"` | Required by `advancedFlowSchema_`. |
| `newFlow.enabled` | `true` (typically) | Single call ships it enabled — no separate enable RPC. |
| `newFlow.createdByUserId` | JWT `sub` | Optional but recommended. |
| `trigger.schemaType` | `"email_marketing_signup"` | Same value as top-level. Set in both places. |
| `trigger.category` | `"Marketing"` | Required on the trigger step. |
| `trigger.key` | `"email_signup"` or `"email_signup_shopify"` | The MarketingTriggerKey. Lowercase wire value. `email_signup` for Redo forms; `email_signup_shopify` for Shopify customer marketing consent. |
| `send_email.templateId` | `EmailTemplate._id` from step 2 | **NOT a SavedEmailTemplate id.** This was the bug from v1. |
| `send_email.emailAddressFieldName` | `"customerEmail"` | From `baseMarketingSchema`. Worker does string-match lookup. |
| `send_email.recipientNameFieldName` | `"customerFullName"` | Same — exact string. |
| `wait.timeUnit` | `"Days"` | PascalCase, the one exception in the whole API. |
| Terminal step | `{ id: "end", type: "do_nothing" }` | No `nextId`. |

### Validation gotchas

- `advancedFlowSchema_` enforces `steps.filter(s => s.type === "trigger").length === 1`. Zero or two triggers → Zod refine error.
- `versionGroupId`, `_id`, `createdAt`, `updatedAt` must all be **omitted** — schema strips them via `.omit`. Server generates.

## Builder URL

```
https://app.getredo.com/stores/<teamId>/marketing/automations/<automationId>
```

## End-to-end bash cheat sheet

```bash
TOKEN='<jwt>'
TEAM_ID='<from JWT aud after mcht/>'
USER_ID='<from JWT sub>'
BASE='https://app-server.getredo.com'

# 1. Discount (optional — skip on teams without a real Shopify)
DISCOUNT_ID=$(curl -sS -X POST "$BASE/marketing-rpc/createDiscount" \
  -H "Authorization: $TOKEN" -H 'Content-Type: application/json' \
  -d @discount.json | jq -r '.output._id // empty')

# 2. Templates (× 3) — createEmailTemplate, NOT createSavedEmailTemplate
T1=$(curl -sS -X POST "$BASE/marketing-rpc/createEmailTemplate" \
  -H "Authorization: $TOKEN" -H 'Content-Type: application/json' \
  -d @template-1.json | jq -r '.output._id')
T2=$(curl -sS -X POST "$BASE/marketing-rpc/createEmailTemplate" \
  -H "Authorization: $TOKEN" -H 'Content-Type: application/json' \
  -d @template-2.json | jq -r '.output._id')
T3=$(curl -sS -X POST "$BASE/marketing-rpc/createEmailTemplate" \
  -H "Authorization: $TOKEN" -H 'Content-Type: application/json' \
  -d @template-3.json | jq -r '.output._id')

# 3. Flow — /rpc/ namespace, not /marketing-rpc/
# create-flow.json interpolates $TEAM_ID, $USER_ID, $T1, $T2, $T3
AUTOMATION_ID=$(curl -sS -X POST "$BASE/rpc/createAdvancedFlow" \
  -H "Authorization: $TOKEN" -H 'Content-Type: application/json' \
  -d @create-flow.json | jq -r '.output.id')

echo "https://app.getredo.com/stores/$TEAM_ID/marketing/automations/$AUTOMATION_ID"
```

## What this supersedes (v1 corrections)

| v1 claim | Reality |
| -------- | ------- |
| "No public `createAutomation` RPC exists" | `createAdvancedFlow` is public, at `/rpc/createAdvancedFlow`. UI's "New automation" button calls it directly. |
| "6-call duplicate-and-update path" | 3 calls (or 4 with discount). No seed, no duplicate, no separate enable. |
| "`send_email.templateId` is a SavedEmailTemplate `_id`" | It's an `EmailTemplate._id`. Wrong one → builder renders empty cards, worker throws at send time. |
| "Seed via UI if `getTeamAutomations` is empty" | Irrelevant — `createAdvancedFlow` doesn't need a seed. |
| "Duplicates ship disabled — call `setAutomationEnabled`" | Only true on the duplicate path; `createAdvancedFlow` accepts `enabled: true` in the body. |
| "`getTeamAutomations` input is `{ "input": null }`" | That's HTTP 400. `z.void()` wire format is `{ "input": { "$$undefined": true } }`. |

## Type-source pointers

**In this bundle** (self-contained):
- Type contract snapshot — every enum value, step interface, trigger
  triple: [flow-types-snapshot.md](flow-types-snapshot.md)

