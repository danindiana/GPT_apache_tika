How can we run apache tika on our ubuntu 22.04 in parallel to convert a bunch of pdfs into text files?


1. Install Apache Tika

Using apt (recommended):
Bash
sudo apt update
sudo apt install apache-tika
Use code with caution.

Manual Installation (if you need a specific version):
Download the Tika server JAR file from the Apache Tika website.
Make it executable: chmod +x tika-server-*.jar
2.  Parallel Processing with GNU Parallel

GNU Parallel is a fantastic tool for running shell commands in parallel. It's efficient and easy to use.

Install:
Bash
sudo apt install parallel
Use code with caution.

3.  The Conversion Command

We'll use tika-app (part of the Apache Tika package) to extract text. Here's the basic command:

Bash
tika-app -t <PDF_FILE> > <OUTPUT_TEXT_FILE>
Use code with caution.

4.  Putting it Together with Parallel

Bash
find . -name "*.pdf" | parallel "tika-app -t {} > {.}.txt"
Use code with caution.

Explanation:
find . -name "*.pdf": This finds all PDF files in the current directory and its subdirectories.
|: This pipes the list of PDF files to parallel.
parallel: This runs the given command in parallel for each PDF file.
tika-app -t {} > {.}.txt: This is the command that parallel executes.
{}: This is a placeholder for the PDF file name.
{.}.txt: This creates an output text file with the same name as the PDF file, but with a .txt extension.
5.  Advanced Parallel Options

Control the Number of Jobs:

Bash
find . -name "*.pdf" | parallel -j <NUMBER_OF_JOBS> "tika-app -t {} > {.}.txt"
Use code with caution.

(Replace <NUMBER_OF_JOBS> with the desired number of parallel processes. A good starting point is the number of CPU cores you have.)

Progress Bar:

Bash
find . -name "*.pdf" | parallel --bar "tika-app -t {} > {.}.txt"
Use code with caution.

Error Handling:

Bash
find . -name "*.pdf" | parallel --halt 2 "tika-app -t {} > {.}.txt" 
Use code with caution.

(This will stop the entire process if 2 jobs fail. Useful for debugging.)

Example:

Let's say you have a directory named pdfs with all your PDF files.  To convert them in parallel using 4 CPU cores, you would run:

Bash
cd pdfs
find . -name "*.pdf" | parallel -j 4 "tika-app -t {} > {.}.txt"
Use code with caution.

Important Notes

File Names: Make sure your PDF file names don't contain any special characters that might interfere with the shell command.
Tika Options: Explore the other options of tika-app (use tika-app --help) for more control over the conversion process (e.g., specifying output format, handling metadata).
Resource Limits: Monitor your system's resource usage (CPU, memory, I/O) when running parallel processes to avoid overloading it. Adjust the number of jobs (-j) accordingly.
Complex PDFs: For very complex or large PDFs, consider increasing the memory allocated to the Java Virtual Machine (JVM) that Tika uses. You can do this by setting the JAVA_OPTS environment variable before running tika-app.
This approach provides a robust and efficient way to convert your PDFs into text files in parallel on your Ubuntu 22.04 system. Let me know if you have any specific requirements or need further assistance with customizing the process!







Using Tika as a command line utility
The Tika application jar (tika-app-*.jar) can be used as a command line utility for extracting text content and metadata from all sorts of files. This runnable jar contains all the dependencies it needs, so you don't need to worry about classpath settings to run it.
The usage instructions are shown below.

usage: java -jar tika-app.jar [option...] [file|port...]

