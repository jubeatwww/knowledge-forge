# Moving Features between Objects

Redistribute functionality among classes. When responsibilities are misplaced,
these techniques move them to where they belong.

Reference: https://refactoring.guru/refactoring/techniques/moving-features-between-objects

---

## Move Method

**When**: A method uses or is used by features of another class more than its
own.

**Procedure**:
1. Copy the method to the class it uses most.
2. Adjust the method to work in its new home.
3. Turn the original method into a delegate or delete it.

**Resolves**: Feature Envy, Shotgun Surgery, Inappropriate Intimacy.

---

## Move Field

**When**: A field is used by another class more than the class that defines it.

**Procedure**:
1. Create the field in the target class.
2. Update all readers/writers to reference the new location.
3. Remove the field from the original class.

**Resolves**: Feature Envy, Shotgun Surgery.

---

## Extract Class

**When**: A class does the work that should be done by two.

**Procedure**:
1. Decide which fields and methods belong together.
2. Create a new class with those fields and methods.
3. Set up a link from the old class to the new one.
4. Move fields and methods one at a time, testing after each move.

**Resolves**: Large Class, Divergent Change, Data Clumps, Inappropriate
Intimacy.

---

## Inline Class

**When**: A class does almost nothing and has no reason to exist.

**Procedure**:
1. Move all fields and methods from the class into another class.
2. Update all clients.
3. Delete the empty class.

**Resolves**: Lazy Class, Shotgun Surgery.

---

## Hide Delegate

**When**: A client calls a method on an object returned by another object
(message chain).

**Procedure**:
1. For each delegate method the client uses, create a delegating method on the
   server.
2. Change the client to call the server's methods.
3. If no client needs the delegate, remove the accessor.

**Resolves**: Message Chains, Inappropriate Intimacy.

---

## Remove Middle Man

**When**: A class has too many delegating methods that just forward calls.

**Procedure**:
1. Create an accessor for the delegate.
2. Replace client calls to delegating methods with direct calls via the
   accessor.
3. Delete the delegating methods.

**Resolves**: Middle Man.

---

## Introduce Foreign Method

**When**: A library class lacks a method you need, and you can't modify the
library.

**Procedure**:
1. Create a utility method in the client class.
2. Pass the library object as the first parameter.
3. Document that this is a foreign method that ideally belongs in the library.

**Resolves**: Incomplete Library Class.

---

## Introduce Local Extension

**When**: A library class needs several additional methods.

**Procedure**:
1. Create a new class — either a subclass or a wrapper of the library class.
2. Add the needed methods.
3. Replace usage of the library class with the extension.

**Resolves**: Incomplete Library Class.
