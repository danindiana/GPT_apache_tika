# Advanced Parallel Processing Examples

This guide demonstrates advanced techniques for processing multiple PDF files in parallel using GNU Parallel and Apache Tika.

## Basic Parallel Processing

Process all PDFs in a directory with default parallelism:

```bash
find /path/to/pdfs/ -name "*.pdf" | parallel "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"
```

## Specify Number of Parallel Jobs

Use 4 CPU cores for parallel processing:

```bash
find /path/to/pdfs/ -name "*.pdf" | parallel -j 4 "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"
```

## Auto-detect CPU Cores

Automatically use all available CPU cores:

```bash
find /path/to/pdfs/ -name "*.pdf" | parallel -j $(nproc) "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"
```

## With Progress Bar

Show a progress bar during processing:

```bash
find /path/to/pdfs/ -name "*.pdf" | parallel -j 4 --bar "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"
```

## Save to Specific Output Directory

Save all converted text files to a specific directory:

```bash
find /path/to/pdfs/ -name "*.pdf" | parallel -j 4 "java -jar tika-app-2.9.1.jar -t {} > /output/dir/{/.}.txt"
```

## Error Handling

Stop processing if 2 jobs fail:

```bash
find /path/to/pdfs/ -name "*.pdf" | parallel -j 4 --halt 2 "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"
```

## With Logging

Create a log file for each processed PDF:

```bash
find /path/to/pdfs/ -name "*.pdf" | parallel -j 4 "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt 2> {/.}.log"
```

## Using Tika Server

Start Tika server and use curl for parallel processing:

```bash
# Start server (in separate terminal)
java -jar tika-app-2.9.1.jar --server --port 9989

# Process files in parallel using curl
find /path/to/pdfs/ -name "*.pdf" | parallel -j 8 "curl -T {} http://localhost:9989/tika > {/.}.txt"
```

## Resume Failed Jobs

Create a job log and resume if interrupted:

```bash
find /path/to/pdfs/ -name "*.pdf" | parallel -j 4 --joblog /tmp/tika.log "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"

# Resume from job log
parallel -j 4 --resume --joblog /tmp/tika.log "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt" :::: /tmp/tika.log
```

## With Increased Memory per Job

Allocate more memory for each parallel job:

```bash
find /path/to/pdfs/ -name "*.pdf" | parallel -j 2 "java -Xmx4g -jar tika-app-2.9.1.jar -t {} > {/.}.txt"
```

## Process Specific File Patterns

Process only specific PDF patterns:

```bash
find /path/to/pdfs/ -name "*report*.pdf" | parallel -j 4 "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"
```

## Dry Run Mode

Test the command without actually processing files:

```bash
find /path/to/pdfs/ -name "*.pdf" | parallel --dry-run -j 4 "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"
```

## Performance Monitoring

Monitor system resources while processing:

```bash
# In one terminal, start processing
find /path/to/pdfs/ -name "*.pdf" | parallel -j 4 "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"

# In another terminal, monitor resources
watch -n 1 "ps aux | grep tika; free -h; uptime"
```
