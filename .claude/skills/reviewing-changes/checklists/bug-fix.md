# Bug Fix Review Checklist

Use for: Targeted changes to existing `*Processor.swift`, `*Service.swift`, `*Repository.swift`, or `*View.swift` to fix a specific defect.

## Focus Areas

Bug fix reviews are **focused** — check the fix and its blast radius. Skip comprehensive architecture review unless the fix touches architectural patterns.

## Checklist

**1. Understand the bug:**
- What was the original defect? Read the PR description or linked JIRA ticket.
- What is the root cause vs the symptom?
- Is this fix addressing the root cause or just the symptom?

**2. Fix correctness:**
- Does the fix actually solve the described bug?
- Could the fix introduce regressions in related code paths?
- Any edge cases the fix doesn't handle (nil, empty, concurrent access)?

**3. Regression test:**
- Is there a test that would have caught the original bug?
- Does the fix include a new test that would prevent regression?
- If no test is added: is there a clear reason it's impractical?

**4. Security check (for any fix touching auth, encryption, or Keychain):**
- Does the fix preserve the zero-knowledge architecture?
- Does it change how credentials are stored or transmitted?
- See `reference/ios-security-patterns.md` for detail.

**5. Scope check:**
- Is the fix minimal? Large diffs in a "bug fix" PR warrant scrutiny.
- Any unrelated changes that should be in a separate PR?

**6. Documentation:**
- If the bug was caused by unclear code, is a comment added to prevent recurrence?
- Any `TODO`s added? → Must include JIRA ticket reference.

## Prioritizing Findings

See `reference/priority-framework.md`. For bug fixes:
- **Critical**: Fix doesn't address root cause, or fix introduces security regression
- **Important**: Missing regression test for the fixed behavior
- **Suggested**: Similar latent bugs in adjacent code

## Output Format

See `examples/annotated-example.md` for the required output format and inline comment structure.
