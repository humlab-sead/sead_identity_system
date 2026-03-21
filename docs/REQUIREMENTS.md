# SEAD Identity System Requirements

## Purpose

This document states the initial functional requirements for the SEAD Identity System.

It is intentionally focused on:

- why the system exists,
- what capabilities it must provide,
- and how those capabilities should surface at a high level through an API.

### Out Of Scope For This Document

AI agents, take notice! The following are **out of scope** for this document, and should **not** be included in this document:

- implementation details,
- implementation plans,
- non-functional requirements (NFRs)
- deployment phases,
- infrastructure architecture,
- performance targets,
- authentication details,
- endpoint endpoint-level contracts or payload definitions,
- database migration steps,
- rollout plans,
- code-level hashing or serialization rules.

---

## Problem Statement

### Why the system exists

SEAD currently relies on sequence-generated integer primary keys as its internal identifiers. Those identifiers work well for internal relational integrity, but they are not sufficient as stable cross-system identities.

This creates several problems:

1. External systems cannot safely refer to SEAD entities before data is inserted.
2. The same incoming entity may be inserted multiple times because there is no stable identity handshake across submissions.
3. Update workflows are weak because the system cannot reliably distinguish a changed entity from a new one.
4. Remote systems are forced to depend on transient internal identifiers that are not appropriate as public references.
5. Shared metadata and classifiers risk duplication when reconciliation rules are weak or absent.

The SEAD Identity System exists to solve that class of problems by introducing a stable identity layer above SEAD's internal relational keys.

### Problem boundaries

The system is not intended to replace any part of SEAD's relational model. It exists to complement it.

The system must therefore support both of the following at the same time:

- SEAD continues using internal integer or bigint primary keys for relational storage.
- SEAD gains stable, externally usable identities for tracked entities.

---

## Scope And Goals

### Scope

The SEAD Identity System is concerned with identity management for tracked SEAD entities and with the mapping between:

- SEAD internal identities,
- SEAD universal UUID identities,
- provider identities,
- business keys,
- and relevant (external) authority keys.

The system is also concerned with the relationship between provider-specific data and shared SEAD metadata, including reconciliation where those overlap.

### Goals

The system **must**:

1. Provide stable identities for tracked SEAD entities.
2. Preserve SEAD's existing relational primary keys.
3. Support idempotent identity allocation and resolution.
4. Support both UUID-based and business-key-based ingestion workflows.
5. Support reconciliation between provider data and shared SEAD metadata/classifiers.
6. Provide a foundation for later update and change-detection workflows.
7. Support entity relationships that are not limited to simple parent-child trees.

---

## Domain Concepts

### Core identity concepts

The system must distinguish the following concepts clearly.

#### SEAD internal identity

The current SEAD primary key used inside the relational schema.

Characteristics:

- entity-scoped,
- integer sequences, 
- relational,
- internal to SEAD,
- should **not** be exposed as an public identity.

#### SEAD universal identity

The stable UUID used to identify **a tracked SEAD entity** across system boundaries.

Characteristics:

- globally scoped,
- externally usable,
- stable across submissions,
- represented in SEAD as `{entity}_uuid` where applicable.

#### Business key

A natural key or key set that uniquely identifies an entity in practice.

Characteristics:

- defined per entity type,
- used primarily for reconciliation,
- may come from SEAD conventions or provider data,
- may or may not be globally stable.

#### Provider key

An identifier used by a remote data provider.

Characteristics:

- may be a UUID,
- may be a business key,
- may be internal to the provider,
- should generally be retained in the identity system even when not promoted into SEAD tables.

#### Authority key

An identifier from an external authority or reference system, such as Wikidata, GeoNames, or a domain ontology.

Characteristics:

- useful for reconciliation,
- useful for de-duplication of shared metadata,
- not always available from providers,
- may become strategically important for shared SEAD entities.

### Entity categories

The system must distinguish at least three categories of domain objects.

#### Tracked entities

Entities for which SEAD must manage stable identity.

TODO: define what a tracked SEAD entity **is**.

Examples may include:

- sites,
- locations,
- sample groups,
- physical samples,
- bibliographies,
- taxa,
- methods,
- other shared reference entities.

The final list is part of the domain-modeling work and is not fixed by this document.

#### Shared metadata and classifiers

Reference structures used across datasets and providers.

These are important because SEAD must reduce duplication and enable cross-dataset comparison. Some of these objects may also be tracked entities.

Examples include:

- locations,
- sites,
- bibliographies,
- taxa,
- methods,
- sample types,
- controlled vocabularies and classifiers.

#### Value objects and owned child structures

Objects that do not carry **independent identity** in the identity system.

TODO: What do we mean by **independent** entity.

