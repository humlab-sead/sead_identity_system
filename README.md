# SEAD Identity System (Deprecated)

> **This repository is deprecated.** SIMS design documentation and runtime code have moved to [sead_authority_service](https://github.com/humlab-sead/sead_authority_service).
>
> - Design docs: `sead_authority_service/docs/sims/`
> - Runtime code: `sead_authority_service/src/identity/`
> - SQL schema: `sead_authority_service/schema/sql/identity.sql`
>
> This repository is kept as a read-only archive. No further changes will be made here.

---

*Original description:* This project implements the SEAD Identity System. Its purpose is to provide stable links between foreign systems and SEAD while preserving SEAD's existing relational primary keys. The design distinguishes between entities and value objects: stable identity is tracked for entities, while value objects are treated as part of aggregate state.

