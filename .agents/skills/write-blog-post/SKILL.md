---
name: write-blog-post
description: Create or revise a Korean technical blog outline or draft.
disable-model-invocation: true
---

# Write Blog Post

Build an evidence-backed engineering article around its **decision trail**: application meaning, observed evidence, infrastructure decision, trade-off, and operational follow-up.

## 1. Ground

Read `blog/WRITING-GUIDE.md`, `docs/self-intro-competency-draft.md`, `docs/resume-glossary.md`, and `docs/SA-DevOps-연결점.md`.

Extract the experience only from the conversation, user-specified materials, and the existing draft. Separate observations from later interpretation. For every technical claim supporting the conclusion, decision, or recommendation, confirm the owning official documentation and plan a source footnote.

When the evidence cannot support prose, ask only for the missing fact or produce an outline that makes the gap explicit.

Completion: the topic, supported facts, and required evidence gaps are known.

## 2. Select the artefact

Name the topic with an English kebab-case `<slug>`.

- Exploration: `blog/<slug>-outline.md`
- New or revised prose: `blog/<slug>-draft.md`

Keep drafts and outlines in `blog/`. End at the validated writing artefact; use `blog/DEPLOY-GUIDE.md` only for an explicit publishing request.

Completion: the requested outline or draft is at its content-based path.

## 3. Write the decision trail

Lead with the result and state the conclusion early. Then connect the relevant application request, state, or business meaning to the symptom and evidence; explain the decision and alternatives; quantify the trade-off where safe; close with outcome, remaining risk, and operational follow-up.

For incident narratives, use hook → conclusion → sequence and mechanism → insight → lessons → sources. For design narratives, use requirements → options → decision → operating consequences.

### Tone contract

- Use first-person retrospective Korean prose; distinguish observed facts, personal judgments, and facts confirmed together.
- Write for a fellow engineer: short, concrete, conversational declarative sentences.
- State evidence-backed conclusions directly. State inferences with the check that bounds them.
- Separate experience from general principle by sentence, and cite the principle's official source.
- Prefer titles and headings that expose a result or judgment. Choose a design, comparison, or guide form when it makes the article's subject clearer.

Completion: readers can identify the conclusion, evidence, decision, trade-off, and follow-up without internal project context.

## 4. Run the gate

Apply every check in `blog/WRITING-GUIDE.md`. Read the information-exposure section of `/Users/mzc01-hbcho/github.com/kedzie-dev/kedzie-dev.github.io/SECURITY_CHECKLIST.md` and remove confidential or personal information. Retain only safe, useful numbers.

Verify every technical claim supporting the conclusion, decision, or recommendation against its citation. Check that wording attributes personal experience accurately and that the tone contract holds from title through sources.

Completion: the artefact passes the writing and security gates and is ready for the requested handoff.
