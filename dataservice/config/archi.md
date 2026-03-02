# Data Export Tool (Iceberg Export Tool) Architecture Design Document

## 1. Overview
This document describes a standalone data export tool that users can invoke via command line or API to extract data from Iceberg tables, process it (cleaning, transformation, masking, encryption, compression), and export it in specified formats (CSV, Excel, JSON, TXT, Word, Table) to target destinations (S3, cloud disk, Email, message queue, database, API, SFTP/FTP, etc.). The tool is designed to be modular, extensible, and configuration-driven for workflow execution.

## 2. Overall Architecture

### 2.1 Architecture Layer Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Client Layer                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │ Command Line │  │   REST API   │  │   Python Library API     │  │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │ Invocation
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Orchestration Engine                         │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │   Workflow Manager (Task lifecycle: Init, Execute, Cleanup)   │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        ▼                           ▼                           ▼
┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐
│   Config Parser   │   │   Core Pipeline   │   │   Monitor & Log   │
│  (YAML/JSON)      │   │ (Extract-Transform│   │ (Metrics, Audit)  │
│  & Validator      │   │  -Format-Send)    │   │                   │
└───────────────────┘   └───────────────────┘   └───────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        ▼                           ▼                           ▼
┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐
│   Source Module   │   │   Processors      │   │   Sink Module     │
│  (Iceberg Reader) │   │ (Clean, Transform,│   │ (Output Connectors│
│                   │   │  Encrypt, Compress│   │   S3, Email, FTP) │
│                   │   │  Split, Format)   │   │                   │
└───────────────────┘   └───────────────────┘   └───────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Common Services                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│  │   Temp File │  │   Retry     │  │   Validation│  │   Metrics   │ │
│  │   Manager   │  │   Handler   │  │   Module    │  │   Collector │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Module Responsibilities

| Module | Responsibility |
|--------|----------------|
| **Client Layer** | Provides user interaction methods: command line, REST API, Python library. Users pass configuration file path or configuration dictionary to trigger export tasks. |
| **Orchestration Engine** | Workflow manager responsible for parsing configuration, assembling processing pipeline, scheduling module execution, handling errors and retries, managing temporary file lifecycle, and collecting monitoring metrics. |
| **Config Parser** | Reads configuration files (YAML/JSON), validates completeness and legality using JSON Schema or Pydantic models, returns standardized configuration object. |
| **Core Pipeline** | Core processing pipeline that executes in sequence: data extraction, data processing, format conversion, encryption/compression, sending to target. |
| **Source Module** | Data source connector, specifically responsible for reading data from Iceberg tables, supporting predicate pushdown, partition pruning, row limits, etc. |
| **Processors** | A series of pluggable data processors: cleaning, field transformation, masking, encryption, compression, splitting, formatting. Each processor implements a unified interface. |
| **Sink Module** | Output target connectors, each target implements a Sink responsible for sending data (byte stream or file) to the specified location. |
| **Common Services** | Cross-cutting concerns: temporary file management, retry mechanism, data validation, metric collection. |
| **Monitor & Log** | Records task execution logs, collects performance metrics, generates task reports, supports output to files or external monitoring systems. |

## 3. Detailed Core Module Design

### 3.1 Configuration Parser and Validation Module

- **Input**: Configuration file path (YAML/JSON) or configuration dictionary.
- **Output**: Standardized `ExportConfig` object.
- **Validation Rules**:
    - Required field checks (source, outputs, etc.).
    - Data type, format, and enum value validation.
    - Dependency checks (e.g., encryption enabled requires key provided).
    - Target-specific field validation (e.g., S3 requires bucket, SFTP requires host, etc.).
- **Design**: Use JSON Schema to define configuration format, or use Pydantic models (supports nesting, custom validators).

Simplified configuration structure:

```
ExportConfig:
  task_id: str
  source:
    type: iceberg
    catalog: str
    database: str
    table: str
    filter: str (optional)
    limit: int (optional)
  processors: list of processor configs
  sinks: list of sink configs
  options:
    temp_dir: str (default /tmp/export)
    temp_retention_hours: int (default 168)
    retry: {...}
    validation: {...}
    monitor: {...}
```

### 3.2 Source Module (Iceberg Reader)

- **Responsibility**: Connect to Iceberg catalog, execute query, return Arrow Table or Pandas DataFrame.
- **Features**:
    - Support predicate pushdown (via filter parameter).
    - Support row limits.
    - Support selecting specific columns.
    - Support partition pruning (implied via filter).
