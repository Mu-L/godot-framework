---
description: Skill controller — run skill scripts, install missing tools
alwaysApply: true
---

# Skill Controller

When a skill has scripts, run them from the project root as the skill docs say. Do not use your own commands unless the skill says the script is for reference only.

## No bypass

Even when a skill script wraps FFmpeg or another CLI, call it through the skill script — do not hand-write equivalent commands.

## Workflow

1. Find the script and command in the skill docs.
2. Run it. If something is missing, install it ([dependency-manager](dependency-manager.md) or skill setup steps), then run the same command again.
3. If it fails, fix the setup or inputs and try again. Ask before using a different approach.

After installing anything, say what you installed and which command you ran.
