# Design Appendix

## Purpose

This appendix collects implementation-oriented design detail that is intentionally excluded from [SYSTEMS_DESIGN.md](./SYSTEMS_DESIGN.md).

The material here is provisional. It supports later implementation work but should not be treated as the primary statement of system purpose or design intent.

---

## Candidate Implementation Concerns

The following topics belong here rather than in the main design document:

- allocation record structure,
- submission lifecycle details,
- API shape examples,
- natural-key construction rules,
- hashing and serialization rules,
- rollout phases,
- migration strategy,
- pilot scope,
- operational success criteria.

---

## Identity Intake Patterns

The system may need to support more than one kind of incoming identity evidence.

### Provider UUID intake

Possible strategy:

- accept a provider UUID when identity policy allows it,
- use it as the tracked entity UUID when appropriate,
- otherwise retain it as provider identity evidence.

### Business-key intake

Possible strategy:

- define business-key rules per entity type,
- use those keys for reconciliation and resolution,
- retain the submitted key material for traceability.

### Authority-key intake

Possible strategy:

- attach authority identifiers where available,
- use them as additional reconciliation evidence,
- preserve them distinctly from provider keys and SEAD identity.

---

## Submission And Allocation Notes

An implementation may choose to group identity actions inside a submission concept.

That concept would typically need to support:

- grouping of related identity actions,
- traceability of submitted evidence,
- replay or idempotent re-processing,
- audit of resolution versus allocation outcomes.

The concrete schema, lifecycle states, and API representation are intentionally deferred.

---

## Mapping Notes

An implementation will likely need a persistent mapping layer between:

- tracked entity UUID,
- SEAD internal identifier,
- provider identifiers,
- business keys,
- authority keys,
- and submission context.

The exact table structure and uniqueness policy remain design work for a later stage.

---

## Update And Change Detection Notes

The broader design expects future support for change detection, but the low-level mechanism is not yet settled.

Topics still requiring explicit design include:

- what counts as the canonical aggregate payload,
- how owned child rows are normalized,
- whether associations are inside or outside aggregate payload scope,
- what fields are excluded from change evaluation,
- how deterministic serialization is defined.

### Hashing as a future mechanism

Hash-based change detection remains a candidate implementation approach, not a final design commitment.

Possible concerns include:

- algorithm choice,
- normalization rules,
- ordering rules,
- field exclusion policy,
- aggregate boundary definition.

---

## Candidate API Concerns

Later implementation work may define API behavior around concepts such as:

- submission creation,
- identity resolution,
- identity allocation,
- reconciliation outcome reporting,
- traceability queries.

Endpoint names, payload contracts, and transactional semantics are intentionally excluded from the main design document and remain deferred here as implementation topics.

---

## Candidate Rollout Topics

Rollout planning may later cover topics such as:

- initial tracked entity scope,
- pilot entity sets,
- backfill strategy for existing UUID fields,
- migration sequencing,
- integration steps for external clients.

These are planning concerns, not core design statements.

---

## Open Design Questions To Preserve

The following questions remain useful, but they belong in the appendix because they are implementation-facing rather than foundational.

1. Under what policy should a provider UUID be accepted as canonical SEAD UUID?
2. How should business-key rules be defined and governed per entity type?
3. How should existing UUID-bearing SEAD tables be backfilled or normalized where needed?
4. What submission and mapping model best supports auditability without overcomplicating the design?
5. What level of change detection is actually needed once the domain model is stable?