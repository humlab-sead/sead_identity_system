# SEAD Identity System Assessment

## Scope

This assessment is based on the current draft material in:

- `docs/aggregate_model/`
- `docs/bugs_cep/`
- `docs/sead/`
- `docs/`

The purpose of the proposed system is sound: provide stable identity links between foreign systems and SEAD while preserving SEAD's existing integer primary keys.

---

## Overall Assessment

The current design is in a good **conceptual design** state, but not yet in a fully consistent **implementation-ready** state.

The strongest part of the proposal is the core architectural idea:

- treat identity as a concern for **entities / aggregate roots** rather than every row,
- keep SEAD integer keys for internal relational use,
- introduce stable external identity for cross-system coordination,
- support idempotent allocation so the same external identity resolves to the same SEAD entity.

That is a strong direction and it fits the stated domain rule well: update the entity row, but replace child/value-object rows rather than tracking identity for those children individually.

However, the current drafts still have important gaps and contradictions:

- some of the design documentation does not match the actual SEAD schema,
- the boundary between **canonical SEAD identity** and **provider-supplied identity** is not fully resolved,
- update semantics are described conceptually but not yet specified precisely enough for implementation,
- parts of the implementation and NFR drafts are more detailed than the core domain model currently justifies.

My conclusion is that the project has a solid foundation, but it still needs another design pass before implementation should begin.

I also agree with the decision to **stash the implementation plan for now**. At the current maturity level, the right priority is:

- define the SEAD entity model,
- decide aggregate boundaries,
- distinguish entities from shared metadata and classifiers,
- define identity terms and reconciliation rules,
- then return to implementation planning.

---

## What Is Already Strong

### 1. The problem statement is correct

The design correctly identifies the main failure mode in the current SEAD model:

- integer sequence keys are local database identifiers,
- they are allocated late,
- they are poor cross-system identifiers,
- they do not provide a stable basis for idempotent re-submission or update handling.

That diagnosis is accurate and well supported by both the SIMS drafts and the BUGS/CEP example.

### 2. Aggregate-focused identity is the right abstraction

The decision to track identity for **entities / aggregate roots**, but not for child value objects, is the best part of the design.

This gives the system a clear operational rule:

- the aggregate root has stable identity,
- owned children are part of the aggregate state,
- updates replace child collections instead of attempting row-by-row identity matching.

This is a good fit for SEAD because much of the churn and ambiguity appears below the main submission entities rather than at the entity root itself.

### 3. The hybrid UUID + natural-key approach is pragmatic

Supporting both:

- UUID for technically capable providers, and
- natural keys for legacy or spreadsheet-driven providers

is a practical design choice.

If the system required UUID only, adoption would be harder. If it relied on natural keys only, stability would be weaker. The hybrid model is therefore sensible.

### 4. The central mapping concept is sound

The proposed allocation registry is a good core pattern because it gives you:

- idempotent allocation,
- auditability,
- submission grouping,
- rollback support,
- a future hook for change detection.

The BUGS/CEP trace table is a useful historical proof that this class of approach works in practice.

### 5. Separating SIMS from Shape Shifter is a good boundary

Treating SIMS as a separate SEAD-side service and Shape Shifter as a client is the right architectural boundary.

That keeps:

- identity policy in one place,
- ingestion and normalization logic in another,
- long-term identity governance independent of any single ingester implementation.

---

## Main Weaknesses And Gaps

### 1. The docs are not yet internally consistent

The drafts are aligned at the intent level, but not yet at the schema level.

The biggest issue is that some entity dependency statements in the aggregate-model docs do not match the SEAD DDL.

Examples from the actual schema:

- `tbl_sample_groups.site_id -> tbl_sites.site_id`
- `tbl_physical_samples.sample_group_id -> tbl_sample_groups.sample_group_id`
- `tbl_analysis_entities.physical_sample_id -> tbl_physical_samples.physical_sample_id`

