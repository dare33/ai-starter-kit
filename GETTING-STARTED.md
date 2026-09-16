# Getting started — one page

This kit sets up Claude Code the way an experienced user runs it: standing
rules for how it works with you, a small team of helper agents it can delegate
to, the ability to get a second opinion from OpenAI's GPT models from inside
Claude, and three ready-made recipes for starting a project properly. Claude
does the whole install for you. You never open a terminal yourself.

You need a Mac, about 45 minutes, and a **Claude Pro or Max** subscription.
Add an Apple-silicon Mac and a ChatGPT account (paid plans give more usage)
for the optional GPT second-opinion part (any Mac works for everything
else); if it turns out your plan doesn't include Codex, that's fine — skip
it and everything else still works.

## 1. Install the Claude app

Download Claude for Mac from **claude.ai/download**, open it, and sign in
with your Claude account.

## 2. Open a Code session

In the Claude app, click the **Code** tab. When it asks where to work,
choose Local if it offers a choice, then pick your home folder (the folder
with the little house icon and your username, not Desktop or Documents).

## 3. Paste this one message

```
Please set up my computer using the AI starter kit at https://github.com/dare33/ai-starter-kit. First check Apple's command line tools with `xcode-select -p` and install them if missing (tell me when to click Install). Then clone the kit into ~/ai-starter-kit and follow the SETUP-AGENT.md file inside it, phase by phase.
```

## 4. Do the three things it asks you to do

It will ask your permission several times — click Allow. It will also ask to
run the installer outside its safety sandbox, and once whether Claude may
control Terminal — click Allow both times. Three steps need something from you:

1. **Click Install** in a small window that pops up (Apple's developer tools).
2. **Type your Mac password** into a Terminal window that Claude opens for
   you, then press Return. Nothing appears while you type; that's normal.
3. **Log in to ChatGPT** in your browser, if you have an account.

Everything else it does itself. Read what it says; it will tell you plainly
if anything went wrong and what it needs.

## 5. Answer a few questions

Near the end, Claude asks how to address you, what you'll mostly use it for,
and how much it should check in with you. Your answers are written into your
personal rules file so every future session starts knowing them.

## 6. Quit and reopen Claude, then try it

- Ask it to **plan a small project before building it**. Watch it plan, ask
  you to confirm, then delegate the build to a helper.
- Type **/gpt** followed by a question to get GPT's take (if you set up GPT).

When you want to start a real software project, ask Claude to read
`~/ai-starter-kit/suites` and walk you through the solo-speed suite (a free
GitHub account is optional — Claude can keep it on your Mac only). For a
documents or admin project instead, open the session in that project's folder
and ask Claude to read the ops suite's `ABOUTME.md` and run its kickoff prompt.

## If something goes wrong

Paste this into Claude: *"Re-run ~/ai-starter-kit/SETUP-AGENT.md; it is safe
to repeat."* It skips what is already done. Still stuck? Ask the person who
sent you this kit and paste them what Claude said.

Mac only for now. A Windows version can follow if you need it.
