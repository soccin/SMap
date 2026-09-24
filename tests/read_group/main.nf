// Test harness for config/read_group.config. Run it with run.sh, not directly.
//
// Runs Sarek's real BWA_MEM module (from the pinned sarek/ submodule) with
// SMap's read_group.config and writes, per case, the @RG/@PG header lines
// and the RG:Z tag of every read that bwa produced.

include { BWA_MEM as BWAMEM1_MEM } from '../../sarek/modules/nf-core/bwa/mem/main'

params.outdir       = null
params.bad          = false
params.fasta        = 'human_g1k_v37_decoy.fasta'
params.seq_platform = 'ILLUMINA'

// Same container as Sarek's BWA_MEM module
def BWA_CONTAINER = 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/bf/bf7890f8d4e38a7586581cb7fa13401b7af1582f21d94eef969df4cea852b6da/data'

//
// The two functions below copy Sarek's read group construction verbatim so
// the test feeds read_group.config the same strings Sarek does. If Sarek
// changes these, update the copies (and expected_rg.tsv) to match.
//

// sarek 3.9.0 workflows/sarek/main.nf:651,660-665 (FASTQ input)
def fastqReadGroup(meta, flowcell, umi_read_structure, seq_center) {
    def CN = seq_center ? "CN:${seq_center}\\t" : ''
    def sample_lane_id = flowcell ? "${flowcell}.${meta.sample}.${meta.lane}" : "${meta.sample}.${meta.lane}"
    def read_group = umi_read_structure
        ? "\"@RG\\tID:${meta.sample}\\t${CN}PU:consensus\\tSM:${meta.patient}_${meta.sample}\\tLB:${meta.sample}\\tDS:${params.fasta}\\tPL:${params.seq_platform}\""
        : "\"@RG\\tID:${sample_lane_id}\\t${CN}PU:${meta.lane}\\tSM:${meta.patient}_${meta.sample}\\tLB:${meta.sample}\\tDS:${params.fasta}\\tPL:${params.seq_platform}\""
    return read_group.toString()
}

// sarek 3.9.0 subworkflows/local/samplesheet_to_channel/main.nf:168-169
// (BAM input at the mapping step)
def bamReadGroup(meta, seq_center) {
    def fasta = params.fasta
    def seq_platform = params.seq_platform
    def CN = seq_center ? "CN:${seq_center}\\t" : ''
    def read_group = "\"@RG\\tID:${meta.sample}_${meta.lane}\\t${CN}PU:${meta.lane}\\tSM:${meta.patient}_${meta.sample}\\tLB:${meta.sample}\\tDS:${fasta}\\tPL:${seq_platform}\""
    return read_group.toString()
}

process BWA_INDEX_TEST {
    container BWA_CONTAINER

    input:
    path fasta

    output:
    path "bwa"

    script:
    """
    mkdir bwa
    bwa index -p bwa/${fasta.baseName} ${fasta}
    """
}

process SHOW_RG {
    container BWA_CONTAINER
    publishDir params.outdir, mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    path "${meta.id}.hdr.txt"

    script:
    """
    samtools view -H ${bam} | grep -E '^@(RG|PG)' > ${meta.id}.hdr.txt
    samtools view ${bam} | grep -o 'RG:Z:[^[:space:]]*' | sed 's/^/READ\\t/' >> ${meta.id}.hdr.txt
    """
}

workflow {
    if (!params.outdir) {
        error("--outdir is required")
    }

    fasta = file("${projectDir}/data/ref.fa")
    reads = [file("${projectDir}/data/r1.fq"), file("${projectDir}/data/r2.fq")]

    def base_n = [patient: 'P1', sample: 'S1N', lane: 'L001', status: 0]
    def base_t = [patient: 'P1', sample: 'S1T', lane: 'L002', status: 1]

    // --bad: a read group with SM but no LB, which read_group.config must reject
    def metas = params.bad
        ? [base_n + [id: 'bad_no_lb', read_group: '"@RG\\tID:S1N.L001\\tPU:L001\\tSM:P1_S1N\\tPL:ILLUMINA"']]
        : [
            base_n + [id: 'fastq_normal',    read_group: fastqReadGroup(base_n, 'FC1', null, null)],
            base_t + [id: 'fastq_tumor',     read_group: fastqReadGroup(base_t, 'FC1', null, null)],
            base_n + [id: 'fastq_normal_cn', read_group: fastqReadGroup(base_n, 'FC1', null, 'MSKCC')],
            base_n + [id: 'fastq_umi',       read_group: fastqReadGroup(base_n, null, '+T', null)],
            base_t + [id: 'bam_input_tumor', read_group: bamReadGroup(base_t, null)],
        ]

    index = BWA_INDEX_TEST(fasta).map { dir -> [[id: 'ref'], dir] }

    BWAMEM1_MEM(
        channel.fromList(metas).map { m -> [m, reads] },
        index,
        channel.value([[id: 'ref'], fasta]),
        true
    )

    SHOW_RG(BWAMEM1_MEM.out.bam)
}
