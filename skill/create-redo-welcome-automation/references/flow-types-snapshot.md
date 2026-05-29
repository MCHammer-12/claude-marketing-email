# Flow Types — Snapshot

Self-contained type contract for Redo automations, covering everything
you need to construct a valid `AdvancedFlow` payload for
`createAdvancedFlow`.

## Enums (wire values)

### `StepType`

```
"trigger" | "wait" | "send_email" | "send_sms" | "send_webhook" |
"do_nothing" | "condition" | "ab_test" | "manage_customer_tags" |
"manage_static_segment"
```

This skill uses only `trigger`, `wait`, `send_email`, `do_nothing`.

### `MarketingTriggerKey` (the `key` on trigger steps)

```
"email_signup"             — Redo forms / pop-ups
"email_signup_shopify"     — Shopify customer marketing consent
"sms_confirmed"            — SMS signup
"marketing_campaign"
"cart_abandoned"
"browse_abandoned"
"checkout_abandoned"
"back_in_stock"
"customer_group_entered"
"customer_group_exited"
"warranty_registration"
"low_inventory"
"date"
"price_drop"
"refund_return_submitted"
"exchange_processed_with_credit"
```

### `SchemaType` (the `schemaType` on both flow + trigger)

```
"email_marketing_signup"             — for email_signup / email_signup_shopify
"sms_marketing_signup"
"marketing_cart_abandonment"
"marketing_browse_abandonment"
"marketing_checkout_abandonment"
"marketing_segment_membership_change"
"marketing_date"
"marketing_price_drop"
"marketing_back_in_stock"
"marketing_low_inventory"
"marketing_warranty_registration"
"marketing_campaign"
"refund_return_submitted"
"exchange_processed_with_credit"
"order_tracking"
"reviews"
```

### `WaitTimeUnit` — PascalCase outlier

```
"Days" | "Hours" | "Minutes"
```

This is the **only enum in the flow API that isn't lowercase wire
literal**. Don't lowercase it. The schema rejects `"days"`.

### `FlowCategory`

```
"Marketing" | "Order tracking" | "Integration" | "Reviews"
```

## Canonical trigger triples

The `(key, schemaType, category)` triple must always be consistent. For
welcome automations:

| Signup source | key | schemaType | category |
| --- | --- | --- | --- |
| Redo forms / pop-ups | `email_signup` | `email_marketing_signup` | `Marketing` |
| Shopify customer signup | `email_signup_shopify` | `email_marketing_signup` | `Marketing` |

For other marketing triggers (not used by this skill but useful
reference):

| Trigger | key | schemaType | category |
| --- | --- | --- | --- |
| Cart abandonment | `cart_abandoned` | `marketing_cart_abandonment` | `Marketing` |
| Checkout abandonment | `checkout_abandoned` | `marketing_checkout_abandonment` | `Marketing` |
| Browse abandonment | `browse_abandoned` | `marketing_browse_abandonment` | `Marketing` |
| SMS signup | `sms_confirmed` | `sms_marketing_signup` | `Marketing` |
| Back in stock | `back_in_stock` | `marketing_back_in_stock` | `Marketing` |
| Low inventory | `low_inventory` | `marketing_low_inventory` | `Marketing` |
| Segment change | `customer_group_entered` (or `_exited`) | `marketing_segment_membership_change` | `Marketing` |
| Warranty registration | `warranty_registration` | `marketing_warranty_registration` | `Marketing` |
| Order created (post-purchase) | `order_created` | `order_tracking` | `Order tracking` |

## Step interfaces

All steps share `{ id: string, customTitle?: string }`. Then each step
type adds its own fields.

### `TriggerStep`

```ts
{
  id: string,
  type: "trigger",
  schemaType: SchemaType,
  category: FlowCategory,
  key: MarketingTriggerKey,
  nextId: string,
  skipConditions?: { conjunctionMode: "OR", conditions: unknown[] },
  shouldSkipSmartSending?: boolean
}
```

### `WaitStep`

```ts
{
  id: string,
  type: "wait",
  numDays: number,         // count of timeUnit; e.g. for 2 hours, numDays = 2 and timeUnit = "Hours"
  numSeconds?: number,      // sub-minute precision only
  timeUnit: WaitTimeUnit,   // "Days" | "Hours" | "Minutes" — PascalCase
  nextId: string
}
```

### `SendEmailStep`

```ts
{
  id: string,
  type: "send_email",
  templateId: string,                    // EmailTemplate._id (NOT SavedEmailTemplate._id)
  emailAddressFieldName: string,          // "customerEmail" for marketing-signup
  recipientNameFieldName: string,         // "customerFullName" for marketing-signup
  nextId?: string,
  disabled?: boolean
}
```

### `DoNothingStep` (terminator)

```ts
{
  id: string,
  type: "do_nothing",
  nextId?: string                         // omit on the terminal step
}
```

## `AdvancedFlow` top-level

The flow envelope for `createAdvancedFlow`. The schema strips
`_id`, `createdAt`, `updatedAt`, `versionGroupId` — omit those.

```ts
{
  team: string,                           // teamId from JWT aud
  name: string,
  description?: string,
  enabled: boolean,
  steps: Step[],                          // exactly one trigger; chain terminates at do_nothing
  schemaType: SchemaType,
  category: FlowCategory,
  createdByUserId?: string                // recommended — JWT sub
}
```

## Field-name conventions for `send_email`

`emailAddressFieldName` and `recipientNameFieldName` reference fields
declared on the trigger's schema. The Temporal worker looks them up by
exact string. Don't invent values.

For marketing-signup triggers (`email_signup`, `email_signup_shopify`):

- `emailAddressFieldName: "customerEmail"`
- `recipientNameFieldName: "customerFullName"`

Other marketing triggers (cart, browse, checkout abandonment) use the
same recipient field names: `customerEmail` / `customerFullName`.

## Step graph rules

- Exactly one step of type `"trigger"`. Zod refine throws on zero or
  multiple.
- Every non-terminal step has a `nextId` pointing at another step's `id`.
- The graph terminates at a `do_nothing` step with no `nextId`.
- Step `id`s are arbitrary unique strings within the flow. `"trigger"`,
  `"send_email_1"`, etc. work; ObjectIds also work.
- `column` blocks (in email templates, not flow steps) cannot be nested
  inside other `column` blocks. (Different topic; mentioned for
  completeness.)
