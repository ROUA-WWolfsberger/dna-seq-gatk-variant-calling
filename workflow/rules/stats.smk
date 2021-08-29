rule vcf_to_tsv:
    input:
        "{results_path}/annotated/all.vcf.gz",
    output:
        report(
            "{results_path}/tables/calls.tsv.gz",
            caption="../report/calls.rst",
            category="Calls",
        ),
    log:
        "logs/vcf-to-tsv.log",
    conda:
        "../envs/rbt.yaml"
    shell:
        "(bcftools view --apply-filters PASS --output-type u {input} | "
        "rbt vcf-to-txt -g --fmt DP AD --info ANN | "
        "gzip > {output}) 2> {log}"


rule plot_stats:
    input:
        "{results_path}/tables/calls.tsv.gz",
    output:
        depths=report(
            "{results_path}/plots/depths.svg", caption="../report/depths.rst", category="Plots"
        ),
        freqs=report(
            "{results_path}/plots/allele-freqs.svg",
            caption="../report/freqs.rst",
            category="Plots",
        ),
    log:
        "logs/plot-stats.log",
    conda:
        "../envs/stats.yaml"
    script:
        "../scripts/plot-depths.py"
