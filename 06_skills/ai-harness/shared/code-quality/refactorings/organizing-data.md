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

### Example (Java)

**Before:**

```java
class Range {
    int low, high;

    boolean includes(int val) {
        return val >= low && val <= high;
    }
}
```

**After:**

```java
class Range {
    private int low, high;

    int getLow() { return low; }
    int getHigh() { return high; }

    boolean includes(int val) {
        return val >= getLow() && val <= getHigh();
    }
}
```

---

## Replace Data Value with Object

**When**: A data field needs associated behavior (formatting, validation).

**Procedure**:
1. Create a new class with the field and its behavior.
2. Replace the field with an instance of the new class.
3. Move related behavior from client code into the new class.

**Resolves**: Primitive Obsession.

### Example (Java)

**Before:**

```java
class Order {
    private String customerPhone;

    String getFormattedPhone() {
        return "(" + customerPhone.substring(0, 3) + ") "
             + customerPhone.substring(3);
    }
}
```

**After:**

```java
class PhoneNumber {
    private final String number;
    PhoneNumber(String number) { this.number = number; }

    String formatted() {
        return "(" + number.substring(0, 3) + ") " + number.substring(3);
    }
}

class Order {
    private PhoneNumber customerPhone;
    String getFormattedPhone() { return customerPhone.formatted(); }
}
```

---

## Change Value to Reference

**When**: Many equal instances of a class should be a single shared instance.

**Procedure**:
1. Use a factory method or registry to return the canonical instance.
2. Replace constructor calls with the factory/registry lookup.

### Example (Java)

**Before:**

```java
// Each order creates its own Customer — duplicates for same name
class Order {
    private Customer customer;
    Order(String customerName) {
        this.customer = new Customer(customerName);
    }
}
```

**After:**

```java
class Customer {
    private static final Map<String, Customer> registry = new HashMap<>();

    static Customer of(String name) {
        return registry.computeIfAbsent(name, Customer::new);
    }
}

class Order {
    private Customer customer;
    Order(String customerName) {
        this.customer = Customer.of(customerName);
    }
}
```

---

## Change Reference to Value

**When**: A reference object is small, immutable, and awkward to manage.

**Procedure**:
1. Make the object immutable (remove setters).
2. Implement value-based equality.
3. Replace identity comparison with equality comparison.

### Example (Java)

**Before:**

```java
class Money {
    private int amount;
    private String currency;

    void setAmount(int amount) { this.amount = amount; }
}
// compared by identity: money1 == money2
```

**After:**

```java
class Money {
    private final int amount;
    private final String currency;

    Money(int amount, String currency) {
        this.amount = amount;
        this.currency = currency;
    }

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof Money m)) return false;
        return amount == m.amount && currency.equals(m.currency);
    }

    @Override
    public int hashCode() { return Objects.hash(amount, currency); }
}
```

---

## Replace Array with Object

**When**: An array contains elements of different meaning (e.g.,
`row[0] = name`, `row[1] = age`).

**Procedure**:
1. Create a class with a named field for each element.
2. Replace array reads/writes with field access.
3. Delete the array.

**Resolves**: Primitive Obsession.

### Example (Java)

**Before:**

```java
String[] row = new String[3];
row[0] = "Alice";
row[1] = "30";
row[2] = "Engineer";
System.out.println(row[0] + " is " + row[1]);
```

**After:**

```java
class Person {
    private final String name;
    private final int age;
    private final String role;

    Person(String name, int age, String role) {
        this.name = name;
        this.age = age;
        this.role = role;
    }
}
Person p = new Person("Alice", 30, "Engineer");
System.out.println(p.getName() + " is " + p.getAge());
```

---

## Duplicate Observed Data

**When**: Domain data is stored in a GUI component and is needed by domain
logic.

**Procedure**:
1. Create a domain class for the data.
2. Use an observer pattern to sync the GUI with the domain object.

**Resolves**: Large Class (UI + logic).

### Example (Java)

**Before:**

```java
class OrderDialog extends JFrame {
    private JTextField priceField;

    double getPrice() {
        return Double.parseDouble(priceField.getText());
    }

    void updateTotal() {
        double total = getPrice() * getQuantity();
        totalLabel.setText(String.valueOf(total));
    }
}
```

**After:**

```java
class OrderModel extends Observable {
    private double price;

    double getPrice() { return price; }

    void setPrice(double price) {
        this.price = price;
        setChanged(); notifyObservers();
    }
}

class OrderDialog extends JFrame implements Observer {
    private OrderModel model;

    @Override
    public void update(Observable o, Object arg) {
        totalLabel.setText(String.valueOf(model.getPrice() * getQuantity()));
    }
}
```

---

## Replace Magic Number with Symbolic Constant

**When**: Code contains numeric or string literals with special meaning.

**Procedure**:
1. Declare a constant with a descriptive name.
2. Replace all occurrences of the literal with the constant.

### Example (Java)

**Before:**

```java
double potentialEnergy(double mass, double height) {
    return mass * 9.81 * height;
}
```

**After:**

