# Systems Design

## Purpose

This document gives the system design view of the SEAD Identity System.

It explains:

- the design intent of the system,
- the domain model the design is built around,
- the key architectural boundaries,
- and the main design rules that shape later implementation.

It does not restate the functional requirements in detail and it does not define implementation mechanics. Those belong in [REQUIREMENTS.md](./REQUIREMENTS.md) and [DESIGN_APPENDIX.md](./DESIGN_APPENDIX.md).

---

## Design Intent

The SEAD Identity System is designed as an identity layer between external provider workflows and the SEAD relational model.

Its role is to make identity stable across submissions and across system boundaries while preserving SEAD's existing relational primary keys.

At a design level, the system exists to do four things:

1. give tracked entities a stable external identity,
2. preserve the link between that external identity and SEAD internal identity,
3. distinguish provider identity from SEAD identity,
4. support reconciliation where shared metadata or classifiers are involved.

---

## Design Boundaries

The design assumes the following boundaries.

### Internal relational identity remains in SEAD

SEAD integer or bigint primary keys remain the internal relational backbone.

### Stable cross-system identity is layered above that model

Tracked entities receive a stable UUID identity that can be resolved across submissions and across systems.

### Provider identity is not automatically canonical

A provider identifier may be accepted, mapped, reconciled, or rejected according to identity policy. It is not assumed to be identical to SEAD identity.

### Identity management is separate from business-data mutation

The identity system decides what entity is being referred to. It does not by itself define how entity state is inserted, replaced, or updated.

---

## Core Domain Model

The design is intentionally based on a generic domain model rather than on SEAD-specific table descriptions.

### Entities

Entities are domain objects with stable identity and continuity over time.

They are the primary objects managed by the identity system.

Characteristics:

- they have stable identity,
- they can participate in reconciliation,
- they can be referenced across submissions,
- they can exist independently of a specific payload instance.

### Value objects

Value objects do not carry independent identity in the identity system.

They are part of an owning entity's state and are interpreted through that owning context.

Characteristics:

- they are replaced rather than independently tracked,
- they do not receive stable identity in the identity system,
- they help describe entity state but are not identity anchors.

### Shared metadata and classifiers

Some domain objects function as shared reference structures rather than provider-owned submission data.

These require reconciliation and de-duplication rather than simple identity allocation.

Some of them may still be entities.

### Relationships

The domain model must support more than one relationship type.

#### Ownership

One object owns the state of another object.

#### Association

Two independently identified entities are linked without either owning the other's identity.

#### Reconciliation linkage

An incoming provider object is matched to an existing shared object without implying ownership.

---

## Identity Model

The design relies on a clear separation of identity notions.

### SEAD internal identity

The relational primary key used inside SEAD.

### SEAD universal identity

The stable UUID used as the cross-system identity for a tracked entity.

### Provider key

An identifier originating from a remote provider system.

### Business key

A natural key or key set used for reconciliation and identity resolution.

### Authority key

An identifier from an external authority or reference system.

The design depends on keeping these concepts distinct even when they may coincide for a particular entity.

---

## Design Rules

### 1. Track identity for entities, not for every row

The identity system should anchor stable identity at the entity level.

### 2. Treat value objects as aggregate state

Owned child structures should be handled as part of entity state rather than as independently tracked identities.

### 3. Support associations as well as ownership

The design must not collapse all relationships into a parent-child containment model.

### 4. Separate provider-owned data from shared reference structures

Shared metadata and classifiers must support reconciliation, not only allocation.

### 5. Keep canonical SEAD identity distinct from aliasing identifiers

Provider keys, business keys, and authority keys may all contribute evidence, but they should not erase the distinction between canonical SEAD identity and external mappings.

### 6. Preserve room for future update behavior

The design should support later change detection and update handling, but those mechanisms are not part of this document's core design scope.

---

## Architectural View

At a high level, the system has three conceptual responsibilities.

### Identity resolution

Determine whether incoming identity evidence refers to an existing tracked entity.

### Identity allocation

Mint or assign stable identity when no acceptable existing identity is found.

### Identity mapping and traceability

Preserve the relationship between resolved SEAD identity and the evidence that led to that resolution.

This means the system sits logically between:

- provider submissions,
- reconciliation policy,
- and SEAD's relational persistence model.

---

## What This Document Deliberately Leaves Out

This design view does not define:

- endpoint shapes,
- request and response contracts,
- rollout phases,
- migration steps,
- hashing rules,
- serialization rules,
- natural-key construction rules,
- storage schema for allocation records,
- performance or operational requirements.

Those details belong in [DESIGN_APPENDIX.md](./DESIGN_APPENDIX.md) or in later implementation documents.

---

## Relationship To Other Documents

- [REQUIREMENTS.md](./REQUIREMENTS.md) defines what the system must do.
- [ASSESSMENT.md](./ASSESSMENT.md) captures design strengths, weaknesses, and unresolved issues.
- [DESIGN_APPENDIX.md](./DESIGN_APPENDIX.md) holds implementation-oriented design details and lower-level notes.