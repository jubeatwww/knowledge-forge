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

### Example (Java)

**Before:**
```java
class Salesman extends Employee { private String name; }
class Engineer extends Employee { private String name; }
```

**After:**
```java
class Employee { protected String name; }
class Salesman extends Employee {}
class Engineer extends Employee {}
```

---

## Pull Up Method

**When**: Two or more subclasses have methods with identical results.

**Procedure**:
1. Verify the methods have the same signature and behavior.
2. Move the method to the parent class.
3. Remove the duplicate methods from the subclasses.

**Resolves**: Duplicate Code.

### Example (Java)

**Before:**
```java
class Salesman extends Employee {
    double getAnnualCost() { return monthlySalary * 12; }
}
class Engineer extends Employee {
    double getAnnualCost() { return monthlySalary * 12; }
}
```

**After:**
```java
class Employee {
    double getAnnualCost() { return monthlySalary * 12; }
}
class Salesman extends Employee {}
class Engineer extends Employee {}
```

---

## Pull Up Constructor Body

**When**: Subclass constructors have nearly identical code.

**Procedure**:
1. Move the common constructor code to the parent constructor.
2. Call the parent constructor from each subclass constructor.

**Resolves**: Duplicate Code.

### Example (Java)

**Before:**
```java
class Manager extends Employee {
    Manager(String name, String id, int grade) {
        this.name = name;
        this.id = id;
        this.grade = grade;
    }
}
```

**After:**
```java
class Manager extends Employee {
    Manager(String name, String id, int grade) {
        super(name, id);
        this.grade = grade;
    }
}
```

---

## Push Down Method

**When**: A method in the parent class is used by only one subclass.

**Procedure**:
1. Move the method to the subclass that uses it.
2. Remove it from the parent class.

**Resolves**: Refused Bequest.

### Example (Java)

**Before:**
```java
class Employee {
    double getQuota() { /* only relevant to Salesman */ }
}
class Engineer extends Employee {}
class Salesman extends Employee {}
```

**After:**
```java
class Employee {}
class Engineer extends Employee {}
class Salesman extends Employee {
    double getQuota() { /* moved here */ }
}
```

---

## Push Down Field

**When**: A field in the parent class is used by only one subclass.

**Procedure**:
1. Move the field to the subclass that uses it.
2. Remove it from the parent class.

**Resolves**: Refused Bequest.

### Example (Java)

**Before:**
```java
class Employee {
    protected double quota; // only Salesman uses this
}
class Salesman extends Employee {}
```

**After:**
```java
class Employee {}
class Salesman extends Employee {
    private double quota;
}
```

---

## Extract Subclass

**When**: A class has features that are used only in some instances.

**Procedure**:
1. Create a subclass.
2. Move the conditionally-used fields and methods to the subclass.
3. Replace conditionals that check for the variant with polymorphism.

**Resolves**: Large Class, Switch Statements.

### Example (Java)

**Before:**
```java
class Job {
    private double unitPrice;
    private double totalCut; // only used for labor jobs
    boolean isLabor() { return totalCut > 0; }
}
```

**After:**
```java
class Job {
    private double unitPrice;
}
class LaborJob extends Job {
    private double totalCut;
}
```

---

## Extract Superclass

**When**: Two classes have similar features — shared fields and methods.

**Procedure**:
1. Create a new superclass.
2. Move common fields and methods up.
3. Have both classes inherit from the new superclass.

**Resolves**: Duplicate Code, Alternative Classes with Different Interfaces.

### Example (Java)

**Before:**
```java
class Department { String getName() {...} int getHeadCount() {...} }
class Project   { String getName() {...} int getHeadCount() {...} }
```

**After:**
```java
class Party { String getName() {...} int getHeadCount() {...} }
class Department extends Party {}
class Project extends Party {}
```

---

## Extract Interface

**When**: Multiple clients use the same subset of a class's interface, or two
classes share part of their interface.

**Procedure**:
1. Declare an interface with the shared methods.
2. Have the class(es) implement the interface.
3. Change client code to use the interface type.

**Resolves**: Alternative Classes with Different Interfaces, Refused Bequest.

### Example (Java)

**Before:**
```java
class EmailSender { void send(String to, String body) {...} }
class SmsSender   { void send(String to, String body) {...} }
```

**After:**
```java
interface MessageSender { void send(String to, String body); }
class EmailSender implements MessageSender { ... }
class SmsSender implements MessageSender { ... }
```

---

## Collapse Hierarchy

**When**: A subclass is nearly identical to its parent.

**Procedure**:
1. Merge the subclass into the parent (or vice versa).
2. Remove the empty class.

**Resolves**: Lazy Class, Speculative Generality.

### Example (Java)

**Before:**
```java
class Employee { String getName() {...} }
class Salesman extends Employee {
    // adds nothing beyond Employee
}
```

**After:**
```java
class Employee {
    String getName() {...}
}
// Salesman removed — all references now use Employee
```

---

## Form Template Method

**When**: Subclasses have methods with similar structure but different details.

**Procedure**:
1. Break each method into steps — some identical, some varying.
2. Pull the identical steps into the parent as a template method.
3. Make the varying steps into abstract methods overridden by each subclass.

**Resolves**: Duplicate Code.

### Example (Java)

**Before:**
```java
class CsvReport extends Report {
    void generate() { prepare(); writeCsv(); cleanup(); }
}
class HtmlReport extends Report {
    void generate() { prepare(); writeHtml(); cleanup(); }
}
```

**After:**
```java
abstract class Report {
    final void generate() { prepare(); writeBody(); cleanup(); }
    abstract void writeBody();
}
class CsvReport extends Report  { void writeBody() { writeCsv(); } }
class HtmlReport extends Report { void writeBody() { writeHtml(); } }
```

---

**When**: A subclass uses only a fraction of the parent's interface, or the
"is-a" relationship is semantically wrong.

**Procedure**:
1. Create a field in the subclass for the parent class.
2. Delegate needed methods to the field.
3. Remove the inheritance relationship.

**Resolves**: Refused Bequest, Inappropriate Intimacy.

### Example (Java)

**Before:**
```java
class MyStack extends ArrayList<Object> {
    public void push(Object o) { add(o); }
    public Object pop() { return remove(size() - 1); }
}
```

**After:**
```java
class MyStack {
    private final ArrayList<Object> list = new ArrayList<>();
    public void push(Object o) { list.add(o); }
    public Object pop() { return list.remove(list.size() - 1); }
}
```

---

## Replace Delegation with Inheritance

**When**: A class delegates everything to another class and the "is-a"
relationship makes sense.

**Procedure**:
1. Make the delegating class inherit from the delegate.
2. Remove the delegation field and forwarding methods.

> Use sparingly — only when the "is-a" relationship is semantically correct.

### Example (Java)

**Before:**
```java
class Engine { void start() {...} void stop() {...} }
class Car {
    private Engine engine;
    void start() { engine.start(); }
    void stop()  { engine.stop(); }
}
```

**After:**
```java
class Engine { void start() {...} void stop() {...} }
class Car extends Engine {
    // inherits start() and stop() directly
}
```