Options:
    -?  or --help          Print this usage message
    -v  or --verbose       Print debug level messages
    -V  or --version       Print the Apache Tika version number

    -g  or --gui           Start the Apache Tika GUI
    -s  or --server        Start the Apache Tika server
    -f  or --fork          Use Fork Mode for out-of-process extraction

    --config=<tika-config.xml>
        TikaConfig file. Must be specified before -g, -s, -f or the dump-x-config !
    --dump-minimal-config  Print minimal TikaConfig
    --dump-current-config  Print current TikaConfig
    --dump-static-config   Print static config
    --dump-static-full-config  Print static explicit config

    -x  or --xml           Output XHTML content (default)
    -h  or --html          Output HTML content
    -t  or --text          Output plain text content
    -T  or --text-main     Output plain text content (main content only)
    -m  or --metadata      Output only metadata
    -j  or --json          Output metadata in JSON
    -y  or --xmp           Output metadata in XMP
    -J  or --jsonRecursive Output metadata and content from all
                           embedded files (choose content type
                           with -x, -h, -t or -m; default is -x)
    -l  or --language      Output only language
    -d  or --detect        Detect document type
           --digest=X      Include digest X (md2, md5, sha1,
                               sha256, sha384, sha512
    -eX or --encoding=X    Use output encoding X
    -pX or --password=X    Use document password X
    -z  or --extract       Extract all attachements into current directory
    --extract-dir=<dir>    Specify target directory for -z
    -r  or --pretty-print  For JSON, XML and XHTML outputs, adds newlines and
                           whitespace, for better readability

    --list-parsers
         List the available document parsers
    --list-parser-details
         List the available document parsers and their supported mime types
    --list-parser-details-apt
         List the available document parsers and their supported mime types in apt format.
    --list-detectors
         List the available document detectors
    --list-met-models
         List the available metadata models, and their supported keys
    --list-supported-types
         List all known media types and related information


    --compare-file-magic=<dir>
         Compares Tika's known media types to the File(1) tool's magic directory

Description:
    Apache Tika will parse the file(s) specified on the
    command line and output the extracted text content
    or metadata to standard output.

    Instead of a file name you can also specify the URL
    of a document to be parsed.

    If no file name or URL is specified (or the special
    name "-" is used), then the standard input stream
    is parsed. If no arguments were given and no input
    data is available, the GUI is started instead.

- GUI mode

    Use the "--gui" (or "-g") option to start the
    Apache Tika GUI. You can drag and drop files from
    a normal file explorer to the GUI window to extract
    text content and metadata from the files.

- Batch mode

    Simplest method.
    Specify two directories as args with no other args:
         java -jar tika-app.jar <inputDirectory> <outputDirectory>


Batch Options:
    -i  or --inputDir          Input directory
    -o  or --outputDir         Output directory
    -numConsumers              Number of processing threads
    -bc                        Batch config file
    -maxRestarts               Maximum number of times the
                               watchdog process will restart the child process.
    -timeoutThresholdMillis    Number of milliseconds allowed to a parse
                               before the process is killed and restarted
    -fileList                  List of files to process, with
                               paths relative to the input directory
    -includeFilePat            Regular expression to determine which
                               files to process, e.g. "(?i)\.pdf"
    -excludeFilePat            Regular expression to determine which
                               files to avoid processing, e.g. "(?i)\.pdf"
    -maxFileSizeBytes          Skip files longer than this value

    Control the type of output with -x, -h, -t and/or -J.

    To modify child process jvm args, prepend "J" as in:
    -JXmx4g or -JDlog4j.configuration=file:log4j.xml.
You can also use the jar as a component in a Unix pipeline or as an external tool in many scripting languages.

# Check if an Internet resource contains a specific keyword
curl http://.../document.doc \
  | java -jar tika-app.jar --text \
  | grep -q keyword
Wrappers
Several wrappers are available to use Tika in another programming language, such as Julia or Python



Thanks for providing the detailed usage instructions for Apache Tika! This is very helpful.

Let's break down how to use Tika effectively as a command-line utility on your Ubuntu 22.04 system.

Basic Text Extraction

To extract the plain text content from a single file (e.g., document.pdf):

Bash
java -jar tika-app-*.jar -t document.pdf > document.txt 
Use code with caution.

java -jar tika-app-*.jar: This runs the Tika application JAR. Make sure to replace tika-app-*.jar with the actual name of your JAR file.
-t: This option tells Tika to output plain text content.
document.pdf: This is the input PDF file.
>: This redirects the output to a file named document.txt.
Extracting Metadata

To extract only the metadata from a file (e.g., image.jpg):

Bash
java -jar tika-app-*.jar -m image.jpg 
Use code with caution.

-m: This option tells Tika to output metadata.
Other Useful Options

-x: Output XHTML content (this is the default if no output option is specified).
-h: Output HTML content.
-j: Output metadata in JSON format.
-l: Output only the language of the document.
-d: Detect the document type.
Combining Options

You can combine options for more specific output. For example, to extract both text content and metadata in JSON format from a file (e.g., report.docx):

Bash
java -jar tika-app-*.jar -t -j report.docx > report.txt 
Use code with caution.

Piping and Scripting

Tika's command-line interface makes it easy to integrate into shell scripts and pipelines. Here's an example of how to extract text from a PDF file downloaded with curl and then count the number of words:

Bash
curl https://example.com/myfile.pdf | java -jar tika-app-*.jar -t | wc -w
Use code with caution.

Batch Processing

Tika also provides a batch mode for processing multiple files, as you've shown in the instructions. This can be very efficient for large-scale conversions.

Key Considerations

JAR Location: Make sure the tika-app-*.jar file is in your current directory or provide the full path to it.
Java: You need to have Java installed on your system to run Tika.
Memory: For large or complex files, you might need to increase the Java heap size using the -Xmx option (e.g., java -Xmx2g -jar tika-app-*.jar ...).
With these instructions and tips, you can effectively use Apache Tika as a command-line tool to extract text and metadata from various file types on your Ubuntu system. If you have any specific use cases or encounter any issues, feel free to ask! I'm here to help you get the most out of Tika.







Ok here is our tika:

jeb@worlock:/media/jeb/ba4c008c-3079-47f1-8e31-cc3547f6307f/home/walter/programs/tika$ ls
node_modules  package.json  package-lock.json  tika-app-2.9.1.jar


and here is the directory with the pdfs we want to convert to text files: /home/jeb/pdf_scraper_gov2/



Okay, I have the location of your tika-app-2.9.1.jar and the directory containing the PDFs. Here's how to convert those PDFs into text files in parallel:

1. Navigate to the Tika Directory

Open your terminal and navigate to the directory where tika-app-2.9.1.jar is located:

Bash
cd /media/jeb/ba4c008c-3079-47f1-8e31-cc3547f6307f/home/walter/programs/tika
Use code with caution.

2. Install GNU Parallel

Make sure you have GNU Parallel installed:

Bash
sudo apt update
sudo apt install parallel
Use code with caution.

3. Run the Parallel Conversion Command

Execute the following command to convert the PDFs in parallel:

Bash
find /home/jeb/pdf_scraper_gov2/ -name "*.pdf" | parallel "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt"
Use code with caution.

Explanation:
find /home/jeb/pdf_scraper_gov2/ -name "*.pdf": This searches for all files ending in .pdf within the /home/jeb/pdf_scraper_gov2/ directory and its subdirectories.
|: This pipes the output (the list of PDF files) to the parallel command.
parallel: This command executes the following command for each PDF file in parallel.
"java -jar tika-app-2.9.1.jar -t {} > {/.}.txt":
java -jar tika-app-2.9.1.jar -t: This runs Tika to extract plain text.
{}: This is a placeholder that parallel replaces with the current PDF file name.
> {/.}.txt: This redirects the output to a new text file with the same name as the PDF (but with a .txt extension) in the same directory as the PDF.
4.  Adjust Parallelism (Optional)

If you want to control the number of parallel processes, use the -j option with parallel:

Bash
find /home/jeb/pdf_scraper_gov2/ -name "*.pdf" | parallel -j 4 "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt" 
Use code with caution.

(This would use 4 CPU cores. Adjust the number as needed.)

Important Notes

File Names: Ensure your PDF file names don't have special characters that could cause issues with the command.
Tika Options: Refer to the Tika usage instructions you provided to explore other options (e.g., -m for metadata, -j for JSON output).
Resource Monitoring: Keep an eye on your system's resource usage (CPU, memory, I/O) during the conversion process. If necessary, adjust the number of parallel jobs to prevent overloading your system.
This should efficiently convert all your PDFs to text files. If you have any problems or further questions, feel free to ask!







Where does that bash save the text files to?


You're right to ask! I apologize for not being explicit about the output location in my previous response.

With the command I provided:

Bash
find /home/jeb/pdf_scraper_gov2/ -name "*.pdf" | parallel "java -jar tika-app-2.9.1.jar -t {} > {/.}.txt" 
Use code with caution.

The text files will be saved in the same directory as their corresponding PDF files.

{/.}.txt: This part of the command is responsible for determining the output file name and location.
{}: This is replaced by parallel with the full path to the PDF file.
/.: This extracts the directory part of the PDF file's path.
.txt: This adds the .txt extension to create the text file name.
Example:

If you have a PDF file at /home/jeb/pdf_scraper_gov2/reports/mydocument.pdf, the converted text file will be saved as /home/jeb/pdf_scraper_gov2/reports/mydocument.txt.

To change the output directory:

If you want to save the text files in a different location, you can modify the command. For example, to save all the text files to /home/jeb/output_texts/:

Bash
find /home/jeb/pdf_scraper_gov2/ -name "*.pdf" | parallel "java -jar tika-app-2.9.1.jar -t {} > /home/jeb/output_texts/{/.}.txt" 
Use code with caution.

This will extract the base filename from the PDF's path and then create the .txt file in the /home/jeb/output_texts/ directory.







ok let's do that and have this be the output dir for the text files: /home/jeb/pdf_scrapes_text/


Excellent! Here's the command to convert your PDFs to text files and save them in the /home/jeb/pdf_scrapes_text/ directory:

Bash
find /home/jeb/pdf_scraper_gov2/ -name "*.pdf" | parallel "java -jar tika-app-2.9.1.jar -t {} > /home/jeb/pdf_scrapes_text/{/.}.txt"
Use code with caution.

Explanation

find /home/jeb/pdf_scraper_gov2/ -name "*.pdf": This locates all the PDF files you want to convert.
parallel: This runs the conversion command in parallel for each PDF.
"java -jar tika-app-2.9.1.jar -t {} > /home/jeb/pdf_scrapes_text/{/.}.txt":
java -jar tika-app-2.9.1.jar -t: This invokes Tika to extract plain text.
{}: This placeholder gets replaced with the full path of each PDF file.
/home/jeb/pdf_scrapes_text/{/.}.txt: This specifies the output directory and file name:
/home/jeb/pdf_scrapes_text/: The directory where you want to save the text files.
/.: This extracts the original file name from the PDF's path (without the directory).
.txt: This adds the .txt extension.
Before you run it

Create the Directory: Make sure the output directory /home/jeb/pdf_scrapes_text/ exists. If not, create it:

Bash
mkdir /home/jeb/pdf_scrapes_text/
Use code with caution.

Navigate to Tika:  In your terminal, navigate to the directory containing tika-app-2.9.1.jar:

Bash
cd /media/jeb/ba4c008c-3079-47f1-8e31-cc3547f6307f/home/walter/programs/tika
Use code with caution.

Now you can run the command above to convert your PDFs!







Ok and can I get that with parallelism?

Show drafts


You got it! Here's the command with parallelism, using 4 CPU cores as an example. You can adjust this number based on your system's capabilities:

Bash
find /home/jeb/pdf_scraper_gov2/ -name "*.pdf" | parallel -j 4 "java -jar tika-app-2.9.1.jar -t {} > /home/jeb/pdf_scrapes_text/{/.}.txt"
Use code with caution.

This command is essentially the same as the previous one, but with the addition of -j 4 to instruct parallel to run 4 processes concurrently.

Choosing the Right Level of Parallelism

Start with CPU Cores: A good starting point for the number of jobs (-j) is the number of CPU cores your system has. You can find this with the command nproc.
Monitor Resources: Keep an eye on your system's CPU, memory, and I/O usage while the conversion is running. If you see it getting overloaded, reduce the number of jobs.
Experiment: You might need to experiment a bit to find the optimal level of parallelism for your specific system and the size/complexity of your PDFs.
Additional Tips for Parallelism

Progress Bar:  If you want to see a progress bar, add --bar to the parallel command:

Bash
find /home/jeb/pdf_scraper_gov2/ -name "*.pdf" | parallel -j 4 --bar "java -jar tika-app-2.9.1.jar -t {} > /home/jeb/pdf_scrapes_text/{/.}.txt"
Use code with caution.

Error Handling: To make the process more robust, you can use --halt to stop if a certain number of jobs fail:

Bash
find /home/jeb/pdf_scraper_gov2/ -name "*.pdf" | parallel -j 4 --halt 2 "java -jar tika-app-2.9.1.jar -t {} > /home/jeb/pdf_scrapes_text/{/.}.txt"
Use code with caution.

(This would stop the whole process if 2 jobs fail).

I'm ready to assist if you have any more questions or want to further refine the command!







ERROR [main] 11:47:53,855 org.apache.pdfbox.contentstream.PDFStreamEngine Cannot read JPEG2000 image: Java Advanced Imaging (JAI) Image I/O Tools are not installed


Show drafts


Ah, that error message means that Apache Tika (or more specifically, the PDFBox library it uses) can't process JPEG 2000 images within your PDFs because the necessary Java Advanced Imaging (JAI) Image I/O Tools are missing.

Here's how to fix it:

1. Install the JAI Image I/O Tools

You have two options for installation:

a) Using Maven (if you're working with a Maven project):

Add the following dependencies to your pom.xml file:

XML
<dependency>
    <groupId>com.github.jai-imageio</groupId>
    <artifactId>jai-imageio-core</artifactId>
    <version>1.4.0</version> </dependency>
<dependency>
    <groupId>com.github.jai-imageio</groupId>
    <artifactId>jai-imageio-jpeg2000</artifactId>
    <version>1.4.0</version>   
 </dependency>
Use code with caution.

b) Manual installation (for standalone use):

