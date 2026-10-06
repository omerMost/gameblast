Read the following files in order — stop reading once you have enough context:
1. `context/STATE.md` — current project snapshot
2. `context/tasks/backlog.md` — full work queue
3. `context/tasks/inbox.md` — raw phone captures (may not exist). Do NOT groom it here — just count pending lines; if there are any, add one line above the menu: `Inbox: N captured idea(s) awaiting grooming — run /backlog to file them.`

Then present a clean numbered menu of every item in **Now**, **Next**, and **Later/stretch**. Format each line as:
`[N] Section — Item title`

Example:
```
[1] Now — Fix: delay before processing animation
[2] Next — Refactor X into Y
[3] Later — Upgrade dependency Z
...
```

Ask the user: "Which item do you want to work on? (enter a number)"

Once they choose:
- Read any session notes or ADRs referenced in that backlog entry
- Briefly confirm what you understand the task to be (2–3 sentences max)
- Ask if they're ready to start or want to discuss first

Do not start writing any code until the user says they're ready.
