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

### Example (Java)

**Before:**

```java
class Account {
    AccountType type;
    int daysOverdrawn;

    double overdraftCharge() {
        if (type.isPremium()) {
            return type.getPremiumRate() * daysOverdrawn;
        }
        return daysOverdrawn * 1.75;
    }
}
```

**After:**

```java
class AccountType {
    double overdraftCharge(int daysOverdrawn) {
        if (isPremium()) {
            return getPremiumRate() * daysOverdrawn;
        }
        return daysOverdrawn * 1.75;
    }
}

class Account {
    AccountType type;
    int daysOverdrawn;

    double overdraftCharge() {
        return type.overdraftCharge(daysOverdrawn);
    }
}
```

---

## Move Field

**When**: A field is used by another class more than the class that defines it.

**Procedure**:
1. Create the field in the target class.
2. Update all readers/writers to reference the new location.
3. Remove the field from the original class.

**Resolves**: Feature Envy, Shotgun Surgery.

### Example (Java)

**Before:**

```java
class Account {
    double interestRate;
    AccountType type;

    double interestFor(double amount, int days) {
        return interestRate * amount * days / 365;
    }
}
```

**After:**

```java
class AccountType {
    double interestRate;
    double getInterestRate() { return interestRate; }
}

class Account {
    AccountType type;

    double interestFor(double amount, int days) {
        return type.getInterestRate() * amount * days / 365;
    }
}
```

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

### Example (Java)

**Before:**

```java
class Person {
    String name;
    String areaCode;
    String number;

    String getPhone() { return areaCode + "-" + number; }
}
```

**After:**

```java
class Person {
    String name;
    TelephoneNumber phone;

    String getPhone() { return phone.toString(); }
}

class TelephoneNumber {
    String areaCode;
    String number;

    public String toString() { return areaCode + "-" + number; }
}
```

---

## Inline Class

**When**: A class does almost nothing and has no reason to exist.

**Procedure**:
1. Move all fields and methods from the class into another class.
2. Update all clients.
3. Delete the empty class.

**Resolves**: Lazy Class, Shotgun Surgery.

### Example (Java)

**Before:**

```java
class Person {
    TelephoneNumber phone;
    String getPhone() { return phone.getNumber(); }
}

class TelephoneNumber {
    String number;
    String getNumber() { return number; }
}
```

**After:**

```java
class Person {
    String phoneNumber;
    String getPhone() { return phoneNumber; }
}
```

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

### Example (Java)

**Before:**

```java
// Client navigates through a chain
String managerName = person.getDepartment().getManager().getName();
```

**After:**

```java
class Person {
    Department department;

    String getManagerName() {
        return department.getManager().getName();
    }
}

// Client uses the wrapper
String managerName = person.getManagerName();
```

---

## Remove Middle Man

**When**: A class has too many delegating methods that just forward calls.

**Procedure**:
1. Create an accessor for the delegate.
2. Replace client calls to delegating methods with direct calls via the
   accessor.
3. Delete the delegating methods.

**Resolves**: Middle Man.

### Example (Java)

**Before:**

```java
class Person {
    Department department;
    String getManagerName() { return department.getManager().getName(); }
    String getDeptName()    { return department.getName(); }
    int    getDeptCode()    { return department.getCode(); }
}
```

**After:**

```java
class Person {
    Department department;
    Department getDepartment() { return department; }
}

// Client calls directly
String name = person.getDepartment().getManager().getName();
```

---

## Introduce Foreign Method

**When**: A library class lacks a method you need, and you can't modify the
library.

**Procedure**:
1. Create a utility method in the client class.
2. Pass the library object as the first parameter.
3. Document that this is a foreign method that ideally belongs in the library.

**Resolves**: Incomplete Library Class.

### Example (Java)

**Before:**

```java
// Inline date arithmetic scattered in client code
Date nextDay = new Date(date.getYear(), date.getMonth(), date.getDate() + 1);
```

**After:**

```java
// Foreign method — ideally belongs in Date
static Date nextDay(Date date) {
    return new Date(date.getYear(), date.getMonth(), date.getDate() + 1);
}

Date nextDay = nextDay(date);
```

---

## Introduce Local Extension

**When**: A library class needs several additional methods.

**Procedure**:
1. Create a new class — either a subclass or a wrapper of the library class.
2. Add the needed methods.
**Resolves**: Incomplete Library Class.

### Example (Java)

**Before:**

```java
// Utility methods scattered across clients
Date nextDay = DateUtil.nextDay(date);
Date endOfMonth = DateUtil.endOfMonth(date);
```

**After:**

```java
class EnhancedDate {
    private final Date date;
    EnhancedDate(Date date) { this.date = date; }

    Date nextDay() {
        return new Date(date.getYear(), date.getMonth(), date.getDate() + 1);
    }

    Date endOfMonth() { /* calendar logic */ return null; }
}

EnhancedDate d = new EnhancedDate(date);
Date tomorrow = d.nextDay();
```
