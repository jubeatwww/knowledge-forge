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

### Example (Java)

**Before:**

```java
void printOwing(double amount) {
    System.out.println("*****");
    System.out.println("** Banner **");
    System.out.println("*****");
    System.out.println("name: " + name);
    System.out.println("amount: " + amount);
}
```

**After:**

```java
void printOwing(double amount) {
    printBanner();
    printDetails(amount);
}

void printBanner() {
    System.out.println("*****");
    System.out.println("** Banner **");
    System.out.println("*****");
}

void printDetails(double amount) {
    System.out.println("name: " + name);
    System.out.println("amount: " + amount);
}
```

---

## Inline Method

**When**: A method body is as clear as the method name, or the method is a
trivial delegation.

**Procedure**:
1. Verify the method is not overridden in subclasses.
2. Replace all calls with the method body.
3. Delete the method.

**Resolves**: Speculative Generality, Middle Man.

### Example (Java)

**Before:**

```java
int getRating() {
    return moreThanFiveLateDeliveries() ? 2 : 1;
}

boolean moreThanFiveLateDeliveries() {
    return numberOfLateDeliveries > 5;
}
```

**After:**

```java
int getRating() {
    return numberOfLateDeliveries > 5 ? 2 : 1;
}
```

---

## Extract Variable

**When**: A complex expression is hard to understand.

**Procedure**:
1. Declare a new variable with a descriptive name.
2. Assign the expression (or its sub-expression) to the variable.
3. Replace the expression with the variable reference.

**Resolves**: Comments, readability.

### Example (Java)

**Before:**

```java
if (platform.toUpperCase().contains("MAC")
        && browser.toUpperCase().contains("IE")
        && wasInitialized() && resize > 0) {
    // perform action
}
```

**After:**

```java
boolean isMacIE = platform.toUpperCase().contains("MAC")
        && browser.toUpperCase().contains("IE");
boolean isReady = wasInitialized() && resize > 0;

if (isMacIE && isReady) {
    // perform action
}
```

---

## Inline Temp

**When**: A temporary variable is assigned once and used once, adding no
clarity.

**Procedure**:
1. Verify the variable is assigned exactly once.
2. Replace all reads with the right-hand-side expression.
3. Delete the variable declaration.

**Resolves**: intermediate step for other refactorings.

### Example (Java)

**Before:**

```java
double basePrice = order.basePrice();
return basePrice > 1000;
```

**After:**

```java
return order.basePrice() > 1000;
```

---

## Replace Temp with Query

**When**: A temporary variable holds the result of an expression that could be
a method.

**Procedure**:
1. Extract the expression into a new method (query).
2. Replace the temp variable with a call to the query method.
3. The new method can now be reused by other methods.

**Resolves**: Long Method (enables further extraction).

### Example (Java)

**Before:**

```java
double getPrice() {
    double basePrice = quantity * itemPrice;
    if (basePrice > 1000) {
        return basePrice * 0.95;
    }
    return basePrice * 0.98;
}
```

**After:**

```java
double getPrice() {
    if (basePrice() > 1000) {
        return basePrice() * 0.95;
    }
    return basePrice() * 0.98;
}

double basePrice() {
    return quantity * itemPrice;
}
```

---

## Split Temporary Variable

**When**: A temporary variable is assigned more than once (not a loop counter
or accumulator) for different purposes.

**Procedure**:
1. Rename the first assignment's variable to reflect its purpose.
2. Create a new variable for the second assignment.
3. Repeat for each subsequent reuse.

**Resolves**: readability, makes Extract Method easier.

### Example (Java)

**Before:**

```java
double temp = 2 * (height + width);
System.out.println("Perimeter: " + temp);
temp = height * width;
System.out.println("Area: " + temp);
```

**After:**

```java
double perimeter = 2 * (height + width);
System.out.println("Perimeter: " + perimeter);
double area = height * width;
System.out.println("Area: " + area);
```

---

## Remove Assignments to Parameters

**When**: A method assigns a new value to a parameter.

**Procedure**:
1. Create a local variable and assign the parameter's value to it.
2. Replace all subsequent references to the parameter with the local variable.

**Resolves**: confusing side effects, enables clearer parameter contracts.

### Example (Java)

**Before:**

```java
int discount(int inputVal, int quantity) {
    if (quantity > 50) inputVal -= 2;
    if (quantity > 100) inputVal -= 1;
    return inputVal;
}
```

**After:**

```java
int discount(int inputVal, int quantity) {
    int result = inputVal;
    if (quantity > 50) result -= 2;
    if (quantity > 100) result -= 1;
    return result;
}
```

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

### Example (Java)

**Before:**

```java
class Order {
    double price() {
        double primaryBase = quantity * itemPrice;
        double secondaryBase = primaryBase * 0.1;
        double tertiaryBase = secondaryBase * 1.05;
        // long computation using all locals ...
        return primaryBase - secondaryBase + tertiaryBase;
    }
}
```

**After:**

```java
class Order {
    double price() {
        return new PriceCalculator(this).compute();
    }
}

class PriceCalculator {
    private double primaryBase, secondaryBase, tertiaryBase;

    PriceCalculator(Order order) {
        primaryBase = order.quantity * order.itemPrice;
        secondaryBase = primaryBase * 0.1;
        tertiaryBase = secondaryBase * 1.05;
    }

    double compute() {
        return primaryBase - secondaryBase + tertiaryBase;
    }
}
```

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

### Example (Java)

**Before:**

```java
String foundPerson(String[] people) {
    for (int i = 0; i < people.length; i++) {
        if (people[i].equals("Don")) return "Don";
        if (people[i].equals("John")) return "John";
        if (people[i].equals("Kent")) return "Kent";
    }
    return "";
}
```

**After:**

```java
String foundPerson(String[] people) {
    Set<String> candidates = Set.of("Don", "John", "Kent");
    return Arrays.stream(people)
            .filter(candidates::contains)
            .findFirst()
            .orElse("");
}
```
