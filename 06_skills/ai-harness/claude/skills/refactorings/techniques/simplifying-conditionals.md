# Simplifying Conditional Expressions

Reduce complexity in conditional logic. Complex conditionals are hard to read,
test, and extend.

Reference: https://refactoring.guru/refactoring/techniques/simplifying-conditional-expressions

---

## Decompose Conditional

**When**: A conditional has a complex condition, complex then-branch, or
complex else-branch.

**Procedure**:
1. Extract the condition into a method with a descriptive name.
2. Extract the then-branch into a method.
3. Extract the else-branch into a method.

**Resolves**: Long Method, readability.

---

## Consolidate Conditional Expression

**When**: Multiple conditionals lead to the same result.

**Procedure**:
1. Merge the conditions using logical operators (`&&`, `||`).
2. Extract the merged condition into a clearly named method.

**Resolves**: Duplicate Code (in conditional logic).

---

## Consolidate Duplicate Conditional Fragments

**When**: The same code exists in all branches of a conditional.

**Procedure**:
1. Move the identical code outside the conditional — before it (if at the
   start of every branch) or after it (if at the end).

---

## Remove Control Flag

**When**: A boolean variable acts as a control flag for a loop or conditional
chain.

**Procedure**:
1. Replace the flag with `break`, `continue`, or `return`.
2. Delete the flag variable.

**Resolves**: readability.

---

## Replace Nested Conditional with Guard Clauses

**When**: A method has deeply nested conditionals that obscure the normal flow.

**Procedure**:
1. Identify the special/edge cases.
2. Add early-return guard clauses for each special case.
3. The remaining code handles the main path with no nesting.

**Resolves**: Long Method, readability.

---

## Replace Conditional with Polymorphism

**When**: A conditional dispatches behavior based on object type or type code.

**Procedure**:
1. Create a subclass or strategy for each branch.
2. Move the branch logic into the corresponding subclass.
3. The caller invokes the method on the base type — dispatch happens via
   polymorphism.

**Resolves**: Switch Statements, Long Method.

---

## Introduce Null Object

**When**: Repeated null checks for the same object clutter the code.

**Procedure**:
1. Create a subclass or implementation that represents the "null" case with
   safe default behavior.
2. Replace null checks with the null object.

**Resolves**: Temporary Field, excessive null checks.

---

## Introduce Assertion

**When**: A section of code assumes a certain condition is true, but this
assumption is not explicit.

**Procedure**:
1. Add an assertion statement that verifies the assumption.
2. If the assertion fails in tests, the caller has a bug, not this method.

**Resolves**: hidden assumptions, defensive debugging.
