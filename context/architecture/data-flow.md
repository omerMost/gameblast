<!--
What this file answers: the happy-path walkthrough of the project's primary flow, from user input (or request) to final output.
When to update: any change that alters the sequence, adds a step, or changes where a step runs. Same turn as the code change.
Example flow for an app: "1. user taps GALLERY → 2. expo-image-picker returns base64 → 3. /processing calls Claude → 4. /result renders the parsed event."
Leave this file blank during install. Fill it in after the first real code-changing session — the real flow often differs from the imagined one, and writing it prematurely locks in fiction.
-->

# Data flow

One end-to-end walk of the primary flow. If there are several, pick the one that most defines the product and walk *that* one. Document secondary flows only when they diverge in interesting ways.

## Primary flow: <name the flow>

_(e.g. "Capture → extract → save" for an app; "Request → handlers → response" for a service; "Input → transform → output" for a pipeline.)_

1. <DESCRIBE step>
2. <DESCRIBE step>
3. <DESCRIBE step>
4. ...

## Failure paths

_(Where does this flow break? What errors can surface at each step, and what's the user-visible behavior when they do?)_

- **Step N (<what fails>)** — <DESCRIBE> → user sees <DESCRIBE>.

## Trust boundaries

_(Which steps validate input, which ones trust their caller. The rule in most projects: validate at the system boundary (user input, external API responses), trust everything in between. Document where those boundaries are.)_

<DESCRIBE>
