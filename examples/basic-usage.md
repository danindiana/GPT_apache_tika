# Basic Usage Examples

This guide provides simple examples for using Apache Tika to extract text from PDF files.

## Single File Conversion

Extract text from a single PDF file:

```bash
java -jar tika-app-2.9.1.jar -t input.pdf > output.txt
```

## Extract Metadata Only

Extract only metadata from a PDF:

```bash
java -jar tika-app-2.9.1.jar -m document.pdf
```

## Extract Metadata as JSON

Get metadata in JSON format:

```bash
java -jar tika-app-2.9.1.jar -j document.pdf
```

## Detect Document Type

Detect the MIME type of a file:

```bash
java -jar tika-app-2.9.1.jar -d unknown-file.bin
```

## Extract Text from URL

Process a document directly from a URL:

```bash
java -jar tika-app-2.9.1.jar -t https://example.com/document.pdf > output.txt
```

## Process with Increased Memory

For large PDF files, increase Java heap size:

```bash
java -Xmx4g -jar tika-app-2.9.1.jar -t large-document.pdf > output.txt
```

## Output HTML Format

Extract content in HTML format:

```bash
java -jar tika-app-2.9.1.jar -h document.pdf > output.html
```

## Extract Main Content Only

Extract only the main text content (excluding headers, footers, etc.):

```bash
java -jar tika-app-2.9.1.jar -T document.pdf > output.txt
```
