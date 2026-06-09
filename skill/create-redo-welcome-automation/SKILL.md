---
name: create-redo-welcome-automation
description: >-
  Build a 3-email welcome automation in a merchant's Redo account end-to-end:
  create the discount (optional), create 3 EmailTemplates, then create the
  automation in a single call. Use when asked to create, build, or set up a
  welcome series, welcome flow, signup automation, or post-signup email
  sequence for Redo (for example, "build a welcome series for [brand]", "set
  up a 3-email welcome flow with 10% off", "create a signup automation").
  Goes through the merchant RPCs the UI uses — no Redo eng work. Inputs are
  a brand description, a merchant session JWT (needs MANAGE_TEMPLATES,
  MANAGE_CAMPAIGNS, MANAGE_AUTOMATIONS), discount details, and signup
  source (Redo forms vs Shopify customer signup). Returns the builder URL.
---

# Create Redo Welcome Automation

Build a 3-email welcome series end-to-end using the merchant RPC surface.
No eng work, no code changes.

Composes with the `create-redo-email` skill for individual template
generation (its prompts, schemas, copy-craft, and brand-archetype best
practices apply to every email in this flow). Composes with `stop-slop`
for prose.

## The corrected 3-call sequence (was 6 in v1)

Live testing surfaced two big simplifications:

- **`createAdvancedFlow` is public** at `/rpc/createAdvancedFlow` — no
  duplicate-and-update dance needed.
- **`send_email.templateId` references an `EmailTemplate._id`** (from
  `createEmailTemplate`), NOT a `SavedEmailTemplate._id`. Using the wrong
  RPC was the original bug.

The full sequence:

| # | Call | Endpoint | Output captured |
| - | ---- | -------- | --------------- |
| 1 | `createDiscount` (optional) | `/marketing-rpc/createDiscount` | `output._id` (Redo discount ID) for the `discount` block |
| 2 | `createEmailTemplate` × 3 | `/marketing-rpc/createEmailTemplate` | `output._id` for each (the flow-usable `EmailTemplate._id`) |
| 3 | `createAdvancedFlow` | `/rpc/createAdvancedFlow` (note `/rpc/` not `/marketing-rpc/`) | `output.id` (the automation ID) |

Total: 5 HTTP calls for 3 emails. Single `createAdvancedFlow` ships the
automation enabled in one shot — no separate `setAutomationEnabled`.

## Inputs to collect

1. **Brand description** — what the merchant sells, brand voice, hero
   imagery references, real product names. Feeds the `create-redo-email`
   archetype selector + each email's content.
2. **Session JWT** — read from `~/.redo/jwt`, where the user stores it once;
   never ask them to paste it into the chat (see INSTALL.md). The merchant
   user must have all three:
   - `MarketingPermissions.MANAGE_TEMPLATES` (for `createEmailTemplate`)
   - `MarketingPermissions.MANAGE_CAMPAIGNS` (for `createDiscount`)
   - `MarketingPermissions.MANAGE_AUTOMATIONS` (for `createAdvancedFlow`)
3. **Discount details** — code (default `WELCOME10`), value (default 10%
   off), expiration days (default 14), strategy (`static` or `dynamic`).
4. **Signup source** — `email_signup` (Redo forms / pop-ups) or
   `email_signup_shopify` (Shopify customer marketing consent). If unsure,
   ask: "Are signups coming from Redo's own forms/pop-ups, or from
   Shopify's customer marketing consent?"
5. **Cadence** (optional) — defaults to Day 0 / Day 2 / Day 5. Allow
   override but recommend the default; rationale in
   [references/cadence-and-roles.md](references/cadence-and-roles.md).
6. **Automation name** (optional) — defaults to `Welcome — 3-Part Series`.

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

Verify and capture:
- `aud` matches `mcht/<teamId>` — capture `teamId` for the builder URL.
- `sub` — capture as `userId` for `newFlow.createdByUserId`.
- `exp` (unix seconds) is in the future.

**Also verify the team has a real Shopify connection** before step 1.
Heuristic: the team's stored `storeUrl` should match `*.myshopify.com`.
If it doesn't (e.g. a custom domain like `your-store.com`), `createDiscount` will return
HTTP 500 with `Invalid Shopify domain for team <teamId>...`. In that
case, skip step 1 and warn the user that the discount must be linked
manually in the builder later.

## Workflow

1. **Collect and confirm inputs.** Show the user the resolved discount,
   signup source, cadence, and automation name. Wait for confirmation.
2. **Pre-flight checks.** Decode JWT (capture `teamId` and `userId`). If
   no real Shopify connection, downgrade to "skip discount" mode and
   warn the user.
3. **Create the discount** (skip if no Shopify). POST to
   `/marketing-rpc/createDiscount`. Capture `output._id`.
4. **Plan the 3 emails.** Each email has a different role — see
   [references/cadence-and-roles.md](references/cadence-and-roles.md).
   Pick brand archetype using `create-redo-email`'s
   `references/best-practices/_index.md`. Confirm the archetype with the
   user.
5. **Generate the 3 templates.** Apply `create-redo-email`'s generation
   prompt, schemas, copy-craft, and brand-archetype guidance to each
   template. Each template includes a `discount` block referencing the
   discount `_id` from step 3 (if it exists). Set `category: "Marketing"`,
   `schemaType: "marketing_email"`, `templateType: "default"`, and
   `team: <teamId>` on every template.
6. **Show the user a preview** of all 3 emails (section-by-section
   summary, copy highlights, discount placement, cadence). Wait for "go"
   confirmation before writing.
7. **POST × 3 to `createEmailTemplate`.** Capture each `output._id` —
   these are the flow-usable EmailTemplate IDs. **NOT
   `createSavedEmailTemplate`** — using that returns a SavedEmailTemplate
   wrapper ID that the flow worker can't resolve, and the builder will
   render empty cards.
8. **POST to `createAdvancedFlow`** at `/rpc/createAdvancedFlow` (note
   `/rpc/` namespace, NOT `/marketing-rpc/`). Single call ships the
   automation already enabled. See
   [references/automation-build.md](references/automation-build.md) for
   the exact step shape, field names, and trigger triple.
9. **Return the builder URL** to the user:
   `https://app.getredo.com/stores/<teamId>/marketing/automations/<automationId>`.
   Surface: the discount code, the 3 template names + IDs, any
   placeholder image URLs to replace, and a one-line "send yourself a
   test" reminder.

## The "rules" — flow type contracts

Full type contract snapshot lives in
[references/flow-types-snapshot.md](references/flow-types-snapshot.md).
Self-contained — includes every enum value, step interface, and the
canonical (key, schemaType, category) triples for marketing triggers.

For the welcome automation specifically:

| Signup source | key | schemaType | category |
| --- | --- | --- | --- |
| Redo forms / pop-ups | `email_signup` | `email_marketing_signup` | `Marketing` |
| Shopify customer signup | `email_signup_shopify` | `email_marketing_signup` | `Marketing` |

Both share the same `schemaType`. Only `key` differs.

Field-name conventions for send-email steps in marketing-signup flows:

- `emailAddressFieldName: "customerEmail"`
- `recipientNameFieldName: "customerFullName"`

These are not negotiable — the Temporal worker looks them up by exact
string match.

## Step graph cheat sheet

```
trigger ──► send_email_1 ──► wait_to_email_2 (2d) ──► send_email_2 ──► wait_to_email_3 (3d) ──► send_email_3 ──► end (do_nothing)
```

Cumulative days: Day 0 / Day 2 / Day 5. Relative waits: `0 → 2 → 3` (not
`0 → 2 → 5` — that's Day 0 / Day 2 / Day 7).

Full step JSON shape lives in
[references/automation-build.md](references/automation-build.md).

## Errors

| Symptom | Cause | Fix |
| ------- | ----- | --- |
| HTTP 401/403 | Token expired, wrong team, or missing one of the three required permissions | Re-issue token from a user with `MANAGE_TEMPLATES` + `MANAGE_CAMPAIGNS` + `MANAGE_AUTOMATIONS` |
| HTTP 500 on `createDiscount` with `Invalid Shopify domain` | Team has no real Shopify connection (or `storeUrl` is malformed) | Skip step 1; warn the user; templates render with empty discount placeholder until they link one in the builder |
| Builder shows empty email cards after `createAdvancedFlow` returns 200 | Used `SavedEmailTemplate._id` in `send_email.templateId` instead of `EmailTemplate._id` | Re-run step 7 using `createEmailTemplate`, not `createSavedEmailTemplate`. The wrapper IDs don't resolve. |
| HTTP 400 + Zod error on trigger | Used `schemaType` value as `key` or vice versa | `key: "email_signup"` (or `"email_signup_shopify"`), `schemaType: "email_marketing_signup"`. Different enums, similar names. |
| HTTP 400 + Zod error on wait | `timeUnit: "days"` instead of `"Days"` | `WaitTimeUnit` is PascalCase. Use `"Days"`, `"Hours"`, `"Minutes"`. |
| HTTP 400 + Zod error mentioning `versionGroupId` | Included it in the body | Drop it. The schema is `.omit({versionGroupId: true, _id: true, createdAt: true, updatedAt: true})` — server generates. |
| HTTP 400 + Zod refine "expected exactly one trigger" | Multiple trigger steps or none | Exactly one step with `type: "trigger"` in `newFlow.steps`. |
| HTTP 404 on `POST /marketing-rpc/createAdvancedFlow` | Wrong namespace | `createAdvancedFlow` is at `/rpc/`, not `/marketing-rpc/`. All other RPCs in this sequence (`createDiscount`, `createEmailTemplate`) are on `/marketing-rpc/`. |
| HTTP 500 (opaque) "Failed to create email template" on subsequent template calls | Suspect: side-effect throw in the create handler when team has malformed `storeUrl`. Seen on test teams without a real Shopify connection after the first call. | Retest on a Shopify-connected store. |
| Templates show empty discount code | `discount.discountId` not set or points to a non-existent discount | Re-link in the builder, or rebuild with a fresh discount |

## Reference

- Full RPC playbook + request bodies + payload shapes:
  [references/automation-build.md](references/automation-build.md)
- Per-email role + cadence rationale:
  [references/cadence-and-roles.md](references/cadence-and-roles.md)
- Companion skill for template generation: `create-redo-email`
  (its `references/block-schemas.md`, `references/copy-craft.md`, and
  `references/best-practices/` all apply here — load them as needed)
- Companion skill for prose review: `stop-slop`
- Type contract snapshot (self-contained):
  [references/flow-types-snapshot.md](references/flow-types-snapshot.md)
