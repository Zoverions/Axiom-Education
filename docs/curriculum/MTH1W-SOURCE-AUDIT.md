# MTH1W Curriculum Source Audit

**Status:** course-completion claim blocked
**Audited:** 2026-08-01
**Student-facing label allowed:** Grade 9 Math Foundations Preview

## Authority checked

The controlling source for this audit is the Ontario Ministry of Education's
*The Ontario Curriculum, Grade 9: Mathematics, 2021*, including teacher
supports. The downloaded 222-page PDF used for the audit had SHA-256:

```text
a153c03a809551770403376db606815ee10577c36c425533495ef1abb8da91aa
```

Official publication links:

- [Publications Ontario catalogue record](https://www.publications.gov.on.ca/CL32215)
- [Ministry curriculum PDF](https://assets-us-01.kc-usercontent.com/fbd574c4-da36-0066-a0c5-849ffb2de96e/9f57c5ea-424b-42de-9152-68b4181655de/The%20Ontario%20Curriculum%20-%20Mathematics%20Grade%209%20De-streamed%20Course%202021_with%20Teacher%20Supports.pdf)

## Finding

The repository's 11-record `MTH1W` snapshot is not a complete or correctly
numbered transcription of the official 2021 course. It is useful topic data,
but it must not be presented as an authoritative expectation inventory.

Confirmed conflicts include:

- local `MTH1W-B2` means linear equations and inequalities, while official
  overall expectation B2 is **Powers**;
- local `MTH1W-B4` is an equation-of-a-line topic, while the official Number
  strand contains only overall expectations B1 through B3;
- the local snapshot omits official course areas including Coding and
  Financial Literacy.

The authoritative course is organized through mathematical thinking and
making connections plus strands A through F. A complete inventory must retain
the distinction between overall and specific expectations; the document's
ordering is not itself a required teaching sequence.

## Enforced boundary

Until every readiness gate in `config/curriculum-readiness.json` is supported
by reviewable evidence:

- the four current lessons and their deterministic exercises are a
  **foundations preview**, not a complete MTH1W course;
- local topic identifiers are displayed as derived topic references, not as
  verified official curriculum bindings;
- no completion, credit, grade, transcript, Ministry approval, or school
  equivalency may be implied;
- the curriculum browser remains an experimental corpus viewer;
- signatures and deterministic builds prove artifact integrity, not curriculum
  correctness or redistribution permission.

## Course-completion evidence required

MTH1W can be marked complete only after all of the following exist:

1. a pinned, machine-readable inventory of every official overall and specific
   expectation, with reviewed identifiers and source locations;
2. educator review of source fidelity and instructional interpretation;
3. documented licensing and redistribution disposition;
4. reviewed units and lessons covering the official course;
5. guided and independent practice with answer rationales;
6. lesson checks, quizzes, unit assessments, and cumulative review;
7. accessible and printable/offline alternatives;
8. governed progress and educator correction/review workflows; and
9. automated and human evidence showing that public claims match the delivered
   course.

Only after this gate passes does delivery move to the remaining Grade 9
courses, then later grades in order.
