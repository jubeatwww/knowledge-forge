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

### Example (Java)

**Before:**
```java
public List<int[]> getThem() {
    List<int[]> list1 = new ArrayList<>();
    for (int[] x : theList)
        if (x[0] == 4) list1.add(x);
    return list1;
}
```

**After:**
```java
public List<Cell> getFlaggedCells() {
    List<Cell> flaggedCells = new ArrayList<>();
    for (Cell cell : gameBoard)
        if (cell.isFlagged()) flaggedCells.add(cell);
    return flaggedCells;
}
```

---

## Add Parameter

**When**: A method needs more information from its caller.

**Procedure**:
1. Add the parameter to the method signature.
2. Update all callers to supply the argument.

> Consider if **Introduce Parameter Object** or **Preserve Whole Object** is
> a better alternative.

### Example (Java)

**Before:**
```java
public Contact getContact(Customer customer) {
    return customer.getPrimaryContact();
}
```

**After:**
```java
public Contact getContact(Customer customer, Date date) {
    return customer.getContactAt(date);
}
```

---

## Remove Parameter

**When**: A parameter is no longer used by the method body.

**Procedure**:
1. Verify no branch uses the parameter.
2. Remove it from the signature.
3. Update all callers.

**Resolves**: Dead Code, Speculative Generality.

### Example (Java)

**Before:**
```java
public double getPrice(int quantity, String format) {
    return basePrice * quantity;
}
```

**After:**
```java
public double getPrice(int quantity) {
    return basePrice * quantity;
}
```

---

## Separate Query from Modifier

**When**: A method both returns a value and changes the object's state.

**Procedure**:
1. Create two methods: one that returns the value (query), one that performs
   the change (modifier).
2. Replace all calls with the appropriate method.

**Resolves**: side effects, testability.

### Example (Java)

**Before:**
```java
public String getAndRemoveNext() {
    String next = queue.peek();
    queue.poll();
    return next;
}
```

**After:**
```java
public String getNext() {
    return queue.peek();
}

public void removeNext() {
    queue.poll();
}
```

---

## Parameterize Method

**When**: Multiple methods do the same thing but with different hardcoded
values.

**Procedure**:
1. Create a single method with a parameter for the varying value.
2. Replace the specialized methods with calls to the parameterized method.

**Resolves**: Duplicate Code.

### Example (Java)

**Before:**
```java
public void tenPercentRaise() {
    salary *= 1.10;
}

public void fivePercentRaise() {
    salary *= 1.05;
}
```

**After:**
```java
public void raise(double factor) {
    salary *= (1 + factor);
}
```

---

## Replace Parameter with Explicit Methods

**When**: A method is dispatched via a parameter value (e.g., flag enum).

**Procedure**:
1. Create a separate method for each parameter value.
2. Replace calls that pass a constant with calls to the explicit method.

**Resolves**: Switch Statements (inside the method).

### Example (Java)

**Before:**
```java
public void setValue(String name, int value) {
    if (name.equals("height")) height = value;
    else if (name.equals("width")) width = value;
}
```

**After:**
```java
public void setHeight(int value) {
    height = value;
}

public void setWidth(int value) {
    width = value;
}
```

---

## Preserve Whole Object

**When**: You extract several values from an object and pass them as individual
parameters.

**Procedure**:
1. Replace the individual parameters with the whole object.
2. Have the method extract what it needs from the object.

**Resolves**: Long Parameter List, Data Clumps.

### Example (Java)

**Before:**
```java
public boolean isWithin(int low, int high) {
    return value >= low && value <= high;
}
// caller
plan.isWithin(range.getLow(), range.getHigh());
```

**After:**
```java
public boolean isWithin(Range range) {
    return value >= range.getLow() && value <= range.getHigh();
}
// caller
plan.isWithin(range);
```

---

## Replace Parameter with Method Call

**When**: A caller computes a value to pass as a parameter, but the method
could compute it itself.