- **Connection Methods**: Via Hive Metastore, Hadoop configuration, or REST Catalog. Connection information obtained from configuration or environment variables.

### 3.3 Processor Pipeline

Processors follow the "Pipes and Filters" pattern, each implementing:

```python
class Processor:
    def process(self, data: DataFrame, context: Context) -> DataFrame:
        # Transform data, return new DataFrame or None (indicating filtering out)
        pass
```

Built-in processors include:
- **Cleaner**: Handle null values, deduplication.
- **Transformer**: Date formatting, column renaming, type conversion.
- **Masker**: Field masking (e.g., phone numbers, emails).
- **Encryptor**: Encrypt specified columns or entire data.
- **Compressor**: Compress data (zip/gzip).
- **Splitter**: Split DataFrame into multiple subsets based on column values.
- **Formatter**: Convert DataFrame to target format (CSV, Excel, etc.) byte stream.

Processor order can be specified in configuration, or automatically ordered logically (e.g., compression usually last).

### 3.4 Output Connector (Sink)

Each Sink implements a unified interface:

```python
class Sink:
    def connect(self) -> bool:
        """Establish connection (if needed)"""
    
    def send(self, data: bytes, metadata: Dict) -> bool:
        """Send data"""
    
    def close(self):
        """Close connection"""
```

Built-in Sinks:
- **LocalFileSink**: Save to local file.
- **S3Sink**: Upload to S3.
- **FTP/SFTPSink**: Upload to FTP/SFTP server.
- **EmailSink**: Send via email.
- **KafkaSink**: Send to Kafka topic.
- **DatabaseSink**: Write to database (MySQL, ES, StarRocks).
- **APISink**: Send via HTTP POST.

### 3.5 Workflow Manager (Orchestration Engine)

The Workflow Manager is the core of the tool, responsible for:
1. **Initialization**: Create temporary directory, load configuration, initialize modules.
2. **Parse Configuration**: Call Config Parser to get configuration object.
3. **Build Pipeline**: Instantiate Source, Processors, Sinks based on configuration.
4. **Execute Pipeline**:
    - Call Source to get data.
    - Call Processors in sequence to process data.
    - If splitting needed, execute subsequent processors for each subset and call Sink for each subset.
    - If no splitting, execute subsequent processors directly and call Sink.
5. **Error Handling & Retry**: Catch exceptions, decide whether to retry current step based on retry policy.
6. **Cleanup**: Delete temporary files, close connections.
7. **Monitoring Report**: Collect execution metrics (duration, row count, size), generate report and output.

### 3.6 Validation Module

- **Purpose**: Perform quality checks during or after data export.
- **Check Items**:
    - Row count validation: Compare actual row count with expected.
    - Null value validation: Critical fields cannot be null.
    - Data type validation: Values match schema.
    - Checksum: File integrity check (e.g., MD5).
- **Implementation**: Validation module can be executed as an optional processor before sending, or as an independent step to check target data after sending (requires target to support reading).

### 3.7 Monitoring Module

- **Functions**:
    - Record task start/end times, duration of each stage.
    - Record processed row count, file sizes.
    - Record errors and warnings.
    - Generate structured logs (JSON format).
- **Output**: Can be written to local log files, or sent to external monitoring systems (e.g., Prometheus, Elasticsearch).

### 3.8 Temporary File Management

- All intermediate files (formatted files, compressed packages) are stored in `temp_dir`, organized by task ID subdirectory.
- File lifecycle controlled by Workflow Manager: automatically deleted after task completion based on `temp_retention_hours`.
- Supports retaining files from the last N hours for troubleshooting.

## 4. Data Flow Diagram (FTP/SFTP Export Example)

