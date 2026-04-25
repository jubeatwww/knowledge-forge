# Change Preventers

These smells mean that changing something in one place forces many changes
elsewhere. They make the codebase rigid and expensive to evolve.

---

## Divergent Change

A single class is frequently modified for different reasons. Each change affects
a different subset of the class's methods.

### Detection Criteria

- You change the class for reason A (e.g., new database) and touch methods X, Y.
- You change the class for reason B (e.g., new report format) and touch methods
  P, Q — a completely different set.
- The class has methods that group into clusters with little interaction between
  groups.
- The class has multiple distinct reasons to change (violates SRP).

### Why It's a Problem

- Every unrelated change risks breaking something in another responsibility.
- The class grows uncontrollably because it attracts every kind of change.
- Hard to test one responsibility in isolation.

### Recommended Refactorings

- **Extract Class** — split the class so each resulting class has a single
  reason to change.

---

## Shotgun Surgery

A single logical change requires many small edits scattered across multiple
classes.

### Detection Criteria

- Adding a feature or fixing a bug touches 5+ files.
- The same kind of edit (e.g., adding a field) is repeated across classes.
- A naming convention or constant change requires a global find-and-replace.
- Related logic is spread thin across the codebase.

### Why It's a Problem

- Easy to miss one of the scattered edit points.
- Increases the chance of introducing bugs during change.
- Makes changes time-consuming and error-prone.

### Recommended Refactorings

- **Move Method** / **Move Field** — consolidate related behavior into one
  class.
- **Inline Class** — when a class does too little and its behavior should merge
  with another.

---

## Parallel Inheritance Hierarchies

Every time you create a subclass of one class, you must also create a subclass
of another class. This is a special case of Shotgun Surgery.

### Detection Criteria

- Two class hierarchies mirror each other (e.g., `Order` → `DomesticOrder` /
  `InternationalOrder` and `Shipping` → `DomesticShipping` /
  `InternationalShipping`).
- Adding a variant to one hierarchy always requires adding one to the other.
- Class name prefixes or suffixes are shared across hierarchies.

### Why It's a Problem

- Duplication of hierarchy structure.
- Forgetting to add the parallel subclass causes runtime errors.
- The coupling between hierarchies is hidden and fragile.

### Recommended Refactorings

- **Move Method** / **Move Field** — merge one hierarchy into the other until
  the parallel hierarchy can be removed.
- **Replace Inheritance with Delegation** — one hierarchy delegates to the
  other instead of mirroring it.
