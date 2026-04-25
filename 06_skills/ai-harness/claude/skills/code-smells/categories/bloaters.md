# Bloaters

Bloaters are code, methods, and classes that have grown so large that they are
hard to work with. They accumulate gradually as the program evolves, especially
when no one makes an effort to eradicate them.

---

## Long Method

A method that contains too many lines of code.

### Detection Criteria

- Method body exceeds ~20 lines of logic (excluding declarations, blank lines,
  and braces).
- You feel the need to add a comment explaining a section within the method.
- The method does more than one conceptual task.
- Multiple levels of nesting (3+ levels of indentation).
- Hard to name the method because it does several things.

### Why It's a Problem

- Harder to understand, test, and reuse.
- Hides duplicate code within long flows.
- Small changes have unpredictable blast radius.

### Recommended Refactorings

- **Extract Method** — pull coherent fragments into named methods.
- **Replace Temp with Query** — eliminate temporaries that block extraction.
- **Introduce Parameter Object** / **Preserve Whole Object** — reduce parameter
  clutter that discourages extraction.
- **Replace Method with Method Object** — when local variables make extraction
  impossible, move the entire method into its own class.
- **Decompose Conditional** — extract complex conditional branches.

---

## Large Class

A class that has too many fields, methods, or lines of code.

### Detection Criteria

- Class has 10+ fields.
- Class has 20+ public methods.
- Class file exceeds ~300 lines.
- You can identify two or more distinct responsibilities.
- Some fields/methods are only used together in a subset (indicating a hidden
  class).

### Why It's a Problem

- Violates Single Responsibility Principle.
- Hard to understand the class as a whole.
- Changes to one responsibility risk breaking another.
- Difficult to test in isolation.

### Recommended Refactorings

- **Extract Class** — move a coherent group of fields and methods to a new class.
- **Extract Subclass** — when a subset of features is used only in some cases.
- **Extract Interface** — when clients use different subsets of the class.
- **Duplicate Observed Data** — when a class mixes domain and UI logic.

---

## Primitive Obsession

Using primitive types (strings, ints, arrays) instead of small objects for
simple tasks like currency, ranges, phone numbers, etc.

### Detection Criteria

- Fields like `string zipCode`, `int startRange / int endRange` instead of
  value objects.
- Constants or enums used as type codes.
- String field names encoding meaning (e.g., `string phoneType`).
- Repeated validation/formatting logic for the same kind of value.

### Why It's a Problem

- Validation and behavior scatter across the codebase.
- No type safety — any string can be passed where a phone number is expected.
- Duplicate logic for formatting, comparison, validation.

### Recommended Refactorings

- **Replace Data Value with Object** — wrap the primitive in a meaningful class.
- **Replace Type Code with Class** — create a class instead of coded constants.
- **Replace Type Code with Subclasses** / **Replace Type Code with
  State/Strategy** — when type codes influence behavior.
- **Introduce Parameter Object** — when the same group of primitives travels
  together.
- **Replace Array with Object** — when arrays hold heterogeneous data.

---

## Long Parameter List

A method takes more than 3–4 parameters.

### Detection Criteria

- Method signature has 4+ parameters.
- You pass data that the method could retrieve itself.
- Several parameters are always passed together across different methods.
- Boolean flag parameters that switch method behavior.

### Why It's a Problem

- Hard to read, remember parameter order, and call correctly.
- Long lists often signal the method is doing too much.
- Changes to the parameter list ripple through all callers.

### Recommended Refactorings

- **Replace Parameter with Method Call** — let the method fetch what it needs.
- **Preserve Whole Object** — pass the object instead of extracting fields from
  it.
- **Introduce Parameter Object** — group related parameters into a single
  object.

---

## Data Clumps

Groups of data that frequently appear together (e.g., three fields always passed
as a trio to methods).

### Detection Criteria

- The same 3+ fields appear together in multiple classes.
- The same 3+ parameters appear together in multiple method signatures.
- Removing one of the group would make the others meaningless.
- You see parallel arrays or matching indexes (e.g., `names[i]`,
  `addresses[i]`).

### Why It's a Problem

- Duplicate handling logic for the group.
- Adding a new member to the group requires updating every location.
- Obscures the domain concept the group represents.

### Recommended Refactorings

- **Extract Class** — create a class for the clump.
- **Introduce Parameter Object** — replace parameter groups with the new class.
- **Preserve Whole Object** — pass the containing object instead of individual
  fields.
