# Organizing Data

Improve data handling, encapsulation, and the way classes represent values and
type information.

Reference: https://refactoring.guru/refactoring/techniques/organizing-data

---

## Self Encapsulate Field

**When**: You access a field directly but want to add logic (validation,
lazy init) to the access.

**Procedure**:
1. Create a getter and setter for the field.
2. Replace all direct field references with getter/setter calls.

**Resolves**: enables future flexibility for field access logic.

---

## Replace Data Value with Object

**When**: A data field needs associated behavior (formatting, validation).

**Procedure**:
1. Create a new class with the field and its behavior.
2. Replace the field with an instance of the new class.
3. Move related behavior from client code into the new class.

**Resolves**: Primitive Obsession.

---

## Change Value to Reference

**When**: Many equal instances of a class should be a single shared instance.

**Procedure**:
1. Use a factory method or registry to return the canonical instance.
2. Replace constructor calls with the factory/registry lookup.

---

## Change Reference to Value

**When**: A reference object is small, immutable, and awkward to manage.

**Procedure**:
1. Make the object immutable (remove setters).
2. Implement value-based equality.
3. Replace identity comparison with equality comparison.

---

## Replace Array with Object

**When**: An array contains elements of different meaning (e.g.,
`row[0] = name`, `row[1] = age`).

**Procedure**:
1. Create a class with a named field for each element.
2. Replace array reads/writes with field access.
3. Delete the array.

**Resolves**: Primitive Obsession.

---

## Duplicate Observed Data

**When**: Domain data is stored in a GUI component and is needed by domain
logic.

**Procedure**:
1. Create a domain class for the data.
2. Use an observer pattern to sync the GUI with the domain object.

**Resolves**: Large Class (UI + logic).

---

## Replace Magic Number with Symbolic Constant

**When**: Code contains numeric or string literals with special meaning.

**Procedure**:
1. Declare a constant with a descriptive name.
2. Replace all occurrences of the literal with the constant.

---

## Encapsulate Field

**When**: A class has a public field.

**Procedure**:
1. Make the field private.
2. Create a getter (and setter if needed).

**Resolves**: Data Class.

---

## Encapsulate Collection

**When**: A class exposes a collection directly via a getter.

**Procedure**:
1. Have the getter return a read-only view or copy.
2. Add methods to add/remove elements.
3. Remove the setter or have it copy the incoming collection.

**Resolves**: Data Class.

---

## Replace Type Code with Class

**When**: A type code (int/string constant) doesn't affect behavior.

**Procedure**:
1. Create a new class with instances for each code value.
2. Replace the type code field with the new class type.

**Resolves**: Primitive Obsession.

---

## Replace Type Code with Subclasses

**When**: A type code affects class behavior (controls conditionals).

**Procedure**:
1. Create a subclass for each type code value.
2. Move code-specific behavior to the appropriate subclass.
3. Remove the type code field.

**Resolves**: Primitive Obsession, Switch Statements.

---

## Replace Type Code with State/Strategy

**When**: A type code affects behavior and changes at runtime.

**Procedure**:
1. Create a state/strategy class with subclasses for each code value.
2. The host class delegates to the state/strategy object.
3. Changing the type replaces the state/strategy instance.

**Resolves**: Primitive Obsession, Switch Statements.

---

## Replace Subclass with Fields

**When**: Subclasses differ only in constant-returning methods.

**Procedure**:
1. Replace the methods with fields in the parent class.
2. Set the field values in the constructor.
3. Remove the subclasses.

**Resolves**: Speculative Generality, unnecessary hierarchy.
