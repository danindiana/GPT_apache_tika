# GPT Apache Tika

A comprehensive guide and toolkit for running Apache Tika in parallel to convert PDFs and other documents to text files on Ubuntu systems, with GPT-assisted troubleshooting and optimization.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Workflow Diagrams](#workflow-diagrams)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

This project provides scripts, documentation, and best practices for efficiently processing large batches of PDF files using Apache Tika on Ubuntu 22.04. It leverages parallel processing with GNU Parallel to maximize throughput and includes extensive troubleshooting guides for common issues.

**Key Features:**
- Parallel PDF to text conversion using Apache Tika
- Configurable parallel processing with GNU Parallel
- Progress monitoring and telemetry
- Comprehensive error handling and recovery
- Solutions for common font encoding and Unicode mapping issues

## Architecture

### System Architecture

```mermaid
graph TB
    subgraph "Input Layer"
        A[PDF Files Directory] --> B[File Discovery]
    end

    subgraph "Processing Layer"
        B --> C[GNU Parallel]
        C --> D1[Tika Worker 1]
        C --> D2[Tika Worker 2]
        C --> D3[Tika Worker 3]
        C --> D4[Tika Worker N]

        D1 --> E[Tika Server<br/>Port 9989]
        D2 --> E
        D3 --> E
        D4 --> E
    end

    subgraph "Output Layer"
        E --> F1[Text File 1]
        E --> F2[Text File 2]
        E --> F3[Text File 3]
        E --> F4[Text File N]

        F1 --> G[Output Directory]
        F2 --> G
        F3 --> G
        F4 --> G
    end

    subgraph "Monitoring"
        C --> H[Progress Counter]
        H --> I[Telemetry Display]
    end

    style A fill:#e1f5ff
    style G fill:#e8f5e9
    style E fill:#fff3e0
    style I fill:#f3e5f5
```

### Processing Workflow

```mermaid
flowchart TD
    Start([Start Processing]) --> Init[Initialize Configuration]
    Init --> CheckTika{Tika Server<br/>Running?}

    CheckTika -->|No| StartTika[Start Tika Server]
    CheckTika -->|Yes| FindFiles
    StartTika --> FindFiles[Find PDF Files]

    FindFiles --> CountFiles[Count Total Files]
    CountFiles --> SetParallel[Set Parallel Jobs Count]

    SetParallel --> ProcessLoop{More Files<br/>to Process?}

    ProcessLoop -->|Yes| ValidateFile{Supported<br/>File Type?}
    ProcessLoop -->|No| Complete

    ValidateFile -->|No| Skip[Skip File]
    ValidateFile -->|Yes| SendToTika[Send to Tika Server]

    SendToTika --> TikaProcess{Processing<br/>Success?}

    TikaProcess -->|Yes| SaveText[Save Text Output]
    TikaProcess -->|No| HandleError[Log Error]

    SaveText --> UpdateCounter[Update Progress Counter]
    HandleError --> UpdateCounter
    Skip --> ProcessLoop

    UpdateCounter --> DisplayProgress[Display Progress]
    DisplayProgress --> ProcessLoop

    Complete([Processing Complete])

    style Start fill:#4caf50,color:#fff
    style Complete fill:#4caf50,color:#fff
    style HandleError fill:#f44336,color:#fff
    style TikaProcess fill:#ff9800
    style SendToTika fill:#2196f3,color:#fff
```

### Error Handling Flow

```mermaid
flowchart TD
    Error([Error Detected]) --> Type{Error Type}

    Type -->|Unicode Mapping| Unicode[Font Unicode Mapping Issue]
    Type -->|JPEG2000| JPEG[JAI Image I/O Missing]
    Type -->|Server| Server[Tika Server Error]
    Type -->|File| File[File Access Error]

    Unicode --> UnicodeCheck{Critical<br/>Character?}
    UnicodeCheck -->|Yes| FontReplace[Font Replacement]
    UnicodeCheck -->|No| Ignore1[Log Warning & Continue]

    JPEG --> InstallJAI[Install JAI Image I/O Tools]
    InstallJAI --> UpdateClasspath[Update Classpath]

    Server --> RestartServer{Server<br/>Responsive?}
    RestartServer -->|No| KillRestart[Kill & Restart Server]
    RestartServer -->|Yes| RetryRequest[Retry Request]

    File --> CheckPerm{Permission<br/>Issue?}
    CheckPerm -->|Yes| FixPerm[Fix Permissions]
    CheckPerm -->|No| SkipFile[Skip File & Log]

    FontReplace --> Resume([Resume Processing])
    Ignore1 --> Resume
    UpdateClasspath --> Resume
    RetryRequest --> Resume
    KillRestart --> Resume
    FixPerm --> Resume
    SkipFile --> Resume

    style Error fill:#f44336,color:#fff
    style Resume fill:#4caf50,color:#fff
    style InstallJAI fill:#2196f3,color:#fff
    style FontReplace fill:#2196f3,color:#fff
```

## Repository Structure

### Current Directory Tree

```mermaid
graph TB
    A[GPT_apache_tika/] --> B[README.md]
    A --> C[LICENSE]
    A --> D[scripts/]
    A --> E[docs/]
    A --> F[examples/]

    D --> D1[pdf_txt_tika.sh]

    E --> E1[troubleshooting/]
    E1 --> E2[tika-usage-notes.md]
    E1 --> E3[font-mapping-issues.md]
    E1 --> E4[pdfbox-warnings.md]

    F --> F1[basic-usage.md]
    F --> F2[advanced-parallel.md]

    style A fill:#1976d2,color:#fff
    style D fill:#66bb6a
    style E fill:#ffa726
    style F fill:#ab47bc
    style E1 fill:#ef5350
```

### Repository File Organization

```mermaid
mindmap
  root((GPT Apache Tika))
    Documentation
      README.md
      LICENSE
      Troubleshooting Docs
        Tika Usage Notes
        Font Mapping Issues
        PDFBox Warnings
    Scripts
      pdf_txt_tika.sh
        Parallel Processing
        Telemetry
        Error Handling
    Examples
      Basic Usage
        Single File
        Metadata
        Detection
      Advanced Parallel
        GNU Parallel
        Tika Server
        Performance
```

### File Descriptions

| Directory | File | Description |
|-----------|------|-------------|
| `/` | README.md | Main project documentation with architecture diagrams |
| `/` | LICENSE | Project license information |
| `/scripts/` | pdf_txt_tika.sh | Main bash script for parallel PDF processing with telemetry |
| `/docs/troubleshooting/` | tika-usage-notes.md | Historical notes on Tika usage and troubleshooting |
| `/docs/troubleshooting/` | font-mapping-issues.md | Notes on font character mapping warnings (T6, etc.) |
| `/docs/troubleshooting/` | pdfbox-warnings.md | PDFBox warnings, solutions, and OCR configuration |
| `/examples/` | basic-usage.md | Simple examples for single-file processing |
| `/examples/` | advanced-parallel.md | Advanced parallel processing techniques |

## Prerequisites

- Ubuntu 22.04 (or similar Debian-based Linux distribution)
- Java Runtime Environment (JRE) 8 or higher
- Apache Tika 2.9.1 or later
- GNU Parallel
- curl
- Sufficient disk space for output files

## Installation

### 1. Install Java

```bash
sudo apt update
sudo apt install default-jre
java -version
```

### 2. Install Apache Tika

**Option A: Using apt (recommended for standard use):**

```bash
sudo apt update
sudo apt install apache-tika
```

**Option B: Manual installation (for specific versions):**

```bash
# Download Tika
wget https://archive.apache.org/dist/tika/2.9.1/tika-app-2.9.1.jar

# Make it executable
chmod +x tika-app-2.9.1.jar

# Optional: Move to a standard location
sudo mkdir -p /opt/tika
sudo mv tika-app-2.9.1.jar /opt/tika/
```

### 3. Install GNU Parallel

```bash
sudo apt update
sudo apt install parallel
```

### 4. Install JAI Image I/O Tools (for JPEG2000 support)

**Option A: Maven project:**

Add to your `pom.xml`:

```xml
<dependency>
    <groupId>com.github.jai-imageio</groupId>
    <artifactId>jai-imageio-core</artifactId>
    <version>1.4.0</version>
</dependency>
<dependency>
    <groupId>com.github.jai-imageio</groupId>
    <artifactId>jai-imageio-jpeg2000</artifactId>
    <version>1.4.0</version>
</dependency>
```

**Option B: Manual installation:**

```bash
# Download JAR files and add to classpath when running Tika
java -cp 'tika-app-2.9.1.jar:jai-imageio-core-1.4.0.jar:jai-imageio-jpeg2000-1.4.0.jar' \
    org.apache.tika.cli.TikaCLI -t input.pdf > output.txt
```

## Usage

### Quick Start

For detailed usage examples, see:
- **[Basic Usage Guide](examples/basic-usage.md)** - Single file processing, metadata extraction, format conversion
- **[Advanced Parallel Processing](examples/advanced-parallel.md)** - GNU Parallel techniques, performance optimization, error handling

### Basic Usage

**Single file conversion:**

```bash
java -jar tika-app-2.9.1.jar -t input.pdf > output.txt
```

**Extract metadata:**

```bash
java -jar tika-app-2.9.1.jar -m input.pdf
```

### Parallel Processing

**Using the provided script:**

```bash
# Edit the script to configure directories
nano scripts/pdf_txt_tika.sh

# Set input and output directories
# input_dir="your/input_dir/"
# output_dir="your/output_dir/"

# Run the script
./scripts/pdf_txt_tika.sh
```

**Manual parallel processing:**

```bash
# Basic parallel conversion
find /path/to/pdfs/ -name "*.pdf" | \
    parallel "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"

# With specific number of jobs (4 CPU cores)
find /path/to/pdfs/ -name "*.pdf" | \
    parallel -j 4 "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"

# With progress bar
find /path/to/pdfs/ -name "*.pdf" | \
    parallel -j 4 --bar "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"

# Save to specific output directory
find /path/to/pdfs/ -name "*.pdf" | \
    parallel -j 4 "java -jar tika-app-2.9.1.jar -t {} > /output/dir/{/.}.txt"
```

For more advanced parallel processing techniques, see [Advanced Parallel Processing Guide](examples/advanced-parallel.md).

### Using Tika Server

**Start the server:**

```bash
java -jar tika-app-2.9.1.jar --server --port 9989
```

**Send files using curl:**

```bash
curl -T input.pdf http://localhost:9989/tika > output.txt
```

### Advanced Options

**Increase Java heap size for large files:**

```bash
java -Xmx4g -jar tika-app-2.9.1.jar -t large-file.pdf > output.txt
```

**Extract text from main content only:**

```bash
java -jar tika-app-2.9.1.jar -T input.pdf > output.txt
```

**Output in JSON format:**

```bash
java -jar tika-app-2.9.1.jar -j input.pdf > output.json
```

## Git Repository Diagrams

### Repository Evolution Timeline

```mermaid
timeline
    title GPT Apache Tika - Repository Evolution
    section Foundation
        Initial Commit : Created repository structure
                      : Added LICENSE file
    section Core Script
        PDF Processing : Added pdf_txt_tika.sh script
                      : Implemented parallel processing
                      : Added telemetry support
    section Documentation Phase 1
        Usage Notes : Created Oct-16-notes.md
                   : Documented Tika commands
                   : Added troubleshooting tips
        Font Issues : Created T6_char.md
                   : Documented Unicode mapping warnings
        PDFBox Warnings : Created addons/readme.md
                       : Addressed JPEG2000 errors
                       : Added Tesseract OCR config
    section Documentation Phase 2
        Structure Improvement : Reorganized files into directories
                             : Created docs/troubleshooting/
                             : Created scripts/ and examples/
        Enhanced README : Added Mermaid diagrams
                       : Created architecture visualizations
                       : Added comprehensive workflows
        Examples : Added basic-usage.md
                : Added advanced-parallel.md
```

### Git Commit History Visualization

```mermaid
gitGraph
    commit id: "Initial commit"
    commit id: "Add LICENSE"
    commit id: "Add pdf_txt_tika.sh script"
    commit id: "Create Oct-16-notes.md"
    commit id: "Create T6_char.md"
    commit id: "Create readme.md"
    branch claude/add-git-mermaid-diagrams-01G4wBuQoFm6xdDPcvAbgiRc
    checkout claude/add-git-mermaid-diagrams-01G4wBuQoFm6xdDPcvAbgiRc
    commit id: "Add comprehensive README with Mermaid diagrams"
    checkout main
    merge claude/add-git-mermaid-diagrams-01G4wBuQoFm6xdDPcvAbgiRc tag: "v1.0"
    branch claude/add-git-mermaid-diagrams-01V6BsDnTF7F6UkYvL91z9vE
    checkout claude/add-git-mermaid-diagrams-01V6BsDnTF7F6UkYvL91z9vE
    commit id: "Reorganize repository structure"
    commit id: "Add git-focused Mermaid diagrams"
    commit id: "Create examples and enhanced docs"
```

### Contribution Workflow

```mermaid
graph TB
    Start([New Contribution]) --> Fork{Fork or<br/>Clone?}

    Fork -->|Fork| ForkRepo[Fork Repository on GitHub]
    Fork -->|Direct Access| CloneRepo[Clone Repository]

    ForkRepo --> CloneForked[Clone Forked Repo Locally]
    CloneForked --> CreateBranch
    CloneRepo --> CreateBranch[Create Feature Branch<br/>claude/feature-name-sessionID]

    CreateBranch --> MakeChanges[Make Code Changes]
    MakeChanges --> LocalTest[Test Locally]

    LocalTest --> TestPass{Tests Pass?}
    TestPass -->|No| FixIssues[Fix Issues]
    FixIssues --> LocalTest

    TestPass -->|Yes| StageChanges[Stage Changes<br/>git add .]
    StageChanges --> Commit[Commit with Message<br/>git commit -m "..."]

    Commit --> MoreChanges{More Changes<br/>Needed?}
    MoreChanges -->|Yes| MakeChanges
    MoreChanges -->|No| Push[Push to Remote<br/>git push -u origin branch]

    Push --> CreatePR[Create Pull Request]
    CreatePR --> CodeReview[Code Review]

    CodeReview --> ReviewResult{Review<br/>Approved?}
    ReviewResult -->|Changes Requested| AddressComments[Address Comments]
    AddressComments --> MakeChanges

    ReviewResult -->|Approved| MergePR[Merge Pull Request]
    MergePR --> DeleteBranch[Delete Feature Branch]
    DeleteBranch --> End([Contribution Complete])

    style Start fill:#4caf50,color:#fff
    style End fill:#4caf50,color:#fff
    style CreatePR fill:#2196f3,color:#fff
    style MergePR fill:#ff9800,color:#fff
```

### Pull Request Workflow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Local as Local Branch
    participant Remote as Remote Branch
    participant GH as GitHub
    participant Review as Reviewers
    participant Main as Main Branch

    Dev->>Local: Create feature branch
    Dev->>Local: Make changes
    Dev->>Local: Commit changes
    Dev->>Local: Run local tests

    Dev->>Remote: Push branch
    Dev->>GH: Create pull request

    GH->>Review: Notify reviewers
    Review->>GH: Review code

    alt Changes Requested
        Review->>Dev: Request changes
        Dev->>Local: Make updates
        Dev->>Local: Commit fixes
        Dev->>Remote: Push updates
        Remote->>GH: Update PR automatically
        GH->>Review: Notify of updates
        Review->>GH: Re-review
    end

    Review->>GH: Approve PR

    alt Merge Conflicts
        GH->>Dev: Report conflicts
        Dev->>Local: Resolve conflicts
        Dev->>Local: Commit resolution
        Dev->>Remote: Push resolution
    end

    GH->>Main: Merge PR
    GH->>Dev: Close PR
    Main->>GH: Trigger CI/CD (if configured)

    Dev->>Local: Delete feature branch
    Dev->>Remote: Delete remote branch
```

### Branch Management Strategy

```mermaid
graph LR
    Main[Main Branch<br/>Production Ready] --> Feature1[claude/feature-A<br/>sessionID-1]
    Main --> Feature2[claude/feature-B<br/>sessionID-2]
    Main --> Feature3[claude/bugfix-C<br/>sessionID-3]

    Feature1 --> PR1[Pull Request #1]
    Feature2 --> PR2[Pull Request #2]
    Feature3 --> PR3[Pull Request #3]

    PR1 --> Review1{Code Review}
    PR2 --> Review2{Code Review}
    PR3 --> Review3{Code Review}

    Review1 -->|Approved| Merge1[Merge to Main]
    Review2 -->|Approved| Merge2[Merge to Main]
    Review3 -->|Approved| Merge3[Merge to Main]

    Review1 -->|Changes Needed| Feature1
    Review2 -->|Changes Needed| Feature2
    Review3 -->|Changes Needed| Feature3

    Merge1 --> Main
    Merge2 --> Main
    Merge3 --> Main

    style Main fill:#4caf50,color:#fff
    style PR1 fill:#2196f3,color:#fff
    style PR2 fill:#2196f3,color:#fff
    style PR3 fill:#2196f3,color:#fff
```

### File Processing State Machine

```mermaid
stateDiagram-v2
    [*] --> Discovered: Find PDF files

    Discovered --> Queued: Add to processing queue
    Queued --> Validating: Check file type

    Validating --> Skipped: Unsupported type
    Validating --> Processing: Supported PDF

    Processing --> TikaServer: Send to Tika
    TikaServer --> Extracting: Parse PDF content

    Extracting --> Success: Text extracted
    Extracting --> Warning: Non-critical errors
    Extracting --> Error: Critical error

    Warning --> Success: Continue with warnings

    Success --> Saving: Write to text file
    Saving --> Completed: File saved

    Error --> Retry: Retry with options
    Error --> Failed: Max retries exceeded

    Retry --> Processing: Try again

    Completed --> [*]
    Skipped --> [*]
    Failed --> [*]

    note right of Warning
        Font mapping warnings,
        JPEG2000 issues,
        Minor encoding problems
    end note

    note right of Error
        Server timeout,
        Out of memory,
        Corrupted PDF
    end note
```

## Workflow Diagrams

### System Architecture

```mermaid
graph TB
    subgraph "Input Layer"
        A[PDF Files Directory] --> B[File Discovery]
    end

    subgraph "Processing Layer"
        B --> C[GNU Parallel]
        C --> D1[Tika Worker 1]
        C --> D2[Tika Worker 2]
        C --> D3[Tika Worker 3]
        C --> D4[Tika Worker N]

        D1 --> E[Tika Server<br/>Port 9989]
        D2 --> E
        D3 --> E
        D4 --> E
    end

    subgraph "Output Layer"
        E --> F1[Text File 1]
        E --> F2[Text File 2]
        E --> F3[Text File 3]
        E --> F4[Text File N]

        F1 --> G[Output Directory]
        F2 --> G
        F3 --> G
        F4 --> G
    end

    subgraph "Monitoring"
        C --> H[Progress Counter]
        H --> I[Telemetry Display]
    end

    style A fill:#e1f5ff
    style G fill:#e8f5e9
    style E fill:#fff3e0
    style I fill:#f3e5f5
```

### Development Workflow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Local as Local Repo
    participant Branch as Feature Branch
    participant Main as Main Branch
    participant CI as CI/CD

    Dev->>Local: Clone repository
    Dev->>Branch: Create feature branch
    Dev->>Branch: Make changes
    Dev->>Branch: Commit changes
    Dev->>Branch: Test locally

    alt Tests Pass
        Dev->>Branch: Push to remote
        Branch->>CI: Trigger CI pipeline
        CI->>CI: Run tests
        CI->>CI: Run linters

        alt CI Success
            Branch->>Main: Create pull request
            Main->>Main: Code review
            Main->>Main: Merge to main
        else CI Failure
            CI-->>Dev: Report errors
            Dev->>Branch: Fix issues
        end
    else Tests Fail
        Dev->>Branch: Fix issues locally
    end
```

## Troubleshooting

For comprehensive troubleshooting guides, see:
- **[Tika Usage Notes](docs/troubleshooting/tika-usage-notes.md)** - Historical notes and command reference
- **[Font Mapping Issues](docs/troubleshooting/font-mapping-issues.md)** - Unicode mapping warnings
- **[PDFBox Warnings](docs/troubleshooting/pdfbox-warnings.md)** - JPEG2000, Tesseract OCR configuration

### Common Issues and Solutions

#### 1. Unicode Mapping Warnings

**Issue:** `No Unicode mapping for X in font Y`

**Solution:**
- Usually non-critical - check if extracted text is acceptable
- For critical characters, consider font replacement or PDF regeneration
- See [Font Mapping Issues Guide](docs/troubleshooting/font-mapping-issues.md) for detailed analysis

#### 2. JPEG2000 Image Errors

**Issue:** `Cannot read JPEG2000 image: Java Advanced Imaging (JAI) Image I/O Tools are not installed`

**Solution:**
```bash
# Install JAI Image I/O Tools (see Installation section)
# Update classpath when running Tika
java -cp 'tika-app-2.9.1.jar:jai-imageio-core-1.4.0.jar:jai-imageio-jpeg2000-1.4.0.jar' \
    org.apache.tika.cli.TikaCLI -t input.pdf > output.txt
```

#### 3. Out of Memory Errors

**Issue:** `OutOfMemoryError` when processing large PDFs

**Solution:**
```bash
# Increase Java heap size
java -Xmx4g -jar tika-app-2.9.1.jar -t large-file.pdf > output.txt

# For very large files, consider increasing even more
java -Xmx8g -jar tika-app-2.9.1.jar -t very-large-file.pdf > output.txt
```

#### 4. Character Encoding Issues

**Issue:** Extracted text contains garbled characters

**Solution:**
```bash
# Specify output encoding
java -jar tika-app-2.9.1.jar -t -eUTF-8 input.pdf > output.txt
```

#### 5. Tika Server Not Responding

**Issue:** Server hangs or doesn't respond

**Solution:**
```bash
# Kill the server process
pkill -f "tika-app.*--server"

# Restart with increased timeout
java -jar tika-app-2.9.1.jar --server --port 9989 -timeout=300000
```

### Performance Optimization

**Optimal parallel jobs:**
```bash
# Use number of CPU cores
nproc  # Check your CPU count
find . -name "*.pdf" | parallel -j $(nproc) "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"
```

**Monitor system resources:**
```bash
# While processing, monitor in another terminal
htop
# or
watch -n 1 "ps aux | grep tika"
```

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for:
- Bug fixes
- Performance improvements
- Documentation enhancements
- New features or scripts
- Troubleshooting solutions

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

## Additional Resources

- [Apache Tika Official Documentation](https://tika.apache.org/)
- [GNU Parallel Tutorial](https://www.gnu.org/software/parallel/parallel_tutorial.html)
- [PDFBox Documentation](https://pdfbox.apache.org/)

---

**Project maintained by:** GPT-assisted development
**Last updated:** 2025-11-14