Those support the proposed aggregate chain reasonably well.

But the location/site relationship is different from what the aggregate draft implies:

- `tbl_sites` does **not** depend directly on `tbl_locations`
- the relationship is modeled through `tbl_site_locations`
- this means site/location is an association, not a simple parent-child containment hierarchy

That matters because the aggregate design currently treats `location -> site` as a direct dependency. In the actual schema, that is not true.

This should be expanded into a broader modeling rule:

- the system must allow **many-to-many relationships between entities**,
- the design must distinguish between **provider data** and **shared SEAD metadata / classifiers**,
- some things can be entities and still function as shared metadata rather than provider-owned data.

That distinction is important in SEAD. For example:

- `Location` is an entity, but it is also shared metadata,
- `Site` may also be treated as shared metadata rather than provider-owned data,
- `Bibliographies`, `Taxa Tree`, `Methods`, and `Sample Type` are all examples of metadata or classifier structures that need reconciliation rather than naive duplication.

This implies a design requirement that is not yet fully expressed in the current drafts:

- provider-specific data and shared SEAD reference structures should not be modeled the same way,
- classifiers and metadata need explicit reconciliation workflows,
- the aggregate model must support associations between entities, not only parent-child ownership chains.

So the statement that `Location` is the aggregate root for `Site` should be treated as a flaw in the current realization of the aggregate model, not as a settled design decision.

### 2. Some implementation assumptions duplicate or conflict with existing SEAD columns

The implementation draft proposes adding `{entity}_external_id` columns to pilot tables. That should be revised.

But the actual schema already includes UUIDs on at least some core tables:

- `tbl_sites.site_uuid`
- `tbl_sample_groups.sample_group_uuid`

If the design adds parallel `site_external_id` and `sample_group_external_id` columns, then these tables would effectively have two competing external identity columns.

That creates design ambiguity:

- Which one is canonical?
- Are old UUIDs aliases or the main identity?
- If both are kept, how are they synchronized?

This should be resolved before implementation, and I agree with the refinement:

- there should be no separate `{entity}_external_id` column family,
- the table-level stable identifier should be `{entity}_uuid`,
- existing UUID columns in SEAD should be reused rather than paralleled.

For user data, the most coherent rule is:

- if the provider supplies a UUID and SEAD accepts it, use that UUID,
- otherwise mint the UUID in SEAD,
- in the long term, providers may be required to supply UUIDs.

That is a cleaner direction than introducing another external-id column set. It also means the real design question shifts from column naming to governance:

- when is a provider UUID accepted as the SEAD UUID,
- when is a SEAD UUID minted instead,
- and how are remote identifiers retained in the identity system when they are not promoted into SEAD itself.

### 3. The design still conflates several different identity notions

The documents currently blur together:

- the SEAD integer primary key,
- the SEAD UUID identity,
- business or natural keys,
- provider-side internal or external keys,
- third-party authority identifiers.

Those are not necessarily the same thing.

This is the most important design issue still unresolved.

In particular:

- a provider UUID may be acceptable as the stable SEAD UUID in some cases,
- but the design must say when that is allowed,
- and it must still handle cases where multiple provider identities or authority identifiers point at the same SEAD entity.

If multiple providers can point at the same underlying entity, then SEAD needs a stable identity of its own, and provider identifiers should be treated as aliases or mappings to that identity.

The clearest next step is to define the terms explicitly. A good working vocabulary is:

- **SEAD internal identity**: the current serial or sequence-backed primary key, entity-scoped, relational, never exposed as the public identity.
- **SEAD universal identity**: the new UUID identity, exposed externally and accepted externally, globally scoped.
- **Business keys**: combinations of fields that uniquely identify an entity in practice, often used for reconciliation. These are natural keys and must be defined per entity type.
- **Remote-system keys**: the provider's own internal, external, or business identifiers. These should generally live in the identity system rather than directly in SEAD tables.
- **Authority keys**: identifiers from external authority systems such as Wikidata, GeoNames, or domain ontologies. These are especially valuable because they can greatly improve reconciliation quality.

