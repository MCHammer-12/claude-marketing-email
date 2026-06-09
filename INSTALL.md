# Installing the Redo Marketing Skills

Three Claude skills for creating marketing emails and automations in a
merchant's Redo account, end-to-end, from a freeform description.

## What's in this repo

```
claude-marketing-email/
├── README.md
├── INSTALL.md                                  ← you are here
└── skill/
    ├── create-redo-email/                      ← one-off marketing email
    │   ├── SKILL.md
    │   └── references/
    │       ├── block-schemas.md
    │       ├── copy-craft.md
    │       ├── example-template.json
    │       └── best-practices/                 ← 10 brand archetypes
    ├── create-redo-welcome-automation/         ← 3-email welcome series
    │   ├── SKILL.md
    │   └── references/
    │       ├── automation-build.md
    │       ├── cadence-and-roles.md
    │       └── flow-types-snapshot.md
    └── create-redo-starter-pack/               ← full set of core flows
        ├── SKILL.md
        └── references/
            └── pack-composition.md
```

The skills are self-contained — all required values, enum casings, and
type contracts are inlined in their `references/`.

## Prereqs

- **Claude Code** (`npm install -g @anthropic-ai/claude-code` if you
  don't have it) or **Claude.ai** with skill upload
- A **merchant session JWT** with the right permissions (see below),
  stored in a local file the skills read — **never pasted into Claude**.
  Each skill checks the JWT and tells you if it's missing perms.

## Install (Claude Code)

```bash
# From wherever you cloned this repo:
cd claude-marketing-email/
ln -s "$(pwd)/skill/create-redo-email" ~/.claude/skills/create-redo-email
ln -s "$(pwd)/skill/create-redo-welcome-automation" ~/.claude/skills/create-redo-welcome-automation
ln -s "$(pwd)/skill/create-redo-starter-pack" ~/.claude/skills/create-redo-starter-pack
```

Symlinks keep the install live — if you `git pull` updates, the
installed skills update too.

For a copy install instead (no live updates):

```bash
cp -r skill/create-redo-email ~/.claude/skills/
cp -r skill/create-redo-welcome-automation ~/.claude/skills/
cp -r skill/create-redo-starter-pack ~/.claude/skills/
```

Verify:

```bash
ls ~/.claude/skills/ | grep create-redo
```

You should see all three skill names. Restart Claude Code (or start a
fresh session) so the new skills are picked up.

## Install (Claude.ai web)

1. Zip each skill folder:
   ```bash
   cd skill/
   zip -r create-redo-email.zip create-redo-email/
   zip -r create-redo-welcome-automation.zip create-redo-welcome-automation/
   zip -r create-redo-starter-pack.zip create-redo-starter-pack/
   ```
2. Go to your Claude.ai settings → Skills → Upload skill
3. Upload each `.zip`
4. Enable them for the conversation you want to use them in

## Get and store your session JWT

The skills write into a specific merchant's Redo account. They need a
session token for a user on that team with the right permissions.

**Required permissions:**

| Skill | Permissions |
| ----- | ----------- |
| `create-redo-email` | `MANAGE_TEMPLATES` |
| `create-redo-welcome-automation` | `MANAGE_TEMPLATES` + `MANAGE_CAMPAIGNS` + `MANAGE_AUTOMATIONS` |
| `create-redo-starter-pack` | `MANAGE_TEMPLATES` + `MANAGE_CAMPAIGNS` + `MANAGE_AUTOMATIONS` |

**How to get the token:**

1. Log into the merchant app at `https://app.getredo.com` as a user with
   the required permissions
2. Open browser devtools (Cmd+Opt+I on macOS) → Network tab
3. Click any XHR to `app-server.getredo.com` — its request headers carry
   an `Authorization:` header with the JWT
4. Copy the value (the raw JWT — three base64 chunks separated by dots,
   starts with `eyJ...`)

**Store it locally — do NOT paste it into Claude.** Your session JWT is a
live credential; pasting it into the chat puts it in the conversation
transcript. Save it to a private file **in your own terminal**, and the
skills read it from there — the token never enters a conversation:

```bash
mkdir -p ~/.redo && chmod 700 ~/.redo
(umask 077; cat > ~/.redo/jwt)     # paste the JWT, press Enter, then Ctrl-D
```

This writes an owner-only file; the paste never hits the chat or your
shell history. Prefer macOS Keychain (also keeps it off your screen)?

```bash
security add-generic-password -a "$USER" -s redo-jwt -w   # prompts for the value, no echo
```

…then tell Claude to read it with
`security find-generic-password -s redo-jwt -w` instead of `cat ~/.redo/jwt`.

**Verify it has the right shape** — reads from the file and prints only the
claims, never the token:

```bash
cut -d. -f2 ~/.redo/jwt | base64 -d 2>/dev/null | jq '{aud, exp, sub}'
```

You should see:
- `aud: "mcht/<teamId>"` — confirms which team it writes to
- `exp` (unix seconds) in the future
- `sub` — your user ID (used as `createdByUserId` for automations)

If `exp` has passed, log out and back in, and re-save the file.

## Smoke test

Open a fresh Claude Code session in any directory and run:

```
Create a Redo email for a 20% off summer sale on sustainable t-shirts.
Brand voice: friendly, casual. One hero image, one CTA. Use coral
(#FF6B5C) as the accent color.
```

Claude should invoke `create-redo-email`, read your token from
`~/.redo/jwt` (it never asks you to paste it), ask you to confirm
name/subject/archetype, show a preview, and on "go" POST to
`createEmailTemplate` and return the builder URL.

For the welcome skill:

```
Build a 3-email welcome series for [brand name]. They sell [what].
Brand voice: [tone]. Use a 10% off discount with code WELCOME10.
Signups come from Redo forms.
```

This will create the discount (if Shopify is connected), the 3
templates, and the automation in one flow.

## Troubleshooting

| Symptom | Fix |
| ------- | --- |
| Claude doesn't pick up the skill | Restart Claude Code; verify symlink with `ls ~/.claude/skills/` |
| HTTP 401/403 | Token expired or wrong team. Re-grab from browser devtools. |
| HTTP 403 specifically | Token is for a user missing one of the required permissions. Re-issue from a user with all three (`MANAGE_TEMPLATES` + `MANAGE_CAMPAIGNS` + `MANAGE_AUTOMATIONS` for the welcome / starter-pack skills). |
| HTTP 500 "Failed to create email template" on the second+ template | Seen on test teams without a real Shopify connection (malformed `storeUrl`). Retest against a Shopify-connected team. |
| HTTP 500 "Invalid Shopify domain" on `createDiscount` | Team has no real Shopify connection. The welcome / starter-pack skills detect this and offer to skip the discount step. |
| Builder shows empty email cards after the automation creates | The `send_email` step used a `SavedEmailTemplate._id` instead of an `EmailTemplate._id`. The skills always use `createEmailTemplate` — re-run if you hit this. |
| Generated email looks "AI-templated" | Push back on the description. Ask for: real product names, named hero shot, specific brand voice descriptors, ideally 2-3 reference URLs to the brand's site. |

## Updating

If you installed via symlink, just `git pull` — the symlinked skill
folders point at the same files.

If you copied: re-run the `cp -r` commands or re-upload to Claude.ai.