```java
static final double GRAVITATIONAL_ACCELERATION = 9.81;

double potentialEnergy(double mass, double height) {
    return mass * GRAVITATIONAL_ACCELERATION * height;
}
```

---

## Encapsulate Field

**When**: A class has a public field.

**Procedure**:
1. Make the field private.
2. Create a getter (and setter if needed).

**Resolves**: Data Class.

### Example (Java)

**Before:**

```java
class Person {
    public String name;
}
// usage: person.name = "Alice";
```

**After:**

```java
class Person {
    private String name;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
}
// usage: person.setName("Alice");
```

---

## Encapsulate Collection

**When**: A class exposes a collection directly via a getter.

**Procedure**:
1. Have the getter return a read-only view or copy.
2. Add methods to add/remove elements.
3. Remove the setter or have it copy the incoming collection.

**Resolves**: Data Class.

### Example (Java)

**Before:**

```java
class Course {
    private List<Student> students = new ArrayList<>();

    public List<Student> getStudents() { return students; }
    public void setStudents(List<Student> s) { students = s; }
}
// caller can mutate: course.getStudents().clear();
```

**After:**

```java
class Course {
    private final List<Student> students = new ArrayList<>();

    public List<Student> getStudents() {
        return Collections.unmodifiableList(students);
    }
    public void addStudent(Student s) { students.add(s); }
    public void removeStudent(Student s) { students.remove(s); }
}
```

---

## Replace Type Code with Class

**When**: A type code (int/string constant) doesn't affect behavior.

**Procedure**:
1. Create a new class with instances for each code value.
2. Replace the type code field with the new class type.

**Resolves**: Primitive Obsession.

### Example (Java)

**Before:**

```java
class Person {
    static final int O = 0, A = 1, B = 2, AB = 3;
    private int bloodType;

    Person(int bloodType) { this.bloodType = bloodType; }
}
Person p = new Person(Person.A);
```

**After:**

```java
enum BloodType { O, A, B, AB }

class Person {
    private BloodType bloodType;

    Person(BloodType bloodType) { this.bloodType = bloodType; }
    BloodType getBloodType() { return bloodType; }
}
Person p = new Person(BloodType.A);
```

---

## Replace Type Code with Subclasses

**When**: A type code affects class behavior (controls conditionals).

**Procedure**:
1. Create a subclass for each type code value.
2. Move code-specific behavior to the appropriate subclass.
3. Remove the type code field.

**Resolves**: Primitive Obsession, Switch Statements.

### Example (Java)

**Before:**

```java
class Employee {
    static final int ENGINEER = 0, MANAGER = 1;
    private int type;

    double bonus(double salary) {
        return (type == ENGINEER) ? salary * 0.1 : salary * 0.3;
    }
}
```

**After:**

```java
abstract class Employee {
    abstract double bonus(double salary);
}

class Engineer extends Employee {
    double bonus(double salary) { return salary * 0.1; }
}

class Manager extends Employee {
    double bonus(double salary) { return salary * 0.3; }
}
```

---

## Replace Type Code with State/Strategy

**When**: A type code affects behavior and changes at runtime.

**Procedure**:
1. Create a state/strategy class with subclasses for each code value.
2. The host class delegates to the state/strategy object.
3. Changing the type replaces the state/strategy instance.

**Resolves**: Primitive Obsession, Switch Statements.

### Example (Java)

**Before:**

```java
class Employee {
    private int type; // can change at runtime

    void setType(int type) { this.type = type; }

    double bonus(double salary) {
        return switch (type) {
            case 0 -> salary * 0.1;
            case 1 -> salary * 0.3;
            default -> 0;
        };
    }
}
```

**After:**

```java
interface EmployeeType {
    double bonus(double salary);
}
class EngineerType implements EmployeeType {
    public double bonus(double salary) { return salary * 0.1; }
}
class ManagerType implements EmployeeType {
    public double bonus(double salary) { return salary * 0.3; }
}

class Employee {
    private EmployeeType type;
    void setType(EmployeeType type) { this.type = type; }
    double bonus(double salary) { return type.bonus(salary); }
}
```

---

## Replace Subclass with Fields

**When**: Subclasses differ only in constant-returning methods.

**Procedure**:
1. Replace the methods with fields in the parent class.
2. Set the field values in the constructor.
3. Remove the subclasses.

**Resolves**: Speculative Generality, unnecessary hierarchy.

### Example (Java)

**Before:**

```java
abstract class Person {
    abstract String getCode();
    abstract String getLabel();
}
class Male extends Person {
    String getCode() { return "M"; }
    String getLabel() { return "Male"; }
}
class Female extends Person {
    String getCode() { return "F"; }
    String getLabel() { return "Female"; }
}
```

**After:**

```java
class Person {
    private final String code;
    private final String label;

    Person(String code, String label) {
        this.code = code;
        this.label = label;
    }

    static Person male() { return new Person("M", "Male"); }
    static Person female() { return new Person("F", "Female"); }

    String getCode() { return code; }
    String getLabel() { return label; }
}
