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

### Example (Java)

**Before:**

```java
double charge(Date date, int qty) {
    if (date.before(SUMMER_START) || date.after(SUMMER_END)) {
        return qty * winterRate + winterServiceCharge;
    } else {
        return qty * summerRate;
    }
}
```

**After:**

```java
double charge(Date date, int qty) {
    if (isWinter(date)) {
        return winterCharge(qty);
    } else {
        return summerCharge(qty);
    }
}

boolean isWinter(Date d) { return d.before(SUMMER_START) || d.after(SUMMER_END); }
double winterCharge(int qty) { return qty * winterRate + winterServiceCharge; }
double summerCharge(int qty) { return qty * summerRate; }
```

---

## Consolidate Conditional Expression

**When**: Multiple conditionals lead to the same result.

**Procedure**:
1. Merge the conditions using logical operators (`&&`, `||`).
2. Extract the merged condition into a clearly named method.

**Resolves**: Duplicate Code (in conditional logic).

### Example (Java)

**Before:**

```java
double disabilityAmount() {
    if (seniority < 2) return 0;
    if (monthsDisabled > 12) return 0;
    if (isPartTime) return 0;
    // compute disability
    return basePay * 0.6;
}
```

**After:**

```java
double disabilityAmount() {
    if (isIneligibleForDisability()) return 0;
    return basePay * 0.6;
}

boolean isIneligibleForDisability() {
    return seniority < 2 || monthsDisabled > 12 || isPartTime;
}
```

---

## Consolidate Duplicate Conditional Fragments

**When**: The same code exists in all branches of a conditional.

**Procedure**:
1. Move the identical code outside the conditional — before it (if at the
   start of every branch) or after it (if at the end).

### Example (Java)

**Before:**

```java
if (isSpecialDeal()) {
    total = price * 0.9;
    sendNotification();
} else {
    total = price;
    sendNotification();
}
```

**After:**

```java
if (isSpecialDeal()) {
    total = price * 0.9;
} else {
    total = price;
}
sendNotification();
```

---

## Remove Control Flag

**When**: A boolean variable acts as a control flag for a loop or conditional
chain.

**Procedure**:
1. Replace the flag with `break`, `continue`, or `return`.
2. Delete the flag variable.

**Resolves**: readability.

### Example (Java)

**Before:**

```java
boolean found = false;
for (Person p : people) {
    if (!found) {
        if (p.getName().equals(target)) {
            sendAlert(p);
            found = true;
        }
    }
}
```

**After:**

```java
for (Person p : people) {
    if (p.getName().equals(target)) {
        sendAlert(p);
        break;
    }
}
```

---

## Replace Nested Conditional with Guard Clauses

**When**: A method has deeply nested conditionals that obscure the normal flow.

**Procedure**:
1. Identify the special/edge cases.
2. Add early-return guard clauses for each special case.
3. The remaining code handles the main path with no nesting.

**Resolves**: Long Method, readability.

### Example (Java)

**Before:**

```java
double payAmount() {
    double result;
    if (isDead) {
        result = deadAmount();
    } else {
        if (isSeparated) {
            result = separatedAmount();
        } else {
            result = normalPay();
        }
    }
    return result;
}
```

**After:**

```java
double payAmount() {
    if (isDead) return deadAmount();
    if (isSeparated) return separatedAmount();
    return normalPay();
}
```

---

## Replace Conditional with Polymorphism

**When**: A conditional dispatches behavior based on object type or type code.

**Procedure**:
1. Create a subclass or strategy for each branch.
2. Move the branch logic into the corresponding subclass.
3. The caller invokes the method on the base type — dispatch happens via
   polymorphism.

**Resolves**: Switch Statements, Long Method.

### Example (Java)

**Before:**

```java
class Bird {
    String type;

    double speed() {
        return switch (type) {
            case "european" -> baseSpeed();
            case "african" -> baseSpeed() - loadFactor();
            case "norwegian_blue" -> isNailed ? 0 : baseSpeed();
            default -> throw new IllegalStateException();
        };
    }
}
```

**After:**

```java
abstract class Bird {
    abstract double speed();
}
class European extends Bird {
    double speed() { return baseSpeed(); }
}
class African extends Bird {
    double speed() { return baseSpeed() - loadFactor(); }
}
class NorwegianBlue extends Bird {
    double speed() { return isNailed ? 0 : baseSpeed(); }
}
```

---

## Introduce Null Object

**When**: Repeated null checks for the same object clutter the code.

**Procedure**:
1. Create a subclass or implementation that represents the "null" case with
   safe default behavior.
2. Replace null checks with the null object.

**Resolves**: Temporary Field, excessive null checks.

### Example (Java)

**Before:**

```java
Customer customer = order.getCustomer();
String name = (customer != null) ? customer.getName() : "Guest";
String plan = (customer != null) ? customer.getPlan() : Plan.basic();
```

**After:**

```java
class NullCustomer extends Customer {
    public String getName() { return "Guest"; }
    public Plan getPlan() { return Plan.basic(); }
    public boolean isNull() { return true; }
}

// Order returns NullCustomer instead of null
String name = order.getCustomer().getName();
String plan = order.getCustomer().getPlan();
```

---

## Introduce Assertion

**When**: A section of code assumes a certain condition is true, but this
assumption is not explicit.

**Procedure**:
1. Add an assertion statement that verifies the assumption.
2. If the assertion fails in tests, the caller has a bug, not this method.

**Resolves**: hidden assumptions, defensive debugging.

### Example (Java)

**Before:**

```java
double expenseLimit() {
    // should have either expense limit or primary project
    return (expenseLimit != NULL_EXPENSE)
        ? expenseLimit
        : primaryProject.getMemberExpenseLimit();
}
```

**After:**

```java
double expenseLimit() {
    assert expenseLimit != NULL_EXPENSE || primaryProject != null
        : "Must have either expense limit or primary project";
    return (expenseLimit != NULL_EXPENSE)
        ? expenseLimit
        : primaryProject.getMemberExpenseLimit();
}