**Procedure**:
1. Move the computation inside the method.
2. Remove the parameter.

**Resolves**: Long Parameter List.

### Example (Java)

**Before:**
```java
double basePrice = quantity * itemPrice;
double discount = getDiscount(basePrice);
// caller
double finalPrice = discountedPrice(basePrice, discount);
```

**After:**
```java
// callee computes discount itself
double discountedPrice() {
    double basePrice = quantity * itemPrice;
    double discount = getDiscount(basePrice);
    return basePrice - discount;
}
```

---

## Introduce Parameter Object

**When**: A group of parameters naturally belongs together and is repeated
across methods.

**Procedure**:
1. Create a class with fields for each parameter in the group.
2. Replace the parameter group with an instance of the new class.
3. Move related behavior into the new class over time.

**Resolves**: Long Parameter List, Data Clumps, Primitive Obsession.

### Example (Java)

**Before:**
```java
public List<Entry> getEntries(int startDate, int endDate) {
    return entries.stream()
        .filter(e -> e.getDate() >= startDate && e.getDate() <= endDate)
        .collect(Collectors.toList());
}
```

**After:**
```java
public List<Entry> getEntries(DateRange range) {
    return entries.stream()
        .filter(e -> range.contains(e.getDate()))
        .collect(Collectors.toList());
}
```

---

## Remove Setting Method

**When**: A field should be set only at creation time, but a setter exists.

**Procedure**:
1. Set the field value in the constructor.
2. Delete the setter method.

**Resolves**: Data Class, encapsulation.

### Example (Java)

**Before:**
```java
public class Account {
    private String id;
    public Account() {}
    public void setId(String id) { this.id = id; }
}
```

**After:**
```java
public class Account {
    private final String id;
    public Account(String id) { this.id = id; }
}
```

---

## Hide Method

**When**: A method is not used by any external class.

**Procedure**:
1. Make the method private (or the most restrictive visibility possible).

**Resolves**: unnecessary public surface area.

### Example (Java)

**Before:**
```java
public class Order {
    public double calculateDiscount() {
        return total > 100 ? total * 0.1 : 0;
    }
}
```

**After:**
```java
public class Order {
    private double calculateDiscount() {
        return total > 100 ? total * 0.1 : 0;
    }
}
```

---

## Replace Constructor with Factory Method

**When**: You need more than simple construction — e.g., returning a subclass
based on parameters.

**Procedure**:
1. Create a static factory method.
2. Move constructor logic into the factory method.
3. Make the constructor private.

### Example (Java)

**Before:**
```java
public class Employee {
    public Employee(int type) {
        this.type = type;
    }
}
// caller
Employee eng = new Employee(ENGINEER);
```

**After:**
```java
public class Employee {
    private Employee(int type) { this.type = type; }
    public static Employee createEngineer() {
        return new Employee(ENGINEER);
    }
}
// caller
Employee eng = Employee.createEngineer();
```

---

## Replace Error Code with Exception

**When**: A method returns a special value (e.g., `-1`, `null`) to indicate an
error.

**Procedure**:
1. Throw an exception for the error case.
2. Update callers to catch the exception.

### Example (Java)

**Before:**
```java
public int withdraw(int amount) {
    if (amount > balance) return -1;
    balance -= amount;
    return 0;
}
```

**After:**
```java
public void withdraw(int amount) {
    if (amount > balance)
        throw new InsufficientFundsException(amount, balance);
    balance -= amount;
}
```

---

## Replace Exception with Test

**When**: An exception is thrown for a condition that could be checked
beforehand.

**Procedure**:
1. Add a conditional check before the call.
2. Move the exception handler's logic into the else branch or remove it.

**Resolves**: performance, clarity.

### Example (Java)

**Before:**
```java
try {
    value = stack.pop();
} catch (EmptyStackException e) {
    value = defaultValue;
}
```

**After:**
```java
if (!stack.isEmpty()) {
    value = stack.pop();
} else {
    value = defaultValue;
}
```
