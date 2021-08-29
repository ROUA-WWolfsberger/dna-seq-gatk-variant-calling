rule trim_reads_se:
    input:
        unpack(get_fastq),
    output:
        temp(results_path+"trimmed/{sample}-{unit}.fastq.gz"),
    params:
        **config["params"]["trimmomatic"]["se"],
        extra="",
    log:
        "logs/trimmomatic/{sample}-{unit}.log",
    wrapper:
        "0.75.0/bio/trimmomatic/se"


rule trim_reads_pe:
    input:
        unpack(get_fastq),
    output:
        r1=temp(results_path+"trimmed/{sample}-{unit}.1.fastq.gz"),
        r2=temp(results_path+"trimmed/{sample}-{unit}.2.fastq.gz"),
        r1_unpaired=temp(results_path+"trimmed/{sample}-{unit}.1.unpaired.fastq.gz"),
        r2_unpaired=temp(results_path+"trimmed/{sample}-{unit}.2.unpaired.fastq.gz"),
        trimlog=results_path+"trimmed/{sample}-{unit}.trimlog.txt",
    params:
        **config["params"]["trimmomatic"]["pe"],
        extra=lambda w, output: "-trimlog {}".format(output.trimlog),
    log:
        "logs/trimmomatic/{sample}-{unit}.log",
    wrapper:
        "0.75.0/bio/trimmomatic/pe"


rule map_reads:
    input:
        reads=get_trimmed_reads,
        idx=rules.bwa_index.output,
    output:
        temp(results_path+"mapped/{sample}-{unit}.sorted.bam"),
    log:
        "logs/bwa_mem/{sample}-{unit}.log",
    params:
        index=lambda w, input: os.path.splitext(input.idx[0])[0],
        extra=get_read_group,
        sort="samtools",
        sort_order="coordinate",
    threads: 8
    wrapper:
        "0.75.0/bio/bwa/mem"


rule mark_duplicates:
    input:
        results_path+"mapped/{sample}-{unit}.sorted.bam",
    output:
        bam=temp(results_path+"dedup/{sample}-{unit}.bam"),
        metrics=results_path+"qc/dedup/{sample}-{unit}.metrics.txt",
    log:
        "logs/picard/dedup/{sample}-{unit}.log",
    params:
        config["params"]["picard"]["MarkDuplicates"],
    wrapper:
        "0.75.0/bio/picard/markduplicates"


rule recalibrate_base_qualities:
    input:
        bam=get_recal_input(),
        bai=get_recal_input(bai=True),
        ref=resources_path+"genome.fasta",
        dict=resources_path+"genome.dict",
        known=resources_path+"variation.noiupac.vcf.gz",
        known_idx=resources_path+"variation.noiupac.vcf.gz.tbi",
    output:
        recal_table=results_path+"recal/{sample}-{unit}.grp",
    log:
        "logs/gatk/bqsr/{sample}-{unit}.log",
    params:
        extra=get_regions_param() + config["params"]["gatk"]["BaseRecalibrator"],
    resources:
        mem_mb=1024,
    wrapper:
        "0.75.0/bio/gatk/baserecalibrator"


rule apply_base_quality_recalibration:
    input:
        bam=get_recal_input(),
        bai=get_recal_input(bai=True),
        ref=resources_path+"genome.fasta",
        dict=resources_path+"genome.dict",
        recal_table=results_path+"recal/{sample}-{unit}.grp",
    output:
        bam=protected(results_path+"recal/{sample}-{unit}.bam"),
    log:
        "logs/gatk/apply-bqsr/{sample}-{unit}.log",
    params:
        extra=get_regions_param(),
    resources:
        mem_mb=1024,
    wrapper:
        "0.75.0/bio/gatk/applybqsr"


rule samtools_index:
    input:
        "{prefix}.bam",
    output:
        "{prefix}.bam.bai",
    log:
        "logs/samtools/index/{prefix}.log",
    wrapper:
        "0.75.0/bio/samtools/index"
