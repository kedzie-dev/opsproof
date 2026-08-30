# Review Rubric

## Evidence ladder

| Evidence | Use |
| --- | --- |
| Product, platform, or standards documentation | Confirm product names, lifecycle terms, and technical behavior. |
| First-party engineering writing | Compare architecture and delivery language in a similar operating context. |
| Engineering communities | Check whether a phrase reads naturally to practitioners; do not use it alone to prove technical behavior. |

Search both the exact phrase and the concept it is trying to name. For Korean writing, search Korean and English equivalents when the phrase may be a literal translation.

## Verdicts

| Verdict | Apply when | Action |
| --- | --- | --- |
| `keep` | The phrase is a documented product, API, standard, or widely understood technical term. | Leave it unchanged; explain only if the user asked. |
| `revise` | The phrase is a literal translation, vague abstraction, or uses a familiar term for a different concept. | Replace it with the narrowest phrase that names the actual operation. |
| `propose only` | Evidence is weak, alternatives change the intended nuance, or a rewrite would alter a supported claim. | Present alternatives and the trade-off; preserve the source text. |

Prefer a concrete noun phrase over a metaphor when it names an operational contract. For example, use `변경 절차·배포 흐름` when the text means review, approval, rollout, and rollback; use `빌드 실행 환경` when the text means where a CI job runs.

## Meaning guardrails

- Keep code identifiers, CLI options, API fields, product names, metrics, and cited terms exactly unless their owner documents a replacement.
- Keep modality: `할 수 있다`, `확인했다`, and `검증하지 못했다` carry different evidence levels.
- Keep author voice. Correct the term, not the argument's personality.
- Treat confidentiality as a separate gate: a natural phrase can still expose an internal system.

## Report format

Lead with the verdict. Then use this compact table for every changed or proposed term:

| Original | Verdict | Replacement or alternative | Reason and source |
| --- | --- | --- | --- |
| `<phrase>` | `keep` / `revise` / `propose only` | `<phrase>` | `<usage finding and direct URL, or evidence gap>` |

End with modified files, validations, and wording left as a proposal.