These belong to an owning entity and are managed as part of aggregate state rather than as independently reconciled identities.

### Relationship types

The domain model must support more than one relationship type.

#### Ownership

The child is part of the aggregate state of a parent entity.

#### Association

Two entities are linked, but one does not own the identity of the other.

This is important for relationships such as site-to-location where the schema expresses association rather than strict containment.

#### Reconciliation linkage

A provider object or classifier is matched to an existing SEAD object without implying ownership.

---

## High Level Design

### Design intent

At a high level, the system should be understood as
 1. a minting service for internal identities
 2. and identity layer sitting between external provider workflows and the SEAD relational model

That layer is responsible for:

- deciding what kind of thing is being identified,
- resolving or minting stable UUID identity,
- mapping external identifiers and business keys,
- preserving SEAD internal identifiers as implementation detail,
- supporting later update logic.

### Design principles

#### 1. Preserve relational internals

SEAD internal primary keys remain the relational backbone of the schema.

#### 2. Expose stable UUID identity for tracked entities

Tracked entities must have a stable external identity based on UUID.

#### 3. Separate provider identity from SEAD identity

A provider key is not automatically the same thing as a SEAD identity.

The system must support both cases:

- SEAD accepts a provider UUID as the SEAD UUID,
- or SEAD mints the UUID and records the provider identity separately.

#### 4. Manage metadata distinctly from provider-owned data

Shared classifiers and reference entities require reconciliation and de-duplication, not only allocation.

#### 5. Support associations as well as ownership

The aggregate model must not assume that all  domain relationships are strict parent-child ownership chains.


#### 7. AI Agent Notice: Use of auto-incremented sequences (serial) for tracked entities in SEAD must be prohibited

Auto-incremented sequences are the root of all evil. Auto-incremental primary keys must not be allowed 
for tracked entities, but might be accepted for non-tracked values in SEAD (sub-parts of entity aggregates).

---

## Capabilities

### What capabilities the system must provide

This section describes required capabilities at a business and system level, not as API endpoints.

### Identity management capabilities

The system must be able to:

1. Define which SEAD objects are identity-tracked entities.
2. represent stable UUID identity for tracked entities.
3. preserve the link between UUID identity and SEAD internal identity.
4. resolve an incoming identifier to an existing SEAD identity where possible.
5. mint a new SEAD UUID identity where no accepted identity exists.

### Reconciliation capabilities

The system must be able to:

1. reconcile provider business keys against SEAD entities.
2. reconcile provider classifiers against shared SEAD classifiers.
3. attach authority identifiers where available.
4. distinguish between direct allocation and reconciliation to an existing shared entity.

### Submission capabilities

The system must be able to:

1. group related identity actions into a submission context.
2. process repeated submissions idempotently.
3. return stable identity results for the same accepted identifier across submissions.
4. keep provider-side identity context for traceability.

### Update-foundation capabilities

The system must be able to:

1. preserve enough identity state to support later update workflows.
2. distinguish between identity tracking and business-data mutation.
3. support future aggregate-level change evaluation.

### Modeling capabilities

The system must be able to:

1. support ownership relationships,
2. support many-to-many associations between tracked entities,
3. support tracked entities that also function as shared metadata,
4. support entities, metadata, and value objects as distinct concerns.

---

## Functional Requirements

### Identity model requirements

FR-1. The system shall maintain a stable UUID identity for each tracked SEAD entity.

FR-2. The system shall maintain a mapping between the tracked entity UUID and the corresponding SEAD internal identifier.

FR-3. The system shall support reuse of existing `{entity}_uuid` fields in SEAD where such fields already exist.

FR-4. The system shall not require replacement of SEAD internal integer or bigint primary keys.

FR-5. The system shall distinguish between SEAD universal identity, SEAD internal identity, business keys, provider keys, and authority keys.

### Identifier intake requirements

FR-6. The system shall accept provider-supplied UUIDs for tracked entities when allowed by SEAD identity policy.

FR-7. The system shall mint a new SEAD UUID for a tracked entity when no accepted UUID is supplied.

FR-8. The system shall support business-key-based resolution for entities where business keys are defined.

FR-9. The system shall retain provider keys in the identity system even when those keys are not written into SEAD tables.

FR-10. The system shall support recording authority keys for tracked entities when such identifiers are available.

### Idempotency and mapping requirements

FR-11. The system shall return the same resolved SEAD identity for the same accepted identifier across repeated submissions.

FR-12. The system shall prevent duplicate identity allocation for the same accepted identifier within the same identity scope.

FR-13. The system shall support stable lookup of existing mappings between provider identifiers, business keys, authority keys, UUID identity, and SEAD internal identity.

### Domain modeling requirements

