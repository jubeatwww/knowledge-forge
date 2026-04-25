# Dispensables

A dispensable is something pointless and unneeded whose absence would make the
code cleaner, more efficient, and easier to understand.

---

## Comments

Excessive or explanatory comments that compensate for unclear code rather than
supplementing clear code.

### Detection Criteria

- A comment explains *what* the next few lines do (the code itself should say
  that).
- A comment apologizes for confusing code instead of the code being rewritten.
- Commented-out code remains in the file.
- Comments restate the obvious (e.g., `// increment counter` above `i++`).

### Why It's a Problem

- Comments rot — they go out of sync with the code they describe.
- They signal that the code is not self-explanatory.
- Commented-out code creates noise and uncertainty.

### Recommended Refactorings

- **Extract Method** — name the extracted method to make the comment
  unnecessary.
- **Rename Method** / **Extract Variable** — improve naming so intent is clear.
- Delete commented-out code (version control remembers it).

> **Note**: Comments that explain *why* (business rules, non-obvious trade-offs,
> workarounds for external constraints) are valuable and should be kept.

---

## Duplicate Code

The same code structure or logic appears in two or more places.

### Detection Criteria

- Identical or near-identical blocks in the same class.
- Similar code across sibling subclasses.
- Similar code in unrelated classes.
- Same algorithm implemented differently in different locations.

### Why It's a Problem

- Bug fixes must be applied in multiple places.
- Changes diverge silently over time.
- Increases codebase size without adding value.

### Recommended Refactorings

- **Extract Method** — when duplicates are in the same class.
- **Pull Up Method** / **Form Template Method** — when duplicates are in
  sibling subclasses.
- **Extract Class** — when duplicates are in unrelated classes.
- **Substitute Algorithm** — when two implementations achieve the same result
  differently.

---

## Lazy Class

A class that does too little to justify its existence.

### Detection Criteria

- The class was created for a planned feature that never materialized.
- The class has been reduced through refactoring until almost nothing remains.
- The class has 1–2 trivial methods and no fields (or vice versa).
- The class is a thin wrapper that adds no behavior.

### Why It's a Problem

- Every class adds cognitive overhead and maintenance cost.
- Indirection without benefit makes the code harder to follow.

### Recommended Refactorings

- **Inline Class** — merge the class into its sole user.
- **Collapse Hierarchy** — when a subclass is nearly identical to its parent.

---

## Data Class

A class that has only fields, getters, and setters — it holds data but has no
meaningful behavior.

### Detection Criteria

- Class consists only of public fields or fields with getters/setters.
- No methods contain business logic.
- Other classes manipulate the data class's fields extensively (the behavior
  lives elsewhere).
- The class is essentially a struct/record with no encapsulation.

### Why It's a Problem

- Business logic that belongs to the data ends up scattered in clients.
- The class cannot protect its own invariants.
- Changes to data format require updating all client code.

### Recommended Refactorings

- **Encapsulate Field** / **Encapsulate Collection** — restrict direct access.
- **Move Method** — move behavior from clients into the data class.
- If the class holds immutable data for transfer purposes (DTO), it may be
  acceptable.

---

## Dead Code

Code that is no longer reachable or used: unreachable branches, unused
variables, parameters, methods, or classes.

### Detection Criteria

- Methods or classes never called from production or test code.
- Variables assigned but never read.
- Conditional branches that can never be reached.
- Parameters that are always passed the same value or never inspected.

### Why It's a Problem

- Developers waste time reading and maintaining unused code.
- Dead code may mask bugs (someone might think it's active).
- Increases compilation and cognitive cost.

### Recommended Refactorings

- Delete the unused code. Use version control to recover it if needed.
- **Remove Parameter** — for unused method parameters.
- IDE/linter warnings are the best detection tool.

---

## Speculative Generality

Code created "just in case" for a future need that never arrived — abstract
classes, hooks, parameters, or frameworks that no current use case requires.

### Detection Criteria

- Abstract classes or interfaces with only one implementor.
- Methods with unused parameters kept "for future flexibility."
- Delegation that goes through unnecessary layers.
- Feature flags or config options that have never been toggled.

### Why It's a Problem

- Adds complexity without delivering value.
- Misleads future readers about the system's actual variability.
- Maintenance cost for unused abstractions.

### Recommended Refactorings

- **Collapse Hierarchy** — merge single-implementor abstract classes.
- **Inline Class** — remove unnecessary delegation layers.
- **Remove Parameter** — drop unused parameters.
- **Rename Method** — when overly generic names obscure actual purpose.
