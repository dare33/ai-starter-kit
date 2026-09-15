# Getting started — one page

This kit sets up Claude Code the way an experienced user runs it: standing
rules for how it works with you, a small team of helper agents it can delegate
to, the ability to get a second opinion from OpenAI's GPT models from inside
Claude, and two ready-made recipes for starting a project properly. Claude
does the whole install for you. You never open a terminal yourself.

You need a Mac, about 45 minutes, a **Claude Pro or Max** subscription, and
optionally a **ChatGPT Plus or Pro** subscription (for the GPT second-opinion
part; everything else works without it).

## 1. Install the Claude app

Download Claude for Mac from **claude.ai/download**, open it, and sign in
with your Claude account.

## 2. Open a Code session

In the Claude app, click the **Code** tab. When it asks which folder to work
in, choose your home folder (it is the folder with the little house icon and
your username, not Desktop or Documents) and click Open.

## 3. Paste this one message

```
Please set up my computer using the AI starter kit at https://github.com/dare33/ai-starter-kit. First check Apple's command line tools with `xcode-select -p` and install them if missing (tell me when to click Install). Then clone the kit into ~/ai-starter-kit and follow the SETUP-AGENT.md file inside it, phase by phase.
```

## 4. Do the three things it asks you to do

It will ask your permission several times as it goes — click Allow. Once it
will ask to run the installer outside its safety sandbox; that is expected,
click Allow once. Your Mac will also ask once whether Claude may control
Terminal — click Allow. Three steps need something from you:

1. **Click Install** in a small window that pops up (Apple's developer tools).
2. **Type your Mac password** into a Terminal window that Claude opens for
   you, then press Return. Nothing appears while you type; that's normal.
3. **Log in to ChatGPT** in your browser, if you have a subscription.

Everything else it does itself. Read what it says; it will tell you plainly
if anything went wrong and what it needs.

## 5. Answer a few questions

Near the end, Claude asks how to address you, what you'll mostly use it for,
and how much it should check in with you. Your answers are written into your
personal rules file so every future session starts knowing them.

## 6. Quit and reopen Claude, then try it

- Ask it to **plan a small project before building it**. Watch it plan,
  ask you to confirm, then delegate the build to a helper.
- Type **/gpt** followed by a question to get GPT's take.
- Ask Claude to help you write a document, or to plan a small personal
  project and show you the plan before doing anything.

When you want to start a real software project, ask Claude to read
`~/ai-starter-kit/suites` and walk you through the solo-speed suite — that
step needs a free GitHub account, which Claude will help you set up when you
get there.

## If something goes wrong

Paste this into Claude: *"Re-run ~/ai-starter-kit/SETUP-AGENT.md; it is safe
to repeat."* It skips what is already done. Still stuck? Ask the person who
sent you this kit and paste them what Claude said.

Mac only for now. A Windows version can follow if you need it.
