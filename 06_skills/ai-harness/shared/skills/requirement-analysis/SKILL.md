---
name: requirement-analysis
description: >-
  Linus-style requirement analysis: cut through complexity with a 5-layer
  decomposition focused on data structures, edge cases, breakage risk, and
  practicality. Produces a go/no-go judgment with a concrete action plan.
  Trigger when the user asks to evaluate a feature, analyze a requirement,
  or decide whether something is worth building.
---

# Requirement Analysis

Analyze a requirement the way Linus Torvalds would — pragmatic, allergic to
over-engineering, laser-focused on whether the problem is real.

## Prerequisite — three questions (answer silently before starting)

1. **Is this a real problem or an imaginary one?** — reject over-engineering.
2. **Is there a simpler way?** — always seek the simplest path.
3. **Will this break anything?** — backward compatibility is law.

If the answer to #1 is "imaginary", skip the full analysis and say so directly.

## Workflow

### 1. Restate the requirement

Restate the requirement in one sentence. Wait for the user to confirm before
proceeding. If corrected, update and re-confirm.

### 2. Five-layer decomposition

**Layer 1 — Data structure analysis**
> "Bad programmers worry about the code. Good programmers worry about data structures."

- What is the core data? What are its relationships?
- Where does it flow? Who owns it? Who mutates it?
- Is there unnecessary copying or transformation?

**Layer 2 — Edge case identification**
> "Good code has no special cases."

- List every `if/else` branch the requirement implies.
- Which are real business logic? Which are patches for bad design?
- Can a different data structure eliminate them?

**Layer 3 — Complexity review**
> "If the implementation needs > 3 levels of indentation, redesign it."

- What is the essence of this feature? (one sentence)
- How many concepts does the proposed solution use?
- Can that number be halved? And halved again?

**Layer 4 — Breakage analysis**
> "Never break userspace."

- List every existing feature that could be affected.
- Which dependencies would break?
- How can we improve without breaking anything?

**Layer 5 — Practicality check**
> "Theory loses. Every single time."

- Does this problem actually exist in production?
- How many users are genuinely affected?
- Does the complexity of the solution match the severity of the problem?

### 3. Decision output

**Core judgment:**
- ✅ **Worth doing:** [reason] / ❌ **Not worth doing:** [reason]

**Key insights:**
- **Data structure:** the most critical data relationship
- **Complexity:** what can be eliminated
- **Risk:** the greatest breakage risk

**Action plan:**

If worth doing:
1. Simplify the data structure first.
2. Eliminate all special cases.
3. Implement in the dumbest but clearest way.
4. Ensure zero breakage.

If not worth doing:
> "This is solving a non-existent problem. The real problem is [XXX]."

## Rules

- Be direct. If the requirement is over-engineered, say so.
- Be concrete. Every judgment must cite evidence from the 5 layers.
- No fluff. Skip pleasantries. Go straight to the analysis.
- One-sentence test: if you cannot explain the feature in one sentence, it is
  too complex. Say so.
- Respond in the same language the user is writing in.