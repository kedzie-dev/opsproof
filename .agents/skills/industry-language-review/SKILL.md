---
name: industry-language-review
description: Review and minimally revise Korean technical writing when its terminology or phrasing may be nonstandard, translated, ambiguous, or unidiomatic for engineers. Use for technical blog posts, portfolios, résumés, architecture proposals, and requests to check whether engineers actually use an expression.
---

# Industry Language Review

Run a **교정 루프**: investigate usage, preserve meaning, make the smallest justified edit.

## 1. Fix the review boundary

Identify the target text, audience, and requested action: report only, propose edits, or edit files. Preserve product names, API names, code identifiers, metrics, citations, and supported facts unless the user explicitly asks to change them.

Completion: every sentence or term under review is known, and the allowed edit scope is explicit.

## 2. Establish usage

Read [the review rubric](references/review-rubric.md) before judging candidates. For each questionable expression, search the expression and the underlying concept.

Use this evidence order:

1. Documentation owned by the product, platform, or standard.
2. First-party engineering writing from organizations operating comparable systems.
3. Credible engineering communities, only to check natural practitioner phrasing.

Record a direct source for any claim about industry usage. Treat a search-result snippet as a lead, not evidence. Mark each candidate `keep`, `revise`, or `propose only` using the rubric.

Completion: every candidate has a verdict, reason, and source or an explicit evidence gap.

## 3. Make the minimal correction

Keep established technical terms. Replace a literal translation or vague abstraction with wording that states the actual responsibility, lifecycle, flow, or operation. Preserve the original claim strength: a language edit must not turn a possibility into a fact or an unmeasured effect into a result.

When evidence is insufficient or multiple phrasings change the intended nuance, report alternatives instead of editing.

Completion: each edit improves clarity or industry fit without changing technical meaning, evidence level, or author voice.

## 4. Close the loop

Review the diff in context. Re-check citations when a technical claim changed. For public technical content, run the repository's relevant Markdown, build, and information-exposure checks.

Report the conclusion first: whether the questioned expression is established, what replaced it, why, modified files, and checks run. Use the format in the rubric.

Completion: every edit is accounted for, validations are reported, and unverified wording remains a proposal rather than a claim.