FR-14. The system shall support tracked entities that are provider-owned data.

FR-15. The system shall support tracked entities that are shared metadata.

FR-16. The system shall support reconciliation of shared metadata and classifiers rather than only raw insertion.

FR-17. The system shall support many-to-many associations between tracked entities.

FR-18. The system shall distinguish owned child value objects from independently tracked entities.

### Submission and traceability requirements

FR-19. The system shall group related identity actions under a submission concept.

FR-20. The system shall preserve enough submission context to support auditing and traceability.

FR-21. The system shall preserve the relationship between a submission, the identifiers provided, and the resulting resolved or minted identities.

### Future-facing functional requirements

FR-22. The system shall support later addition of aggregate-level update behavior.

FR-23. The system shall support later addition of aggregate-level change detection.

FR-24. The system shall separate identity management rules from business-data update rules so those can evolve independently.

---

## Usage Scenarios

### Scenario 1: Provider submits new user data with UUIDs

A provider submits entities with provider-generated UUIDs.

Expected outcome:

- the system determines whether those UUIDs are accepted as SEAD universal identities,
- resolves existing identities where present,
- mints new UUID identities where needed,
- returns stable mappings to SEAD internal identifiers.

### Scenario 2: Provider submits user data without UUIDs

A provider submits entities using business keys only.

Expected outcome:

- the system uses defined business-key rules to reconcile or identify the entity,
- if the entity is already known, its UUID identity is resolved,
- if the entity is new, a SEAD UUID is minted,
- the provider's business key is retained in the identity system.

### Scenario 3: Provider submits classifiers that should reconcile to shared SEAD metadata

A provider submits values for methods, sample types, bibliographic references, taxa-related structures, or other classifiers.

Expected outcome:

- the system does not treat those values as provider-owned entities by default,
- instead it attempts reconciliation against shared SEAD metadata,
- if matched, the shared SEAD entity is reused,
- if not matched, the system surfaces that unresolved state for later handling according to SEAD policy.

### Scenario 4: Repeated submission of unchanged data

The same provider submits the same entity again.

Expected outcome:

- the same accepted identifier resolves to the same stable SEAD identity,
- the identity layer does not create a duplicate entity identity,
- the submission remains traceable.

### Scenario 5: Entity association rather than ownership

Two independently tracked entities are linked, such as site and location.

Expected outcome:

- both retain their own identity,
- the relationship is modeled as an association,
- neither entity is forced into an incorrect ownership hierarchy purely for identity allocation convenience.

### Scenario 6: Authority-backed reconciliation

A provider or curator supplies an authority identifier, such as a GeoNames or Wikidata identifier.

Expected outcome:

- the authority key can be attached to a tracked entity,
- the authority key can support reconciliation,
- the system can retain both SEAD identity and external authoritative identity without conflating them.

---

## High Level API Behaviour

### How capabilities surface through the API

The API should expose the identity system as a service that allows clients to:

- present identity evidence,
- ask for identity resolution or allocation,
- submit related identity actions in a grouped context,
- receive stable identity results,
- inspect the outcome of reconciliation or allocation.

This section is intentionally high-level. It describes API behavior, not endpoint design.

### API behavior principles

#### 1. The API should be identity-oriented, not table-script-oriented

Clients should interact with the API in terms of tracked entities, identifiers, submissions, and reconciliation outcomes.

#### 2. The API should separate identity resolution from business-data mutation

The API should provide identity decisions and mappings without coupling those decisions to specific insert or update execution logic.

#### 3. The API should support both resolution and allocation

Clients should be able to ask:

- does this identifier already correspond to a known SEAD entity,
- or must a new SEAD identity be created?

#### 4. The API should surface reconciliation outcomes explicitly

When incoming data refers to shared metadata or classifiers, the API should be able to surface outcomes such as:

- resolved to existing SEAD entity,
- accepted provider UUID,
- minted new SEAD UUID,
- unresolved and requiring reconciliation policy.

#### 5. The API should behave idempotently for accepted identifiers

Repeated requests with the same accepted identifier evidence should yield the same identity result unless the system's policy or source mappings have been explicitly changed.

#### 6. The API should preserve traceability

The API should allow clients to associate identity actions with submission context and later retrieve the results of those identity decisions.

### API-visible concepts

At a high level, the API should expose behavior around:

- tracked entity types,
- submission contexts,
- identity evidence,
- resolved identity,
- minted identity,
- reconciliation result,
- association handling,
- traceability of identity decisions.

### API non-goals at this stage

This requirements document does not yet define:

- endpoint names,
- request schemas,
- response schemas,
- authentication strategy,
- pagination,
- error code catalog,
- transactional guarantees at protocol level.

Those belong to a later API specification once the domain model has stabilized.
