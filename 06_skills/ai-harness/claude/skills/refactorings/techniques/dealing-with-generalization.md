# Dealing with Generalization

Manage inheritance hierarchies — pulling behavior up, pushing it down, or
replacing inheritance with delegation when the hierarchy does more harm than
good.

Reference: https://refactoring.guru/refactoring/techniques/dealing-with-generalization

---

## Pull Up Field

**When**: Two or more subclasses have the same field.

**Procedure**:
1. Move the field to the parent class.
2. Remove the duplicate fields from the subclasses.

**Resolves**: Duplicate Code.

---

## Pull Up Method

**When**: Two or more subclasses have methods with identical results.

**Procedure**:
1. Verify the methods have the same signature and behavior.
2. Move the method to the parent class.
3. Remove the duplicate methods from the subclasses.

**Resolves**: Duplicate Code.

---

## Pull Up Constructor Body

**When**: Subclass constructors have nearly identical code.

**Procedure**:
1. Move the common constructor code to the parent constructor.
2. Call the parent constructor from each subclass constructor.

**Resolves**: Duplicate Code.

---

## Push Down Method

**When**: A method in the parent class is used by only one subclass.

**Procedure**:
1. Move the method to the subclass that uses it.
2. Remove it from the parent class.

**Resolves**: Refused Bequest.

---

## Push Down Field

**When**: A field in the parent class is used by only one subclass.

**Procedure**:
1. Move the field to the subclass that uses it.
2. Remove it from the parent class.

**Resolves**: Refused Bequest.

---

## Extract Subclass

**When**: A class has features that are used only in some instances.

**Procedure**:
1. Create a subclass.
2. Move the conditionally-used fields and methods to the subclass.
3. Replace conditionals that check for the variant with polymorphism.

**Resolves**: Large Class, Switch Statements.

---

## Extract Superclass

**When**: Two classes have similar features — shared fields and methods.

**Procedure**:
1. Create a new superclass.
2. Move common fields and methods up.
3. Have both classes inherit from the new superclass.

**Resolves**: Duplicate Code, Alternative Classes with Different Interfaces.

---

## Extract Interface

**When**: Multiple clients use the same subset of a class's interface, or two
classes share part of their interface.

**Procedure**:
1. Declare an interface with the shared methods.
2. Have the class(es) implement the interface.
3. Change client code to use the interface type.

**Resolves**: Alternative Classes with Different Interfaces, Refused Bequest.

---

## Collapse Hierarchy

**When**: A subclass is nearly identical to its parent.

**Procedure**:
1. Merge the subclass into the parent (or vice versa).
2. Remove the empty class.

**Resolves**: Lazy Class, Speculative Generality.

---

## Form Template Method

**When**: Subclasses have methods with similar structure but different details.

**Procedure**:
1. Break each method into steps — some identical, some varying.
2. Pull the identical steps into the parent as a template method.
3. Make the varying steps into abstract methods overridden by each subclass.

**Resolves**: Duplicate Code.

---

## Replace Inheritance with Delegation

**When**: A subclass uses only a fraction of the parent's interface, or the
"is-a" relationship is semantically wrong.

**Procedure**:
1. Create a field in the subclass for the parent class.
2. Delegate needed methods to the field.
3. Remove the inheritance relationship.

**Resolves**: Refused Bequest, Inappropriate Intimacy.

---

## Replace Delegation with Inheritance

**When**: A class delegates everything to another class and the "is-a"
relationship makes sense.

**Procedure**:
1. Make the delegating class inherit from the delegate.
2. Remove the delegation field and forwarding methods.

> Use sparingly — only when the "is-a" relationship is semantically correct.
