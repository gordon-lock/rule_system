# Big-Data Quality Management System (BDQM)
## Product Requirements Document (PRD)
**Version:** v1.0
**Author:** Big-Data Product Team
**Last Update:** 2025-07-24

---

## 1. Purpose
Provide an actionable, measurable and extensible system that guarantees **accuracy, completeness, consistency, timeliness, uniqueness and auditability** of data before, during and after ingestion into the warehouse / lake / real-time pipeline, reducing business loss and decision bias caused by poor data quality.

---

## 2. Glossary
| Term | Description |
|---|---|
| DQ | Data Quality |
| SLA | Service-Level Agreement |
| DQC | Data Quality Check rule |
| SLO | Service-Level Objective (e.g., 99.9 % table-level check pass rate) |
| DLP | Data Lineage & Provenance |
| Golden Dataset | Benchmark high-quality dataset used for regression testing |

---

## 3. Background & Pain Points
- **Offline T+1**: schema drift in upstream source causes field mis-alignment and exploding NULLs.
- **Real-time**: dirty Kafka JSON (missing keys, out-of-range numbers) lands in ClickHouse → broken BI dashboards.
- **No unified metrics**; every team writes its own scripts.
- **Late discovery**: 48 h average MTTD (mean time to detection).
- **No closed loop**: repair rate only 60 %.

---

## 4. Goals & Key Results (OKRs)

| Objective | Key Result |
|---|---|
| O1 – Reduce MTTD for critical tables to < 2 h within 6 months | KR1.1 All Top-200 tables covered by real-time DQC, alert within 5 min. |
|  | KR1.2 90 % tickets closed within 24 h. |
| O2 – Cut business incidents caused by DQ issues from 5 / month to < 1 / month within 12 months | — |

---

## 5. Personas
1. **DQ Engineer (DQE)** – configures rules, monitors reports, tracks tickets.
2. **Data Engineer** – embeds checks in CI/CD pipelines.
3. **Data Analyst / BI** – consumes quality scores in Superset.
4. **Platform Ops** – watches cluster resources, SLA attainment.
5. **CDO / Management** – views global quality dashboard.

---

## 6. Scope
**In Scope**
- Offline (Hive/Spark), real-time (Kafka/Flink), semi-structured (Mongo, APIs).
- Rule definition, scheduling, execution, alerting, scoring, closed-loop.
- Metadata, lineage, impact analysis, permissions, audit logs.

**Out of Scope**
- Automated data repair (only suggests & tracks).
- Unstructured (image, audio) quality checks.

---

## 7. Functional Requirements

### 7.1 Rule Center
| ID | Requirement |
|---|---|
| FR-1 | **Rule Templates** – 20+ built-ins (null-rate, uniqueness, enum range, numeric range, regex, record count delta, PK duplicates, FK referential integrity, JSON schema, lag threshold). Support Groovy/SQL/Python UDF custom logic. |
| FR-2 | **Rule Lifecycle** – Draft → Test → Published → Deprecated. Versioned; diff view; 10 % gray rollout. |

### 7.2 Task Scheduling & Execution Engine
| ID | Requirement |
|---|---|
| FR-3 | **Multi-engine adapters** – Spark SQL/Scala on YARN/K8s; Flink CEP/SQL; lightweight Presto/Trino probes. |
| FR-4 | **Scheduling strategies** – cron, Airflow DAG, event-driven (Kafka new partition, HMS alter event). Auto skip if upstream ETL not ready. |

### 7.3 Data Sampling & Metrics
| ID | Requirement |
|---|---|
| FR-5 | **Sampling** – full, fixed rows, percentage, time-window; stratified by business line / region. |
| FR-6 | **Metrics algorithms**<br>Accuracy: hash diff vs Golden Dataset.<br>Completeness: null / missing column rate.<br>Consistency: cross-table join consistency, aggregation match.<br>Timeliness: event_time–ingest_time delta.<br>Uniqueness: PK / business-key duplicate rate.<br>Auditability: field & permission change log. |

### 7.4 Scoring Model
| ID | Requirement |
|---|---|
| FR-7 | **Table-level score** (0-100) = Σ wᵢ·metricᵢ; weights configurable per table. Auto downgrades tables < 80. |
| FR-8 | **Column-level drill-down** to pinpoint root cause. |

### 7.5 Alerting & Notification
| ID | Requirement |
|---|---|
| FR-9 | **Tiered alerts** – P0 (call/SMS/Feishu), P1 (Feishu @owner), P2 (email digest). |
| FR-10 | **Templated messages** via Jinja2, embed table / partition / sample values. |

### 7.6 Issue Ticketing
| ID | Requirement |
|---|---|
| FR-11 | **Auto ticket creation** – rule trigger → Jira/Feishu sheet with table, partition, sample rows (masked), lineage upstream, suggested fix SQL. |
| FR-12 | **State flow** – To Do → In Progress → Verified → Closed. Links to code MR; auto back-fills fix version. |

### 7.7 Data Lineage & Impact
| ID | Requirement |
|---|---|
| FR-13 | **Parsing** – Hive SQL, Spark SQL, Flink SQL, Airflow DAGs → column-level lineage; downstream impact list. |

### 7.8 Permissions & Audit
| ID | Requirement |
|---|---|
| FR-14 | **Fine-grained RBAC** – rule view/edit, job start/stop, alert config, Golden Dataset management down to table/column level. Audit log 180 days, immutable bucket. |

### 7.9 Open APIs
| ID | Requirement |
|---|---|
| FR-15 | **RESTful** `/rules`, `/jobs`, `/scores`, `/alerts`, `/tickets`; OpenAPI 3.0 spec; auto-generated SDKs (Java/Python). |
| FR-16 | **Webhook** push to external SOAR platforms. |

---

## 8. Non-Functional Requirements

| Category | Target |
|---|---|
| **Performance** | 1 TB offline table ≤ 15 min (10-node Spark). Real-time rule latency ≤ 2 min (Flink 30 s checkpoint). |
| **Availability** | 99.9 % uptime; automatic retry ×3, then dead-letter queue. |
| **Scalability** | 10 000+ rules, 1 000 concurrent jobs. |
| **Security** | TLS 1.3, AES-256 at rest; PII masking in samples. |
| **Multi-tenancy** | Namespace isolation, CPU/Mem/IO quotas. |

---

## 9. Architecture

### 9.1 Logical View  