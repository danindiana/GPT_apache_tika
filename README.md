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

```mermaid
graph LR
    A[GPT_apache_tika/] --> B[README.md]
    A --> C[LICENSE]
    A --> D[scripts/]
    A --> E[docs/]
    A --> F[examples/]

    D --> D1[pdf_txt_tika.sh]

    E --> E1[troubleshooting.md]
    E --> E2[installation.md]
    E --> E3[configuration.md]

    F --> F1[basic-usage.md]
    F --> F2[advanced-parallel.md]

    style A fill:#1976d2,color:#fff
    style D fill:#66bb6a
    style E fill:#ffa726
    style F fill:#ab47bc
```

### Current Files

- **README.md** - This file, main project documentation
- **LICENSE** - Project license (Apache 2.0 or similar)
- **pdf_txt_tika.sh** - Main bash script for parallel PDF processing
- **Oct-16-notes.md** - Historical notes on Tika usage and troubleshooting
- **T6_char.md** - Notes on T6 font character mapping warnings
- **addons/readme.md** - PDFBox warnings and solutions documentation

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
nano pdf_txt_tika.sh

# Set input and output directories
# input_dir="your/input_dir/"
# output_dir="your/output_dir/"

# Run the script
./pdf_txt_tika.sh
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

## Workflow Diagrams

### Git Branching Strategy

```mermaid
gitGraph
    commit id: "Initial commit"
    commit id: "Add LICENSE"
    commit id: "Add pdf_txt_tika.sh script"
    branch feature/documentation
    checkout feature/documentation
    commit id: "Add Oct-16-notes.md"
    commit id: "Add T6_char.md"
    commit id: "Create addons/readme.md"
    checkout main
    merge feature/documentation
    branch claude/add-git-mermaid-diagrams
    checkout claude/add-git-mermaid-diagrams
    commit id: "Restructure documentation"
    commit id: "Add Mermaid diagrams"
    commit id: "Update comprehensive README"
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

### Common Issues and Solutions

#### 1. Unicode Mapping Warnings

**Issue:** `No Unicode mapping for X in font Y`

**Solution:**
- Usually non-critical - check if extracted text is acceptable
- For critical characters, consider font replacement or PDF regeneration
- See [T6_char.md](T6_char.md) for detailed analysis

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
