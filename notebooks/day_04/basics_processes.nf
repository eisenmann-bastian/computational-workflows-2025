params.step = 0
params.zip = 'zip'


process SAYHELLO {
    debug true
    """
    echo "Hello World!"
    """
}

process SAYHELLO_PYTHON {
    
    debug true
    """
    #!/usr/bin/env python
    print("Hello World (from Python :))!")
    """
}

process SAYHELLO_PARAM {
    
    debug true
    input:
    val text

    """
    #!/usr/bin/env python
    print("$text")
    """
}

process SAYHELLO_FILE {
    debug true
    input:
    val text

    """
    echo '$text' >> greetings.txt
    """
}

process UPPERCASE {
    input:
    val text

    output:
    path "uppercase.txt"

    script:
    """
    echo ${text.toUpperCase()} > uppercase.txt
    """
}

process PRINTUPPER {
    debug true
    input:
    path textfile

    """
    cat $textfile
    """
}


process COMPRESS {
    debug true

    input:
    tuple path(file), val(compress_type)
    


    output:
    path '*.*'

    script:
    if (compress_type == 'gzip')
        """
        gzip -c $file > ${file}.gz
        """
    else if (compress_type == 'bzip2')
        """
        bzip2 -c $file > ${file}.bz2
        """
    else if (compress_type == 'zip')
        """
        zip ${file}.zip $file
        """
    else
        """
        echo "Unknown compression type: $compress_type"
        exit 1
        """
}

process WRITETOFILE {

    publishDir 'results', mode: 'copy'

    input:
    val entries

    output:
    path 'names.tsv'

    script:
    def lines = ["Name\tTitle"] + entries.collect { "${it.name}\t${it.title}" }
    def content = lines.join('\n')

    """
    mkdir -p results
    echo "${content}" > names.tsv
    """
}


workflow {

    // Task 1 - create a process that says Hello World! (add debug true to the process right after initializing to be sable to print the output to the console)
    if (params.step == 1) {
        SAYHELLO()
    }

    // Task 2 - create a process that says Hello World! using Python
    if (params.step == 2) {
        SAYHELLO_PYTHON()
    }

    // Task 3 - create a process that reads in the string "Hello world!" from a channel and write it to command line
    if (params.step == 3) {
        greeting_ch = Channel.of("Hello world! - Parameterized")
        SAYHELLO_PARAM(greeting_ch)
    }

    // Task 4 - create a process that reads in the string "Hello world!" from a channel and write it to a file. WHERE CAN YOU FIND THE FILE?
    // File is stored in the work directory of the process. Cuz no publish dir is defined, the work directory will not be published.
    if (params.step == 4) {
        greeting_ch = Channel.of("Hello world! - File")
        SAYHELLO_FILE(greeting_ch)
    }

    // Task 5 - create a process that reads in a string and converts it to uppercase and saves it to a file as output. View the path to the file in the console
    if (params.step == 5) {
        greeting_ch = Channel.of("Hello world!")
       
        out_ch = UPPERCASE(greeting_ch)
        out_ch.view()
    }

     

    // Task 6 - add another process that reads in the resulting file from UPPERCASE and print the content to the console (debug true). WHAT CHANGED IN THE OUTPUT?
    if (params.step == 6) {
        greeting_ch = Channel.of("Hello world!")
        out_ch = UPPERCASE(greeting_ch)

        PRINTUPPER(out_ch)
    }

    
    // Task 7 - based on the paramater "zip" (see at the head of the file), create a process that zips the file created in the UPPERCASE process either in "zip", "gzip" OR "bzip2" format.
    //          Print out the path to the zipped file in the console
    if (params.step == 7) {
        greeting_ch = Channel.of("Hello world!")
        out_ch = UPPERCASE(greeting_ch)

        compress_ch = channel.of(params.zip)
        
        compressed_files = out_ch.combine(compress_ch) | COMPRESS
        compressed_files.view()
    }

    // Task 8 - Create a process that zips the file created in the UPPERCASE process in "zip", "gzip" AND "bzip2" format. Print out the paths to the zipped files in the console

    if (params.step == 8) {
        greeting_ch = Channel.of("Hello world!")
        out_ch = UPPERCASE(greeting_ch)

        compress_ch = channel.of("zip","gzip","bzip2")
        
        compressed_files = out_ch.combine(compress_ch) | COMPRESS
        compressed_files.view()
    }

    // Task 9 - Create a process that reads in a list of names and titles from a channel and writes them to a file.
    //          Store the file in the "results" directory under the name "names.tsv"

    if (params.step == 9) {
        in_ch = channel.of(
            ['name': 'Harry', 'title': 'student'],
            ['name': 'Ron', 'title': 'student'],
            ['name': 'Hermione', 'title': 'student'],
            ['name': 'Albus', 'title': 'headmaster'],
            ['name': 'Snape', 'title': 'teacher'],
            ['name': 'Hagrid', 'title': 'groundkeeper'],
            ['name': 'Dobby', 'title': 'hero'],
        )

        //in_ch.flatten().view()
        in_ch.collect() | WRITETOFILE
            // continue here
    }
}