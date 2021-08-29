if "restrict-regions" in config["processing"]:

    rule compose_regions:
        input:
            config["processing"]["restrict-regions"],
        output:
            results_path+"called/{contig}.regions.bed",
        conda:
            "../envs/bedops.yaml"
        shell:
            "bedextract {wildcards.contig} {input} > {output}"


rule call_variants:
    input:
        bam=get_sample_bams,
        ref=resources_path+"genome.fasta",
        idx=resources_path+"genome.dict",
        known=resources_path+"variation.noiupac.vcf.gz",
        tbi=resources_path+"variation.noiupac.vcf.gz.tbi",
        regions=(
            results_path+"called/{contig}.regions.bed"
            if config["processing"].get("restrict-regions")
            else []
        ),
    output:
        gvcf=protected(results_path+"called/{sample}.{contig}.g.vcf.gz"),
    log:
        "logs/gatk/haplotypecaller/{sample}.{contig}.log",
    params:
        extra=get_call_variants_params,
    wrapper:
        "0.75.0/bio/gatk/haplotypecaller"


rule combine_calls:
    input:
        ref=resources_path+"genome.fasta",
        gvcfs=expand(
            results_path+"called/{sample}.{{contig}}.g.vcf.gz", sample=samples.index
        ),
    output:
        gvcf=results_path+"called/all.{contig}.g.vcf.gz",
    log:
        "logs/gatk/combinegvcfs.{contig}.log",
    wrapper:
        "0.75.0/bio/gatk/combinegvcfs"


rule genotype_variants:
    input:
        ref=resources_path+"genome.fasta",
        gvcf=results_path+"called/all.{contig}.g.vcf.gz",
    output:
        vcf=temp(results_path+"genotyped/all.{contig}.vcf.gz"),
    params:
        extra=config["params"]["gatk"]["GenotypeGVCFs"],
    log:
        "logs/gatk/genotypegvcfs.{contig}.log",
    wrapper:
        "0.75.0/bio/gatk/genotypegvcfs"


rule merge_variants:
    input:
        vcfs=lambda w: expand(
            results_path+"genotyped/all.{contig}.vcf.gz", contig=get_contigs()
        ),
    output:
        vcf=results_path+"genotyped/all.vcf.gz",
    log:
        "logs/picard/merge-genotyped.log",
    wrapper:
        "0.75.0/bio/picard/mergevcfs"
