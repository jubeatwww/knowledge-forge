---
name: code-smells
description: >-
  Code smell detection reference. Covers 5 smell categories (Bloaters,
  Object-Orientation Abusers, Change Preventers, Dispensables, Couplers) with
  detection criteria and recommended refactoring techniques for each smell.
  Use this skill when reviewing code for structural quality issues.
---

# Code Smells

A code smell is a surface-level indicator that usually signals a deeper problem
in the code. Smells themselves are not bugs — the code may work fine — but they
increase the risk of bugs and make the codebase harder to evolve.

Reference: https://refactoring.guru/refactoring/smells

## Categories

Load the category file that matches the review focus:

| Category | File | Focus |
|----------|------|-------|
| Bloaters | `categories/bloaters.md` | Code that has grown too large to manage |
| OO Abusers | `categories/oo-abusers.md` | Misuse of object-oriented principles |
| Change Preventers | `categories/change-preventers.md` | Code that resists modification |
| Dispensables | `categories/dispensables.md` | Unnecessary code that adds no value |
| Couplers | `categories/couplers.md` | Excessive coupling between components |

## Usage

When performing a code quality review:

1. Load the relevant category file(s) for the review scope.
2. Apply detection criteria from each smell entry to the code under review.
3. For each detected smell, reference the `refactorings` skill for fix procedures.
