# Object-Orientation Abusers

These smells indicate incomplete or incorrect application of object-oriented
programming principles. They often arise when procedural thinking is applied
in an OO context, or when inheritance is used improperly.

---

## Switch Statements

Complex `switch` or `if-else` chains that dispatch behavior based on a type
code or object type, often duplicated across the codebase.

### Detection Criteria

- `switch`/`if-else` dispatching on a type code, enum, or `typeof`/`instanceof`
  check.
- The same switch structure appears in multiple places.
- Adding a new type requires modifying multiple switch statements.
- The switch selects behavior rather than data.

### Why It's a Problem

- Adding a new variant means hunting down every switch.
- Violates the Open/Closed Principle.
- Duplicated dispatch logic across methods.

### Recommended Refactorings

- **Replace Conditional with Polymorphism** — move each branch into a subclass
  or strategy override.
- **Replace Type Code with Subclasses** — when the type code determines behavior.
- **Replace Type Code with State/Strategy** — when the type changes at runtime.

---

## Temporary Field

A field that is only set and used under certain circumstances, remaining empty
or null the rest of the time.

### Detection Criteria

- A field is only assigned in one specific method or code path.
- The field is checked for null/empty before use in unrelated methods.
- The field exists to pass data between methods instead of using parameters.
- Removing the field would require only localized changes.

### Why It's a Problem

- Readers expect all fields to be meaningful throughout the object's lifetime.
- Code becomes fragile when someone calls methods in unexpected order.
- Makes the class harder to reason about.

### Recommended Refactorings

- **Extract Class** — move the temporary field and its related methods into a
  dedicated class.
- **Introduce Null Object** — provide a default object instead of null checks.

---

## Refused Bequest

A subclass inherits methods and data from a parent but only uses some of them,
or overrides them to do nothing.

### Detection Criteria

- Subclass overrides parent methods with empty bodies or throws
  `NotSupportedException`.
- Subclass uses only a small fraction of inherited methods/fields.
- The "is-a" relationship doesn't make domain sense.
- Parent class was designed for a specific subclass and forces unneeded
  interface on siblings.

### Why It's a Problem

- Violates the Liskov Substitution Principle.
- The inheritance hierarchy becomes confusing and misleading.
- Users of the parent type may call methods that silently do nothing.

### Recommended Refactorings

- **Replace Inheritance with Delegation** — use composition instead.
- **Extract Superclass** — pull only the truly shared behavior into a parent.
- **Push Down Method** / **Push Down Field** — move the unwanted members down
  to the subclass that actually needs them.

---

## Alternative Classes with Different Interfaces

Two classes perform the same function but have different method names or
signatures, making them non-interchangeable.

### Detection Criteria

- Two classes do similar things but with different method names.
- You find yourself writing adapter code to switch between them.
- Client code uses conditionals to choose between the two classes.
- Both classes could satisfy the same interface if their methods were aligned.

### Why It's a Problem

- Duplicate implementation of the same concept.
- Cannot substitute one for the other without wrapper code.
- Cognitive overhead maintaining parallel implementations.

### Recommended Refactorings

- **Rename Method** — align method names so both classes share a common
  interface.
- **Extract Superclass** or **Extract Interface** — formalize the shared
  contract.
- **Move Method** — redistribute methods so responsibilities align.
