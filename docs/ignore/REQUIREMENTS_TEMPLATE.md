Absolutely. For that kind of system, I would avoid a classic FRD/feature catalog and instead use a **requirements pyramid** that moves from **why 
# Table of Contents

## 1. Problem Statement

1.1 Background
1.2 Problem to Be Solved
1.3 Why This Matters
1.4 Consequences of Not Solving It

## 2. Scope

2.1 In Scope
2.2 Out of Scope
2.3 System Boundary
2.4 Relationship to Surrounding Systems

## 3. Goals and Intended Outcomes

3.1 Business Goals
3.2 Operational Goals
3.3 Success Criteria
3.4 Design Principles

## 4. Stakeholders and Actors

4.1 Stakeholders
4.2 User Types and Consumer Types
4.3 External Systems and Dependencies

## 5. Core Concepts and Domain Model

5.1 Key Domain Concepts
5.2 Important Entities
5.3 Relationships Between Entities
5.4 Terms and Definitions

## 6. Capability Model

6.1 Overview of System Capabilities
6.2 Capability Group A
6.3 Capability Group B
6.4 Capability Group C

This section is intentionally phrased in terms of **capabilities**, not endpoints or screens.

## 7. Functional Requirements

7.1 Requirement Structure and Numbering
7.2 Capability Group A Requirements
7.3 Capability Group B Requirements
7.4 Capability Group C Requirements
7.5 Business Rules
7.6 Validation Rules
7.7 Error Conditions and Expected Responses

## 8. Usage Scenarios

8.1 Primary Scenarios
8.2 Alternative Flows
8.3 Edge Cases
8.4 Failure Scenarios

## 9. API Behaviour Overview

9.1 API Style and Interaction Model
9.2 Resource and Operation Patterns
9.3 Request and Response Principles
9.4 Error Handling Principles
9.5 Versioning Principles

This stays above the level of full API spec. The detailed contract can live elsewhere.

## 10. Data Requirements

10.1 Information Managed by the System
10.2 Data Creation and Update Rules
10.3 Data Consistency Rules
10.4 Identity, Uniqueness, and Referential Rules
10.5 Retention and Lifecycle Considerations

## 11. Integration Requirements

11.1 Interactions with Internal Systems
11.2 Interactions with External Systems
11.3 Events, Triggers, or Synchronization Points
11.4 Dependency Assumptions

## 12. Access and Permissions

12.1 Access Contexts
12.2 Roles or Consumer Categories
12.3 Authorization Rules

## 13. Acceptance Structure

13.1 Acceptance Criteria by Capability
13.2 Acceptance Criteria by Scenario
13.3 Traceability to Goals

## 14. Open Issues and Decisions

14.1 Open Questions
14.2 Deferred Decisions
14.3 Assumptions Requiring Validation

## 15. Appendices

15.1 Glossary
15.2 Related Documents
15.3 Change Log

---

## Why this structure works

It gives you the pyramid shape:

* **Problem statement**
* **scope and goals**
* **domain concepts**
* **capabilities**
* **functional requirements**
* **scenarios**
* **API behaviour**

That is a lot healthier than starting with endpoint lists or “the system shall” decomposition too early.

It also separates three things that older RUP-ish structures tend to blur together:

* **why the system exists**
* **what capabilities it must provide**
* **how those capabilities surface through the API**

That separation is especially useful for backend and integration-heavy systems.

## A small wording recommendation

For a modern document, I would seriously consider naming it something like:

* **Requirements Specification**
* **Functional Requirements and Capabilities**
* **System Requirements Overview**

rather than **Functional Requirements Document**, since “FRD” often drags the old style in with it.

## Optional refinement

A very effective variation is to make sections 6 and 7 explicitly hierarchical:

* **Capability**

  * Intent
  * Functional requirements
  * Business rules
  * Acceptance criteria
  * Related scenarios

That keeps each capability self-contained and readable.

I can also give you a **one-page skeleton with sample headings and one-line descriptions for each section** if you want something you can paste directly into a document.
