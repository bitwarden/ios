# Dependency Update Review Checklist

Use for: Changes only to `Mintfile`, `project-*.yml` version references, or `Package.swift`. No business logic changes.

## Focus Areas

Dependency update reviews are **expedited** — verify the update is safe and intentional. Skip architecture and business logic review entirely.

## Checklist

**1. Understand the update:**
- What package(s) are being updated? What are the old and new versions?
- Is this a patch, minor, or major version bump?
- Is there a linked JIRA ticket or Dependabot advisory?

**2. Breaking changes:**
- Does the changelog or release notes mention breaking changes?
- Are there API removals or behavior changes that require code migration?
- For major version bumps: is migration complete, or are there unaddressed call sites?

**3. Security:**
- Is this update prompted by a CVE or security advisory? If so, does it fully address it?
- Does the update introduce new transitive dependencies? Are they from trusted sources?

**4. Supply chain:**
- Is the updated package from the same trusted publisher/maintainer?
- Any unexpected changes to the package manifest (new permissions, new network endpoints)?

**5. CI verification:**
- Do CI checks pass after the update?
- Are snapshot tests still passing (no unexpected visual regressions from UI library updates)?

## Prioritizing Findings

See `reference/priority-framework.md`. For dependency updates:
- **Critical**: Known CVE in the updated version not addressed; supply-chain concern (unexpected publisher change)
- **Important**: Breaking changes present but not fully migrated; CI failures
- **Suggested**: Beta/alpha version stability concerns; consider pinning to a patch range

## Output Format

See `examples/annotated-example.md` for the required output format and inline comment structure.