This terminology is more precise than the current drafts and better reflects the actual problem space.

### 4. Update semantics are still underspecified

The intended behavior is clear at a high level:

- entity rows are updated,
- children are replaced.

But the current drafts do not yet define this precisely enough to implement safely.

The missing pieces are:

- which tables are aggregate roots,
- which tables are owned child value objects,
- which tables are associations rather than owned children,
- what exactly counts as the aggregate payload for hashing and change detection,
- what replacement means operationally: delete-all-and-reinsert, soft replace, versioned replace, or diff-based replace.

Without this, the identity model is correct in principle but incomplete in execution terms.

I agree with the conclusion here: this work should be completed before implementation planning resumes.

At this stage, stashing the implementation plan is the right move. The project should focus first on:

- the system design,
- the SEAD entity model,
- the aggregate model,
- ownership versus association,
- and reconciliation rules for shared metadata.

### 5. Content-hash based change detection is still only a placeholder

Storing `content_hash` is a useful idea, but the current design does not yet define the critical rule that makes hashes trustworthy:

**What is the canonical serialized representation of an aggregate?**

Until that is specified, hashes are not stable enough to drive updates.

For example, the design still needs rules for:

- ordering of child rows,
- null normalization,
- whitespace normalization,
- excluded metadata fields,
- whether associations like location links are inside or outside the aggregate boundary.

This also supports the decision to postpone implementation planning. Until aggregate serialization is formally defined, the hashing part of the design is still conceptual.

### 6. The aggregate model may be slightly over-engineered for the current maturity level

The generic aggregate metadata model is well thought through, but it may be ahead of the more fundamental design decisions.

Tables such as:

- `entity_types`
- `aggregate_definitions`
- `entity_dependencies`

are useful, but they only help once the aggregate boundaries are settled against the real SEAD schema.

Right now, the design still needs clarification on the domain model itself. Until that is stable, metadata-driven orchestration may add complexity earlier than necessary.

### 7. The implementation/NFR drafts are more mature than the domain model

The SIMS documentation includes detailed operational targets, infrastructure choices, and API/security patterns. That is good work, but the design maturity is uneven.

The domain questions are still more urgent than the operational ones.

For example, targets like:

- very high throughput,
- replica strategies,
- OAuth flows,
- bulk API performance goals

are secondary until the system clearly defines what constitutes an entity identity, an aggregate, an owned child, and an update.

This is not wrong, but it indicates the design effort is currently slightly inverted.

I would therefore explicitly recommend that the implementation plan be treated as **parked** until:

- the SEAD entity model is defined,
- the aggregate model is revised against the real schema,
- metadata versus provider data is modeled explicitly,
- and the identity vocabulary is fixed.

---

## Schema-Based Observations That Should Influence The Design

### 1. Site and location are associated, not strictly nested

The current schema uses `tbl_site_locations` as a join table.

That means:

- `location` should probably not be modeled as a strict parent aggregate of `site`,
- instead, `site` and `location` may need separate identities with an association between them,
- or the model must explicitly explain why one is treated as primary despite the relational structure.

This is a significant modeling issue, not a minor documentation detail.

### 2. Shared metadata and classifiers need their own design treatment

The system also needs a stronger distinction between:

- provider-owned data,
- shared metadata,
- common classifiers,
- and authority-linked reference structures.

This matters because a large part of SEAD's value lies in common classifiers that support cross-dataset comparison. That means the identity system cannot only think in terms of provider-owned aggregates. It must also support reconciliation against shared SEAD reference structures.

This affects entities such as:

- locations,
- sites,
- bibliographies,
- taxa,
- methods,
- sample types,
- and other classifier-like metadata.

