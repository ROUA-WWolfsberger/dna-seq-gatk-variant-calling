rule get_genome:
    output:
        resources_path+"genome.fasta",
    log:
        "logs/get-genome.log",
    params:
        species=config["ref"]["species"],
        datatype="dna",
        build=config["ref"]["build"],
        release=config["ref"]["release"],
    cache: True
    wrapper:
        "0.75.0/bio/reference/ensembl-sequence"


checkpoint genome_faidx:
    input:
        resources_path+"genome.fasta",
    output:
        resources_path+"genome.fasta.fai",
    log:
        "logs/genome-faidx.log",
    cache: True
    wrapper:
        "0.75.0/bio/samtools/faidx"


rule genome_dict:
    input:
        resources_path+"genome.fasta",
    output:
        resources_path+"genome.dict",
    log:
        "logs/samtools/create_dict.log",
    conda:
        "../envs/samtools.yaml"
    cache: True
    shell:
        "samtools dict {input} > {output} 2> {log} "


rule get_known_variation:
    input:
        # use fai to annotate contig lengths for GATK BQSR
        fai=resources_path+"genome.fasta.fai",
    output:
        vcf=resources_path+"variation.vcf.gz",
    log:
        "logs/get-known-variants.log",
    params:
        species=config["ref"]["species"],
        build=config["ref"]["build"],
        release=config["ref"]["release"],
        type="all",
    cache: True
    wrapper:
        "0.75.0/bio/reference/ensembl-variation"


rule remove_iupac_codes:
    input:
        resources_path+"variation.vcf.gz",
    output:
        resources_path+"variation.noiupac.vcf.gz",
    log:
        "logs/fix-iupac-alleles.log",
    conda:
        "../envs/rbt.yaml"
    cache: True
    shell:
        "rbt vcf-fix-iupac-alleles < {input} | bcftools view -Oz > {output}"


rule tabix_known_variants:
    input:
        resources_path+"variation.noiupac.vcf.gz",
    output:
        resources_path+"variation.noiupac.vcf.gz.tbi",
    log:
        "logs/tabix/variation.log",
    params:
        "-p vcf",
    cache: True
    wrapper:
        "0.75.0/bio/tabix"


rule bwa_index:
    input:
        resources_path+"genome.fasta",
    output:
        multiext(resources_path+"genome.fasta", ".amb", ".ann", ".bwt", ".pac", ".sa"),
    log:
        "logs/bwa_index.log",
    resources:
        mem_mb=369000,
    cache: True
    wrapper:
        "0.75.0/bio/bwa/index"


rule get_vep_cache:
    output:
        directory(resources_path+"vep/cache"),
    params:
        species=config["ref"]["species"],
        build=config["ref"]["build"],
        release=config["ref"]["release"],
    log:
        "logs/vep/cache.log",
    wrapper:
        "0.75.0/bio/vep/cache"


rule get_vep_plugins:
    output:
        directory(resources_path+"vep/plugins"),
    log:
        "logs/vep/plugins.log",
    params:
        release=config["ref"]["release"],
    wrapper:
        "0.75.0/bio/vep/plugins"
