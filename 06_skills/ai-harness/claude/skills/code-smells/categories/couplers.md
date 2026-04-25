# Couplers

All the smells in this group contribute to excessive coupling between classes
or show what happens when coupling is replaced by excessive delegation.

---

## Feature Envy

A method that accesses data from another object more than from its own object.

### Detection Criteria

- A method calls getters/fields of another object 3+ times while using few or
  none of its own.
- The method would make more sense living in the other class.
- Moving the method would reduce the number of cross-object calls.
- After extraction, the extracted method clearly belongs elsewhere.

### Why It's a Problem

- The method is in the wrong place — behavior is separated from data.
- Changes to the envied class's structure force changes to the envious method.
- Violates "tell, don't ask."

### Recommended Refactorings

- **Move Method** — relocate the method to the class it uses most.
- **Extract Method** — if only part of the method envies another class, extract
  that part first, then move it.

---

## Inappropriate Intimacy

Two classes are excessively tangled — one uses the internal fields and methods
of the other.

### Detection Criteria

- Class A accesses private/protected members of Class B (via friend, reflection,
  or package-private access).
- Two classes have bidirectional references and mutual method calls.
- Changes to one class frequently require changes to the other.
- Extracting one class into a separate module would require pulling the other
  along.

### Why It's a Problem

- The two classes are effectively one unit — changes couple tightly.
- Hard to understand or reuse either class independently.
- Increases the blast radius of modifications.

### Recommended Refactorings

- **Move Method** / **Move Field** — put pieces in the right class.
- **Extract Class** — create a new class for the shared responsibility.
- **Hide Delegate** — reduce what one class exposes to the other.
- **Replace Inheritance with Delegation** — when intimacy comes from a
  parent-child relationship that should be composition.

---

## Message Chains

A client asks object A for object B, then asks B for object C, then asks C for
object D — a chain of `getX().getY().getZ()` calls.

### Detection Criteria

- Call chains like `a.getB().getC().getD().doSomething()`.
- Navigation depth of 3+ objects.
- Client must know the entire object graph to reach a value.
- Intermediate objects exist only to be traversed.

### Why It's a Problem

- Client is coupled to the full navigation path.
- Any change to the intermediate structure breaks the chain.
- Violates the Law of Demeter ("only talk to your friends").

### Recommended Refactorings

- **Hide Delegate** — let the first object provide the needed result directly.
- **Extract Method** / **Move Method** — push the query into the class that
  owns the data.

---

## Middle Man

A class that delegates most of its work to another class, adding no value of
its own.

### Detection Criteria

- Most methods in the class simply forward calls to another object.
- The class adds no logic, validation, or transformation.
- Removing the class and calling the delegate directly would simplify the code.
- The class was introduced for "future flexibility" that never materialized.

### Why It's a Problem

- Extra indirection with no benefit.
- Readers must trace through the middle man to find the real logic.
- Increases the number of classes to maintain.

### Recommended Refactorings

- **Remove Middle Man** — let clients call the delegate directly.
- **Inline Method** — when only a few delegating methods remain.
- If the middle man adds some value, keep it but eliminate the pure pass-through
  methods.

---

## Incomplete Library Class

A library class doesn't provide a method you need, and you can't modify the
library source.

### Detection Criteria

- You write utility methods that wrap library classes.
- Multiple places in the codebase work around the same library limitation.
- You subclass a library class solely to add a missing method.

### Why It's a Problem

- Workaround code duplicates across the codebase.
- The workaround may break when the library updates.
- Domain intent is obscured by low-level library adaptation.

### Recommended Refactorings

- **Introduce Foreign Method** — add the missing method as a utility that takes
  the library object as a parameter.
- **Introduce Local Extension** — create a subclass or wrapper that adds the
  needed methods.