Some of these are entities. Some are metadata. Some are both. The design therefore needs a more nuanced model than a simple “aggregate root versus child value object” split.

### 3. `tbl_analysis_entities` uses `bigint`

The design often speaks in terms of integer identifiers generally, but in the actual DDL:

- `tbl_analysis_entities.analysis_entity_id` is `bigint`

That does not invalidate the approach, but it means the implementation text should avoid being overly specific about `integer` where the schema already varies.

### 4. UUID adoption in SEAD is partial, not uniform

SEAD already contains UUID use in some places, including some tables relevant to this design. That is important because it means:

- the identity-system proposal is not starting from zero,
- there is already precedent for UUID in SEAD,
- migration strategy should reuse that precedent rather than introduce parallel identity columns casually,
- and the canonical table-level public identifier should probably standardize on `{entity}_uuid` rather than a new external-id naming scheme.

### 5. BUGS/CEP proves the need for traceability, but not the final model

The existing `bugs_trace` design is valuable because it demonstrates:

- mappings between external and SEAD rows are necessary,
- update/audit history matters,
- serialized source payloads are useful for trace/debug.

But it is also a warning:

- row-level serialized trace data alone is not a robust aggregate identity model,
- audit logging and identity mapping should not be conflated too tightly,
- the new system should preserve the traceability benefit without inheriting an overly row-centric design.

---

## Upsides Of The Current Direction

If refined, the current design has several strong advantages.

### Upside 1: It solves the real integration problem without breaking SEAD

Keeping existing PKs while adding a stable identity layer is the least disruptive path.

### Upside 2: It supports idempotent ingestion

This is probably the single most valuable operational gain.

### Upside 3: It creates a credible basis for update workflows

The entity/value-object distinction gives a clean conceptual model for updates.

### Upside 4: It supports multiple provider maturity levels

UUID-capable and legacy providers can both participate.

### Upside 5: It is compatible with future change detection and provenance

The allocation table plus content hashes and submission tracking provide a good base for later evolution.

---

## Downsides And Risks In The Current Direction

### Downside 1: Risk of duplicate identity mechanisms

If SEAD keeps existing UUID columns, adds new identity columns, and also keeps a central mapping table, the system may end up with overlapping identity mechanisms unless one is defined as canonical.

### Downside 2: Aggregate boundaries are not settled enough yet

If aggregate boundaries are wrong, update behavior will be wrong.

### Downside 3: Natural keys can become unstable

Natural keys are useful, but only if the design defines:

- provider namespace,
- normalization rules,
- mutability rules,
- collision handling,
- versioning behavior when a business key changes.

### Downside 4: Direct table-level identity mapping can be too rigid

If the identity layer is modeled only as `identifier -> specific SEAD table row`, the system may become harder to evolve when:

- entities migrate across table structures,
- multiple providers refer to one canonical entity,
- one provider changes its own identifiers,
- authority identifiers need to be attached alongside provider identifiers.

### Downside 5: Rollback and identity permanence need clearer rules

The docs mention rollback, but identity allocation and business rollback are different concerns.

The design should decide whether a once-issued identity is:

- never reused,
- invalidated but still reserved,
- or fully removed in some cases.

My recommendation is that issued identities should generally remain immutable and non-reusable, even when business data is withdrawn.

---

## Assessment Of Increased UUID Use

Using UUID more broadly is a good idea, but only if it is done with a clear identity model.

### Where UUID helps

UUID is a good fit for:

- stable public identifiers,
- provider-generated identifiers,
- cross-system references,
- offline allocation,
- long-lived links that must survive integer PK drift.

### Where UUID should not replace integers

I do **not** think the design should replace SEAD primary keys with UUID throughout the schema.

The current proposal is right to keep relational PK/FK structure largely intact.

### The key design question

The critical question is not whether UUID should be used. It should.

The real question is:

**When does a provider UUID become the SEAD UUID, and when must SEAD mint one instead?**

That distinction must be made explicit.

