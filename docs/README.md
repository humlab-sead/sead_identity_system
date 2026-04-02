# SIMS Proposal Docs

This folder contains the proposal for **SIMS**: the SEAD Identity Management System.

SIMS is a separate SEAD-side system. It does not live inside Shape Shifter. The Shape Shifter SEAD ingester depends on SIMS through API calls for identity allocation and related lookup workflows.

## Documents

- [DESIGN_VIEW.md](./DESIGN_VIEW.md)
  Concise system design view.

- [REQUIREMENTS.md](./REQUIREMENTS.md)
  Functional view of what the system must do.

- [ASSESSMENT.md](./ASSESSMENT.md)
  Design assessment, strengths, weaknesses, and open issues.

- [TRACKED_ENTITIES.md](./TRACKED_ENTITIES.md)
  Entity register: enumeration, aggregate boundaries, associations, reconciliation strategies, and business keys.

- [IMPLEMENTATION_VIEW.md](./IMPLEMENTATION_VIEW.md)
  Implementation structures, storage design, and rollout strategy.

## Boundary To Shape Shifter

- SIMS owns identity allocation, identity mappings, and the long-term basis for change detection.
- Shape Shifter owns normalization, reconciliation inputs, API client behavior, and SQL generation.
- The ingester should treat SIMS as an external dependency with a stable API contract.
