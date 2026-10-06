<!--
What this file answers: the shape of the project — what modules exist, where responsibilities live, and why it's drawn this way.
When to update: any new module, renamed boundary, or refactor that moves responsibility across a boundary. Same turn as the code change.
Example shape rule: "app/ screens talk to services/, never the other way. Components never call services directly."
Leave this file blank during install. Fill it in after the first real code-changing session — premature architecture documentation rots fastest and most projects don't know their real shape on day one.
-->

# System design

## Shape (one paragraph)

_(One paragraph: what is this thing at its highest level? "A single-user app that does X by wiring Y to Z." Readable cold.)_

<DESCRIBE>

## Block diagram

_(ASCII block diagram showing module / service / layer boundaries and the arrows between them. Keep it simple — don't draw every file, draw the boundaries.)_

```
<DESCRIBE>
```

## Module boundaries

_(Per-module: what it owns, what it does NOT own, who it can call, who can call it. One bullet per module.)_

- **<module>** — <DESCRIBE>

## Why this shape

_(Non-obvious reasons the shape is what it is. Constraints from external systems, past mistakes we're not repeating, tradeoffs we locked in via ADRs. Point at the ADRs.)_

<DESCRIBE>
