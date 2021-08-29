rule fastqc:
    input:
        unpack(get_fastq),
    output:
        html=results_path+"qc/fastqc/{sample}-{unit}.html",
        zip=results_path+"qc/fastqc/{sample}-{unit}.zip",
    log:
        "logs/fastqc/{sample}-{unit}.log",
    wrapper:
        "0.75.0/bio/fastqc"


rule samtools_stats:
    input:
        results_path+"recal/{sample}-{unit}.bam",
    output:
        results_path+"qc/samtools-stats/{sample}-{unit}.txt",
    log:
        "logs/samtools-stats/{sample}-{unit}.log",
    wrapper:
        "0.75.0/bio/samtools/stats"


rule multiqc:
    input:
        expand(
            [
                results_path+"qc/samtools-stats/{u.sample}-{u.unit}.txt",
                results_path+"qc/fastqc/{u.sample}-{u.unit}.zip",
                results_path+"qc/dedup/{u.sample}-{u.unit}.metrics.txt",
            ],
            u=units.itertuples(),
        ),
    output:
        report(
            results_path+"qc/multiqc.html",
            caption="../report/multiqc.rst",
            category="Quality control",
        ),
    log:
        "logs/multiqc.log",
    wrapper:
        "0.75.0/bio/multiqc"