Download the following JAR files from the Maven Central Repository or a similar source:
jai-imageio-core-*.jar
jai-imageio-jpeg2000-*.jar
Place these JAR files in a directory where your Java application can access them.
You might need to add these JAR files to your classpath when running Tika. You can do this by setting the CLASSPATH environment variable or using the -cp option with the java command.
2.  (If necessary) Add JARs to Tika's Classpath

If you installed the JAI tools manually, you'll need to make sure Tika can find them. Here's how to modify your parallel command to include the JAI JARs in the classpath:

Bash
find /home/jeb/pdf_scraper_gov2/ -name "*.pdf" | parallel -j 4 "java -cp 'tika-app-2.9.1.jar:jai-imageio-core-*.jar:jai-imageio-jpeg2000-*.jar' org.apache.tika.cli.TikaCLI -t {} > /home/jeb/pdf_scrapes_text/{/.}.txt"
Use code with caution.

Replace jai-imageio-core-*.jar and jai-imageio-jpeg2000-*.jar with the actual names of the downloaded JAR files.
Make sure the paths to the JAR files are correct if they are not in the same directory as tika-app-2.9.1.jar.
3. Run the Conversion Again

After installing the JAI Image I/O Tools and (if necessary) updating your command, try running the PDF conversion again. The error related to JPEG2000 images should be resolved.
