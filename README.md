# claude-marketing-email

Claude skills that build Redo marketing assets end-to-end from freeform
descriptions — generated for your specific brand, then written straight
into your Redo account through the same APIs the dashboard uses.

- `create-redo-email` — a single marketing email
- `create-redo-welcome-automation` — a 3-email welcome series with a
  discount, wired into a live automation in one call
- `create-redo-starter-pack` — a complete set of core flows (welcome,
  abandoned cart, browse abandonment, optional checkout abandonment),
  each brand-customized and enabled

## Install

### With Claude Code (easiest)

Open any Claude Code session, anywhere on your system, and prompt:

> Install the Claude skills from
> https://github.com/MCHammer-12/claude-marketing-email — clone the repo
> and symlink the skills in `skill/` into `~/.claude/skills/` so
> `git pull` keeps them in sync.

Claude clones the repo, sets up the symlinks, and tells you when it's
done. Restart Claude Code (`/quit` then re-run `claude`) so the new
skills register.

#### Manual clone if you prefer

```bash
git clone https://github.com/MCHammer-12/claude-marketing-email.git
cd claude-marketing-email
ln -s "$(pwd)/skill/create-redo-email" ~/.claude/skills/create-redo-email
ln -s "$(pwd)/skill/create-redo-welcome-automation" ~/.claude/skills/create-redo-welcome-automation
ln -s "$(pwd)/skill/create-redo-starter-pack" ~/.claude/skills/create-redo-starter-pack
```

### With Claude.ai web

1. Clone the repo (or download as zip).
2. Zip each skill folder:
   ```bash
   cd skill
   zip -r create-redo-email.zip create-redo-email
   zip -r create-redo-welcome-automation.zip create-redo-welcome-automation
   zip -r create-redo-starter-pack.zip create-redo-starter-pack
   ```
3. Claude.ai → settings → Skills → Upload each `.zip`.

### Manual / detailed

[`INSTALL.md`](INSTALL.md) has the explicit shell commands, JWT
acquisition steps, permission requirements, and a full troubleshooting
table.

## Try it

In a fresh Claude Code session (anywhere on your system, doesn't have to
be in this repo), prompt:

> Create a Redo email for a 20% off summer sale on sustainable t-shirts.
> Brand voice: friendly, casual. Use coral as the accent color.

Or, for the welcome flow:

> Build a 3-email welcome series for [brand]. They sell [what]. Brand
> voice: [tone]. Use a 10% off discount with code WELCOME10. Signups
> come from Redo forms.

Or, to stand up a new store's core flows at once:

> Build a starter pack of marketing automations for [brand]. They sell
> [what]. Brand voice: [tone]. Include welcome, abandoned cart, and
> browse abandonment.

Claude picks up the right skill, reads your locally-stored session JWT
(from `~/.redo/jwt` — it never asks you to paste it into the chat),
walks you through generation, and writes to the Redo API. You get the
builder URL(s) back.

## You'll need

- **Claude Code** (`npm install -g @anthropic-ai/claude-code`) or
  Claude.ai
- A **merchant session JWT** for the Redo team you want to write to —
  grab it from your browser devtools while logged into
  `app.getredo.com`, then run `./connect.sh` to save it to `~/.redo/jwt`
  (never paste it into Claude). Full instructions in
  [`INSTALL.md`](INSTALL.md).
- **Marketing permissions** on that team:
  - Email skill: `MANAGE_TEMPLATES`
  - Welcome / starter-pack skills:
    `MANAGE_TEMPLATES` + `MANAGE_CAMPAIGNS` + `MANAGE_AUTOMATIONS`

## What's in the repo

```
skill/
├── create-redo-email/              — one-off marketing email
├── create-redo-welcome-automation/ — 3-email welcome series
└── create-redo-starter-pack/       — full set of core flows
INSTALL.md                          — detailed install + JWT + troubleshooting
```

## Updating

If you installed via symlink: `git pull` updates the live skills.
If you copied or uploaded to Claude.ai: re-install after pulling.