```
┌────────────┐     ┌────────────────┐     ┌────────────────┐
│  User      │     │ Config Parser  │     │ Workflow Mgr   │
│  (CLI)     │────▶│                │────▶│                │
└────────────┘     └────────────────┘     └────────────────┘
                                                   │
                                                   │ 1. Get Data
                                                   ▼
                                            ┌────────────┐
                                            │ Iceberg    │
                                            │ Reader     │
                                            └────────────┘
                                                   │ DataFrame
                                                   ▼
                                            ┌────────────────┐
                                            │ Processors     │
                                            │ (Clean, Mask,  │
                                            │  Format)       │
                                            └────────────────┘
                                                   │ bytes
                                                   │ (possibly multiple)
                                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          Splitter?                                    │
│           ┌───────────┐          ┌───────────┐                       │
│           │    No      │          │    Yes    │                       │
│           │(Single File)│         │(Multiple  │                       │
│           │            │          │  Files)   │                       │
│           └─────┬─────┘          └─────┬─────┘                       │
│                 │                       │                             │
│                 ▼                       ▼                             │
│        ┌─────────────────┐     ┌─────────────────┐                   │
│        │ Single Sink Call│     │ Multiple Sink   │                   │
│        │ (FTP)           │     │ Calls (FTP)     │                   │
│        └─────────────────┘     └─────────────────┘                   │
│                 │                       │                             │
│                 └───────────┬───────────┘                             │
│                             ▼                                         │
│                    ┌─────────────────┐                               │
│                    │ FTP Sink        │                               │
│                    │ (upload files)  │                               │
│                    └─────────────────┘                               │
└─────────────────────────────────────────────────────────────────────┘
                                                   │
                                                   ▼
                                            ┌────────────────┐
                                            │ Validation     │
                                            │ (row count)    │
                                            └────────────────┘
                                                   │
                                                   ▼
                                            ┌────────────────┐
                                            │ Monitor & Log  │
                                            │ (report)       │
                                            └────────────────┘
                                                   │
                                                   ▼
                                            ┌────────────────┐
                                            │ Temp Cleanup   │
                                            └────────────────┘
```

## 5. Configuration Example (YAML)

```yaml
task_id: export_iceberg_to_ftp
source:
  type: iceberg
  catalog: my_catalog
  database: sales_db
  table: orders
  filter: "order_date = '2025-03-01'"
  limit: 1000000

processors:
  - type: cleaner
    null_strategy: drop
  - type: mask
    fields: ["customer_email", "phone"]
    mask_char: "*"
    visible_chars: 3
  - type: formatter
    format: csv
    options:
      delimiter: ","
      include_header: true

sinks:
  - type: sftp
    config:
      host: sftp.example.com
      port: 22
      username: "{{ env.SFTP_USER }}"
      password: "{{ env.SFTP_PASS }}"
      remote_path: "/uploads/{{ ds }}/"
      filename: "orders_{{ split_key }}.csv"
    split_by:
      column: region
      conditions:
        north: ["Beijing", "Tianjin"]
        south: ["Shanghai", "Guangzhou"]
    # If no split, upload entire file directly
  - type: email
    config:
      smtp_server: smtp.gmail.com
      port: 587
      use_tls: true
      username: "{{ env.EMAIL_USER }}"
      password: "{{ env.EMAIL_PASS }}"
      from: exporter@example.com
      to: ["data-team@example.com"]
      subject: "Iceberg Export {{ ds }}"
      body: "Export completed, see attachment."
    # Note: Email typically sends single file; can be combined with split_by, but email usually doesn't split

options:
  temp_dir: /tmp/export
  temp_retention_hours: 24
  retry:
    max_attempts: 3
    delay_seconds: 10
    backoff_multiplier: 2
  validation:
    row_count_min: 1000
  monitor:
    log_level: INFO
    metrics_file: /var/log/export_metrics.json
```

## 6. Error Handling and Retry

- **Retry Scope**: Configurable for entire task retry, or only specific steps (e.g., network transmission).
- **Retry Strategy**: Fixed interval, exponential backoff.
- **Idempotency Design**: Sinks should support idempotent operations (e.g., S3 overwrite, FTP overwrite) to avoid duplicate data.
- **Partial Failure Handling**: If multiple files after splitting, allow partial success, record failed files and retry.

## 7. Extensibility Design

- **Add New Source**: Implement `Source` interface (`read()` returns DataFrame).
- **Add New Processor**: Implement `Processor` interface (`process(data, context)`).
- **Add New Sink**: Implement `Sink` interface (`connect()`, `send()`, `close()`), and add corresponding type in configuration.
- **Add New Validator**: Implement `Validator` interface, reference in `validation` configuration.

## 8. Deployment and Usage

Tool packaged as Python package, providing command line entry point:

```bash
export-tool --config export_config.yaml
```

Or called as Python library:

```python
from export_tool import run_export
run_export(config_dict)
```

Supports injecting sensitive information (passwords, keys) through environment variables, using `{{ env.VAR_NAME }}` placeholders in configuration, replaced during parsing.

## 9. Summary

This design provides a standalone, modular data export tool focused on exporting data from Iceberg to various targets. Through clear module separation and extensible interfaces, users can flexibly define complex export tasks. The tool incorporates error handling, monitoring, and validation mechanisms, ensuring task reliability and observability.