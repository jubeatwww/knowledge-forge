---
name: refactorings
description: >-
  Refactoring techniques reference catalog. Covers 6 technique groups
  (Composing Methods, Moving Features, Organizing Data, Simplifying
  Conditionals, Simplifying Method Calls, Dealing with Generalization).
  Use this skill to look up how to fix code smells and improve structure.
---

# Refactoring Techniques

A refactoring is a disciplined technique for restructuring existing code without
changing its external behavior. Each technique addresses specific structural
problems and is typically motivated by one or more code smells.

Reference: https://refactoring.guru/refactoring/techniques

## Technique Groups

Load the group file that matches the needed refactoring:

| Group | File | Focus |
|-------|------|-------|
| Composing Methods | `techniques/composing-methods.md` | Streamline methods, remove duplication |
| Moving Features | `techniques/moving-features.md` | Redistribute responsibilities between classes |
| Organizing Data | `techniques/organizing-data.md` | Improve data handling and encapsulation |
| Simplifying Conditionals | `techniques/simplifying-conditionals.md` | Reduce conditional complexity |
| Simplifying Method Calls | `techniques/simplifying-method-calls.md` | Clean up method interfaces |
| Dealing with Generalization | `techniques/dealing-with-generalization.md` | Manage inheritance hierarchies |

## Usage

When a code smell is detected, look up applicable techniques from the
recommended group. Each technique entry includes: when to use it, what it does,
and the step-by-step procedure.
