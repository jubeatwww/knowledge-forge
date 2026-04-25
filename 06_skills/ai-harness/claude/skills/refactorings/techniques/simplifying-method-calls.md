# Simplifying Method Calls

Clean up method interfaces to make them easier to understand, use, and
maintain. Poor method signatures propagate confusion to all callers.

Reference: https://refactoring.guru/refactoring/techniques/simplifying-method-calls

---

## Rename Method

**When**: A method name does not reveal its purpose.

**Procedure**:
1. Choose a name that describes what the method does.
2. Rename the method and update all callers.

---

## Add Parameter

**When**: A method needs more information from its caller.

**Procedure**:
1. Add the parameter to the method signature.
2. Update all callers to supply the argument.

> Consider if **Introduce Parameter Object** or **Preserve Whole Object** is
> a better alternative.

---

## Remove Parameter

**When**: A parameter is no longer used by the method body.

**Procedure**:
1. Verify no branch uses the parameter.
2. Remove it from the signature.
3. Update all callers.

**Resolves**: Dead Code, Speculative Generality.

---

## Separate Query from Modifier

**When**: A method both returns a value and changes the object's state.

**Procedure**:
1. Create two methods: one that returns the value (query), one that performs
   the change (modifier).
2. Replace all calls with the appropriate method.

**Resolves**: side effects, testability.

---

## Parameterize Method

**When**: Multiple methods do the same thing but with different hardcoded
values.

**Procedure**:
1. Create a single method with a parameter for the varying value.
2. Replace the specialized methods with calls to the parameterized method.

**Resolves**: Duplicate Code.

---

## Replace Parameter with Explicit Methods

**When**: A method is dispatched via a parameter value (e.g., flag enum).

**Procedure**:
1. Create a separate method for each parameter value.
2. Replace calls that pass a constant with calls to the explicit method.

**Resolves**: Switch Statements (inside the method).

---

## Preserve Whole Object

**When**: You extract several values from an object and pass them as individual
parameters.

**Procedure**:
1. Replace the individual parameters with the whole object.
2. Have the method extract what it needs from the object.

**Resolves**: Long Parameter List, Data Clumps.

---

## Replace Parameter with Method Call

**When**: A caller computes a value to pass as a parameter, but the method
could compute it itself.

**Procedure**:
1. Move the computation inside the method.
2. Remove the parameter.

**Resolves**: Long Parameter List.

---

## Introduce Parameter Object

**When**: A group of parameters naturally belongs together and is repeated
across methods.

**Procedure**:
1. Create a class with fields for each parameter in the group.
2. Replace the parameter group with an instance of the new class.
3. Move related behavior into the new class over time.

**Resolves**: Long Parameter List, Data Clumps, Primitive Obsession.

---

## Remove Setting Method

**When**: A field should be set only at creation time, but a setter exists.

**Procedure**:
1. Set the field value in the constructor.
2. Delete the setter method.

**Resolves**: Data Class, encapsulation.

---

## Hide Method

**When**: A method is not used by any external class.

**Procedure**:
1. Make the method private (or the most restrictive visibility possible).

**Resolves**: unnecessary public surface area.

---

## Replace Constructor with Factory Method

**When**: You need more than simple construction — e.g., returning a subclass
based on parameters.

**Procedure**:
1. Create a static factory method.
2. Move constructor logic into the factory method.
3. Make the constructor private.

---

## Replace Error Code with Exception

**When**: A method returns a special value (e.g., `-1`, `null`) to indicate an
error.

**Procedure**:
1. Throw an exception for the error case.
2. Update callers to catch the exception.

---

## Replace Exception with Test

**When**: An exception is thrown for a condition that could be checked
beforehand.

**Procedure**:
1. Add a conditional check before the call.
2. Move the exception handler's logic into the else branch or remove it.

**Resolves**: performance, clarity.