---

## Recommended UUID Strategy

My recommendation is a **two-layer model** for tracked aggregate entities, with explicit room for business keys and authority keys:

### Option A: Minimal model

- Keep SEAD integer PKs as they are.
- Reuse or add one canonical `{entity}_uuid` for each tracked aggregate entity.
- Accept provider UUID where appropriate; otherwise mint the UUID in SEAD.
- Store provider identifiers, business keys, and authority keys in the identity system as mappings or aliases.

This gives SEAD a stable public identity while still accepting robust provider identifiers.

### Why this is better than using provider UUID directly as SEAD identity

Because it keeps the design safe if:

- multiple providers refer to the same entity,
- a provider changes its own identifier policy,
- SEAD merges or reconciles records from different sources,
- authority keys are attached later.

### Practical rule

For each tracked entity, distinguish clearly between:

- `sead_id`: current relational PK in SEAD
- `entity_uuid`: canonical stable SEAD identity for the aggregate
- `business_key`: natural key used for reconciliation
- `provider_keys`: provider-side identities retained in the identity system
- `authority_keys`: external authoritative identifiers when available

This is more explicit than the current proposal, but it fits the problem better.

### If simplicity is the highest priority

If you want the leanest possible first version, then:

- use UUID as the canonical identity for aggregate roots,
- let provider UUID be reused directly when SEAD accepts it,
- mint UUID in SEAD when the provider has none,
- keep a mapping layer for business keys and future aliasing.

That can work, but it should be treated as a deliberate simplification, not as a universally correct model.

---

## What Should Be Clarified Before Implementation

The next design pass should answer these questions explicitly.

### 1. Which SEAD tables are tracked entities?

Produce a final list of aggregate roots grounded in the real DDL, not only in conceptual workflow.

### 2. Which child tables are owned value objects?

For each aggregate, list the child tables that are replaced on update.

### 3. Which relations are associations rather than ownership?

This is especially important for site/location and other cross-cutting relationships.

### 4. What is the canonical SEAD stable identity?

Decide when SEAD accepts a provider UUID as the canonical `{entity}_uuid`, and when SEAD mints its own.

### 5. What is the canonical aggregate serialization for hashing?

Without this, change detection remains conceptual only.

### 6. How should existing UUID columns be treated?

Decide how existing UUID columns like `site_uuid` and `sample_group_uuid` are reused as the canonical table-level UUID fields.

### 7. What are the permanence rules for allocated identities?

Clarify whether rollback affects only submitted business data, or identity allocations as well.

### 8. Which keys stay out of SEAD proper?

Decide which provider-side keys and remote business keys are kept only in the identity system rather than ingested into SEAD tables.

### 9. How are authority keys represented?

Define how identifiers from authority systems such as Wikidata, GeoNames, and domain ontologies are stored and used in reconciliation.

---

## Final Judgement

The current system description is promising and directionally correct.

Its core strengths are:

- correct identification of the real problem,
- a sound aggregate-focused identity strategy,
- pragmatic support for both UUID and natural keys,
- a good architectural boundary between SIMS and Shape Shifter.

Its main weaknesses are:

- incomplete alignment with the real SEAD schema,
- unresolved distinction between canonical SEAD identity and provider identity,
- insufficiently specified update semantics,
- a risk of introducing overlapping identity mechanisms,
- an insufficient distinction between provider data and shared metadata/classifiers.

So the current design should be treated as:

**A strong draft architecture that is ready for refinement, but not yet ready for direct implementation without another round of schema-grounded design clarification.**

I also think it is correct to **stash the implementation plan for now**. The next phase should be design-only work focused on:

- developing the SEAD entity model,
- revising the aggregate model,
- separating provider data from shared metadata and classifiers,
- defining identity terminology,
- and specifying update/reconciliation semantics.

If that design pass succeeds, the later implementation plan will be much smaller, more coherent, and substantially safer to execute.