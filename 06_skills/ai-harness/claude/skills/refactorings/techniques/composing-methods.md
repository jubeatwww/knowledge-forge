# Composing Methods

Streamline methods, remove code duplication, and pave the way for future
improvements. Excessively long methods are the root of many code smells.

Reference: https://refactoring.guru/refactoring/techniques/composing-methods

---

## Extract Method

**When**: A code fragment can be grouped together and named.

**Procedure**:
1. Create a new method named after its purpose (`createOrder`, `renderDetails`).
2. Move the fragment into the new method.
3. Variables declared inside the fragment become local to the new method.
4. Variables declared before the fragment become parameters.
5. If a local variable is modified and needed later, return it from the method.

**Resolves**: Long Method, Duplicate Code, Comments.

---

## Inline Method

**When**: A method body is as clear as the method name, or the method is a
trivial delegation.

**Procedure**:
1. Verify the method is not overridden in subclasses.
2. Replace all calls with the method body.
3. Delete the method.

**Resolves**: Speculative Generality, Middle Man.

---

## Extract Variable

**When**: A complex expression is hard to understand.

**Procedure**:
1. Declare a new variable with a descriptive name.
2. Assign the expression (or its sub-expression) to the variable.
3. Replace the expression with the variable reference.

**Resolves**: Comments, readability.

---

## Inline Temp

**When**: A temporary variable is assigned once and used once, adding no
clarity.

**Procedure**:
1. Verify the variable is assigned exactly once.
2. Replace all reads with the right-hand-side expression.
3. Delete the variable declaration.

**Resolves**: intermediate step for other refactorings.

---

## Replace Temp with Query

**When**: A temporary variable holds the result of an expression that could be
a method.

**Procedure**:
1. Extract the expression into a new method (query).
2. Replace the temp variable with a call to the query method.
3. The new method can now be reused by other methods.

**Resolves**: Long Method (enables further extraction).

---

## Split Temporary Variable

**When**: A temporary variable is assigned more than once (not a loop counter
or accumulator) for different purposes.

**Procedure**:
1. Rename the first assignment's variable to reflect its purpose.
2. Create a new variable for the second assignment.
3. Repeat for each subsequent reuse.

**Resolves**: readability, makes Extract Method easier.

---

## Remove Assignments to Parameters

**When**: A method assigns a new value to a parameter.

**Procedure**:
1. Create a local variable and assign the parameter's value to it.
2. Replace all subsequent references to the parameter with the local variable.

**Resolves**: confusing side effects, enables clearer parameter contracts.

---

## Replace Method with Method Object

**When**: A long method has so many local variables that Extract Method is
impossible.

**Procedure**:
1. Create a new class named after the method.
2. Add a field for every local variable and parameter.
3. Create a constructor that accepts the original object and all parameters.
4. Move the method body into a `compute()` or `execute()` method.
5. In the original class, replace the method body with a call to the new class.

**Resolves**: Long Method when other techniques fail.

---

## Substitute Algorithm

**When**: You want to replace an algorithm with a clearer or more efficient
one.

**Procedure**:
1. Write the new algorithm.
2. Run all tests with the new algorithm.
3. Compare results of old and new on edge cases.
4. Replace the old algorithm with the new one.

**Resolves**: Duplicate Code, Long Method, performance.
