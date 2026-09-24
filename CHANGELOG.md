# Changelog

## [4.0.0] - 2026-09-23

**Sarek Submodule**: nf-core/sarek v3.9.0 (official), commit b97952e5b

### BREAKING CHANGES
- **BAM Output, No CRAM**: `runSarekHuman.sh` passes `--save_output_as_bam`.
  No CRAM or CRAI files are written or published anywhere under `sbam/`
  - `sbam/preprocessing/markduplicates/<id>/<id>.md.bam` and `.md.bam.bai`
  - `sbam/preprocessing/recalibrated/<id>/<id>.recal.bam` and
    `.recal.bam.bai` (not produced with `-s`)
  - `sbam/csv/*.csv` restart files list the BAM paths
  - MarkDuplicates metrics file is now `<id>.md.bam.metrics`
    (was `<id>.md.cram.metrics`)
  - Anything downstream that looks for `.cram` under `sbam/` must be updated
- **SM/LB Swapped At Alignment**: BWA now writes `SM:<sample>` and
  `LB:<patient>_<sample>` directly (Sarek writes `SM:<patient>_<sample>`,
  `LB:<sample>`)
  - Before 4.0.0 the swap was applied to the header by `sarekCramToBam.sh`
    while converting the CRAM. That script and `fix_sarek_headers.py` are
    retired (see Removed); the swap is in `config/read_group.config`
  - These BAMs cannot be fed back into Sarek variant calling: its Mutect2
    and Sentieon TNscope expect the normal to be named `<patient>_<sample>`
- **Sarek Version**: v3.7.1 -> v3.9.0

### Why Sarek 3.9.0
- In 3.7.1, `--save_output_as_bam` with BQSR silently loses the
  recalibrated BAMs on WGS runs split into intervals
  - ApplyBQSR writes BAM, but the workflow only reads its CRAM output,
    which is then empty
  - No `recalibrated/*.recal.bam` and no `recalibrated.csv` are produced
  - The merged BAM is named `<id>.sorted.bam` and is only published to
    `mapped/` with `--save_mapped`; otherwise it stays in the work directory
- 3.9.0 fixes this (nf-core/sarek#2154, closes #2149): the ApplyBQSR BAMs
  are merged and published as `recal.bam`, and MarkDuplicates writes BAM
  directly instead of CRAM followed by conversion

### Added
- **`config/read_group.config`**: Swaps SM and LB in the read group Sarek
  passes to `bwa mem -R`; included by `iris.config` and `neo.config`
  - Replaces Sarek's BWA `ext.args` (same selector as
    `sarek/conf/modules/aligner.config`) with the same arguments and only
    the read group changed, including `-B 3` for tumors
  - The tags are right in the first BAM BWA writes, so `md.bam` and
    `recal.bam` need no reheader and no extra BAM copy
  - If the read group has no single SM/LB pair to swap, the run stops with
    an error instead of writing mislabeled BAMs. This aborts the run even
    under the iris/neo retry-then-ignore error strategy
  - Re-check against Sarek's `aligner.config` on every Sarek update
- **`tests/read_group/`**: Regression test for `read_group.config`. Run
  `tests/read_group/run.sh` after every Sarek update
  - Runs Sarek's real BWA_MEM module from the pinned submodule on a 3 kb
    reference, with read groups built by a verbatim copy of Sarek's code
    (FASTQ normal/tumor, with CN, UMI, BAM input)
  - Checks the exact @RG line, RG:Z on every read, `-B 3` on tumors only,
    and that a read group without LB stops the run
  - Takes a few seconds; works on IRIS and JUNO
- **Index Touch**: `runSarekHuman.sh` touches every `*.bai` under
  `$ODIR/preprocessing` after Nextflow finishes
  - Nextflow copies the small `.bai` before the large `.bam` finishes, so
    the index ends up older than the data file and htslib warns
    "The index file is older than the data file"
  - Guarded by a directory check so a failed run does not stop the script
    (`set -e`) before `runlog/cmd.sh.log` is written

### Changed
- **MarkDuplicates Index**: iris and neo `GATK4_MARKDUPLICATES` `ext.args`
  add `--CREATE_INDEX true` when `--save_output_as_bam` is set
  - Our `ext.args` replaces Sarek's, which is where 3.9.0 sets this flag.
    Without it Picard writes no `.bai` and the bam/bai join fails
- **BAM Merge After BQSR**: The MERGE_CRAM resources and `-c -p` moved to
  `BAM_APPLYBQSR:BAM_MERGE_INDEX_SAMTOOLS:MERGE_BAM` on iris and neo
  - In BAM mode this step replaces MERGE_CRAM, which no longer runs; same
    reason for `-c -p` (see [3.1.0])
  - The `CRAM_SAMPLEQC:CRAM_QC_RECAL:SAMTOOLS_STATS` selector stays: it is
    Sarek's name for the recal QC step, which runs on the BAMs
- **Metrics Scripts BAM Only**: `collectWgsMetrics.sh`,
  `collectAlignmentSummaryMetrics.sh` and `collectInsertSizeMetrics.sh`
  accept only `.bam` and name output by the `SM` tag
  - The CRAM branch, which named output by `LB` because Sarek CRAMs had the
    sample name there, is gone
- **`bin/cleanup.sh`**: No longer matches `.cram` files in `work/`

### Removed
- **Post-Processing Scripts Retired to `bin/attic/`**:
  `bin/sarekCramToBam.sh` and `bin/fix_sarek_headers.py`
  - Sarek now writes BAM, so there is nothing to convert
  - The SM/LB swap now happens at alignment, so there is nothing to fix;
    running either script on 4.0.0 BAMs would swap the tags back
  - Kept in `bin/attic/` for reference only; do not use them
- **CRAM Support**: SMap no longer reads or writes CRAM anywhere (see
  Changed for the metrics scripts, the MERGE_CRAM config and `cleanup.sh`)

### Upstream Bugs Documented
This release works around or documents these bugs in nf-core/sarek v3.9.0:
1. **`csv/markduplicates.csv` Index Path**: Lists `<id>.md.bai`, but the
   published file is `<id>.md.bam.bai`
   - The CSV uses the index name Picard writes in the work directory; the
     publish step renames it
     (`subworkflows/local/channel_baserecalibrator_create_csv/main.nf:39`)
   - Only matters when restarting with `--step prepare_recalibration` from
     this CSV; `runSarekHuman.sh` never does. Still present on upstream `dev`
   - `markduplicates_no_table.csv` and `recalibrated.csv` are correct
2. **GRCh37 Intervals Validation**: Still present in 3.9.0; the local BED
   workaround from [3.0.0] is kept
3. **Index Older Than BAM**: See Index Touch above

### Technical Details

#### Behavior Unchanged From 3.7.1
- ApplyBQSR only writes reads inside the calling intervals. The GRCh37
  intervals leave out the `hs37d5` decoy contig, so those reads are in
  `md.bam` but not in `recal.bam` (5.3% tumor, 4.6% normal in the test)
- `recal.bam` is about 60% larger than `md.bam`: the sequencer stores
  quality scores in 4 bins, and BQSR expands them to about 38 distinct
  values, which compress worse
- Sarek's read-group construction is identical to 3.7.1
  (`SM:<patient>_<sample>`, `LB:<sample>`) and still requires `sample` to
  be unique across the samplesheet; SMap swaps the tags at alignment
- The SM/LB swap does not change mapping: MarkDuplicates groups by LB,
  still one value per sample across all its lanes, and BQSR groups by
  read group ID/PU, both unchanged

#### New Upstream Plugin
- Sarek 3.9.0 adds the `nf-core-utils@0.4.0` Nextflow plugin. The node
  that launches Nextflow downloads it on the first run

#### Testing
- **Platform**: IRIS (SLURM)
- **Genome**: GRCh37 (GATK.GRCh37)
- **Samples**: One tumor/normal pair, WGS, with BQSR, 13 lanes each
- **Run 1** (BAM output, before the SM/LB swap): 483 tasks completed, none
  failed or retried
  - No CRAM or CRAI files anywhere under `sbam/`; no CRAM conversion or
    CRAM merge steps ran
  - All four BAMs pass `samtools quickcheck`
  - MarkDuplicates `@PG` shows `--CREATE_INDEX true`; the BAM merge `@PG`
    shows `-c -p` and 19 threads, so both config entries matched
  - Recal BAM `@RG`: one record per lane with original IDs; no duplicate
    `@PG` IDs
  - Per-contig read counts in `md.bam` and `recal.bam` match on every
    contig except `hs37d5`; duplicate flags are preserved
- **Run 2** (final release code, SM/LB swap): 409 tasks completed and 74
  cached (FASTP, FASTQC, interval preparation), none failed; all 312 BWA
  tasks ran fresh
  - All four BAMs: 13 `@RG` records, each `SM:<sample>`,
    `LB:<patient>_<sample>`; ID, PU, DS and PL unchanged
  - Every bwa `@PG` command line carries the swapped read group; `-B 3`
    on all tumor tasks, none on normal
  - Mapped and unmapped read counts and chr22 duplicate count identical to
    run 1, so the swap changed only the tags
  - Every `.bai` newer than its BAM; no "index file is older" warning
  - No CRAM or CRAI files
- **`tests/read_group/run.sh`**: all 16 checks pass. With the swap broken
  on purpose, all 5 `@RG` checks fail, so the test detects it

### Recommendations
- Update any downstream scripts that expect CRAM files or
  `.md.cram.metrics` names
- Run `git submodule update` after checking out this release so `sarek/`
  moves to 3.9.0
- Stay on Nextflow 25.10.x
- Do not use the retired scripts in `bin/attic/` on 4.0.0 BAMs
- After any Sarek update, run `tests/read_group/run.sh` and re-check
  `config/read_group.config` against Sarek's `aligner.config`

---

## [3.1.0] - 2026-08-09

**Sarek Submodule**: nf-core/sarek v3.7.1 (official), commit 20f41d1ce
(unchanged from v3.0.0)

### Added
- **Picard CollectInsertSizeMetrics**: New `bin/collectInsertSizeMetrics.sh`
  for insert-size QC on BAM files
  - Writes metrics table and histogram PDF to `out/metrics/$SID`
  - Rejects CRAM input up front (use `sarekCramToBam.sh` first)
  - Unknown cluster is a hard error (PICARD_JAR must be set)

### Fixed
- **Duplicate @RG/@PG Records in Merged CRAMs**: MERGE_CRAM now passes
  `-c -p` to samtools merge on iris and neo
  - Its inputs are interval slices of a single sample, so their @RG/@PG IDs
    collide by construction; without `-c -p` samtools merge kept one copy per
    interval under uniquified IDs and rewrote RG:Z on every read
  - This is the real fix for the duplicate header records that
    `bin/fix_sarek_headers.py` used to delete after the fact
- **WGS Read Length Estimate**: `collectWgsMetrics.sh` samples 100,000 reads
  (was 10,000) and rounds average read length to nearest integer
- **Iris MarkDuplicates Timeouts**: GATK4_MARKDUPLICATES time schedule is now
  `48.h + 24.h * attempt` (attempt 1: 72h, was 42h)
- **Neo MarkDuplicates I/O**: Raised MAX_RECORDS_IN_RAM to 80M and
  SORTING_COLLECTION_SIZE_RATIO to 0.30 (matching iris)
- **Neo FASTP Retries**: FASTP CPUs/memory/time now scale with `task.attempt`

### Changed
- **Nextflow Version Cap**: Require Nextflow >= 25.10.2 and < 26.0.0
  - `00.SETUP.sh` pins `NXF_VER=25.10.4` for reproducible installs
  - `iris.config` / `neo.config` set
    `manifest.nextflowVersion = '!>=25.10.2, <26.0.0'`, so a 26.x runtime
    aborts at launch
  - Nextflow 26 (26.04) makes the v2 strict syntax parser the default and
    tightens type handling; pipelines written against v1 syntax, including
    Sarek 3.7.1, do not run under it
- **Iris SLURM Partition**: `cmobic_pipeline` removed from `iris.config` and
  utility scripts; `iris.config` now submits to `cmobic_cpu`
- **JUNO Picard**: Metrics scripts use Picard 3.4.0 on JUNO (was 2.25.5),
  matching IRIS
- **`bin/fix_sarek_headers.py`**: Writes the fixed header to stdout instead of
  inventing a `.headfix.sam` filename; `sarekCramToBam.sh` now redirects
  - Reports the number of swapped @RG records on stderr and exits non-zero if
    there were none, so a Sarek change that stops putting the sample name in
    LB fails loudly instead of producing a mislabelled BAM
- **`bin/collectAlignmentSummaryMetrics.sh`**: Added the missing usage block

### Removed
- **@PG Deduplication Hack**: `bin/fix_sarek_headers.py` no longer drops @PG
  records with duplicate CL tags
  - Rewriting a BAM header to hide a pipeline bug was the wrong fix: it left
    the alignment records pointing at the uniquified IDs, and it reordered the
    @PG records, breaking the PP chain
  - The duplicates are gone at the source (see the MERGE_CRAM fix above), so
    there is nothing left to deduplicate. Do not reintroduce this
  - The script now does one thing: swap SM and LB in @RG records
- **`bin/sam_header_editor.py`**: Deleted; it existed only to support the
  deduplication hack and had no other caller in the repository
  (supersedes the entry under [2.2.0])

### Recommendations
- Re-run `00.SETUP.sh` (or install Nextflow 25.10.4) for a pinned runtime
- Do **not** upgrade to Nextflow 26.x; stay on 25.10.x
- Prefer the MERGE_CRAM fix over any post-hoc header rewriting for RG/PG issues
- Use `collectInsertSizeMetrics.sh` alongside existing WGS/alignment metrics

---

## [3.0.0] - 2026-01-02

**Sarek Submodule**: nf-core/sarek v3.7.1 (official), commit 20f41d1ce

### BREAKING CHANGES
- **Nextflow Version**: Now requires Nextflow >= 25.10.2 (previously >= 23.04.0)
- **Sarek Source**: Migrated from soccin/sarek fork to official nf-core/sarek repository
- **Sarek Version**: Updated from v3.4.4-A to v3.7.1 (3 minor versions jump)

### Added
- **GRCh37 Intervals File**: Local BED format intervals file for GRCh37 genome
  - Location: `config/intervals/wgs_calling_regions_Sarek.GRCh37.bed`
  - Workaround for upstream nf-core/sarek validation bug
- **Intervals Documentation**: README in config/intervals/ explaining format conversion
- **SINGULARITY_CACHEDIR**: Explicit cache directory setting for Singularity (JUNO cluster)

### Changed
- **Sarek Submodule URL**: Changed from git@github.com:soccin/sarek.git to git@github.com:nf-core/sarek.git
- **Sarek Version**: v3.4.4-A → v3.7.1
  - Includes upstream bug fix #1622 (bcf_annotations stalling)
  - Adds UMI support, Parabricks, MuSE, MSISensor2, Varlociraptor (v3.6.0)
  - Adds VCF filtering and consensus calling (v3.7.0)
  - Improves MultiQC reporting (v1.32)
  - Updates GATK to v4.6.1.0
- **JUNO Cluster Paths**: Updated NXF_SINGULARITY_CACHEDIR path
  - Old: /rtsess01/compute/juno/bic/ROOT/opt/singularity/cachedir_socci
  - New: /juno/bic/work/socci/opt/singularity/cachedir_socci
- **Nextflow Binary**: Updated to v25.10.2

### Fixed
- **GRCh37 Intervals Validation**: Converted .list format to .bed format
  - nf-core/sarek v3.7.1 has validation bug: only accepts .bed/.interval_list but GRCh37 config references .list file
  - Created local BED format file with proper 0-based coordinates
  - Automatic usage via runSarekHuman.sh for GRCh37 genome
- **Singularity Cache**: Explicit SINGULARITY_CACHEDIR prevents fallback to old cache locations

### Upstream Bugs Documented
This release includes workarounds for bugs in nf-core/sarek v3.7.1:
1. **Issue**: GRCh37 intervals validation fails
   - **Root Cause**: Schema requires .bed or .interval_list, but config references .list file
   - **Workaround**: Local BED format conversion, automatic injection via --intervals parameter
2. **File Format Confusion**: .list (chr:start-end, 1-based) is NOT equivalent to .interval_list (Picard format)
   - **Solution**: Proper conversion to BED format (tab-separated, 0-based coordinates)

### Technical Details

#### Sarek Migration Path
- Previous: soccin/sarek fork at v3.4.4-A (commit 25a829b6)
  - Contained critical bug fix #1624 for bcf_annotations.tbi stalling
- Current: Official nf-core/sarek v3.7.1 (commit 20f41d1ce)
  - Bug fix #1624 merged upstream in v3.5.0
  - All custom patches now included in official releases

#### Testing
- **Platform**: JUNO cluster
- **Genome**: GRCh37 (GATK.GRCh37)
- **Pipeline**: WGS mapping mode with base quality score recalibration
- **Status**: Successfully tested, all upstream bugs worked around

#### Migration Notes
- Backup branch created: backup/sarek-3.4.4-A-20260101
- Rollback available if needed
- All configuration files (iris.config, neo.config) verified compatible
- Process names unchanged between versions
- Post-processing scripts remain compatible

### Recommendations
- Update Nextflow to >= 25.10.2 before deploying
- Review new Sarek v3.7.1 features: UMI support, VCF filtering, consensus calling
- Monitor first production runs for unexpected behavior
- Consider quarterly reviews of nf-core/sarek updates

---

## [2.3.0] - 2025-10-22

**Sarek Submodule**: commit 25a829b6, tag 3.4.4-A~1, origin soccin/sarek, branch dev

### Added
- **Multi-Cluster Support**: Added cluster detection and configuration for multiple HPC environments
- **Cluster Detection Utility**: New `getClusterName.sh` script for automatic cluster identification
- **simpleMap2sarek Converter**: Tool to convert simple mapping formats to Sarek input format
- **Picard Alignment Summary Metrics**: New `collectAlignmentSummaryMetrics.sh` tool for QC
- **Manifest Processing Utility**: Added utility for processing sample manifests
- **Cluster-Specific Paths**: Configuration support for genome and tool paths per cluster

### Changed
- **Iris Cluster Configuration**: Updated production settings with proper partition assignments and scratch directory configuration
- **Script Organization**: Moved `getClusterName.sh` to bin directory for better organization
- **simpleMap2sarek Documentation**: Added pairing file support documentation

### Fixed
- **Field Naming**: Renamed fcid to lane in simpleMap2sarek for consistency

### Technical Details

#### Multi-Cluster Infrastructure
The pipeline now supports multiple HPC cluster environments with:
- Automatic cluster detection
- Cluster-specific configuration files (iris.config, neo.config)
- Environment-specific genome and tool path management

#### Iris Cluster Production Configuration
- Updated partition assignment from test01 to cmobic_cpu,cmobic_pipeline
- Configured scratch directory to /localscratch/core001/soccin
- Added detailed comments explaining TMPDIR/scratch handling on IRIS/SLURM

#### New Quality Control Tools
- Picard alignment summary metrics collection
- Enhanced metrics output directory structure

## [2.2.0] - 2025-08-29 - First Official Release

**Sarek Submodule**: commit 25a829b6, tag 3.4.4-A~1, origin soccin/sarek, branch dev

### Fixed
- **SLURM Resource Allocation**: Fixed memory/CPU ratio requirements for SLURM scheduler compatibility
- **TMPDIR Handling**: Updated TMPDIR management in runSarekHuman.sh for proper scratch space allocation
- **Process Resources**: Ensured process resource allocation meets integer constraints required by LSF/SLURM

### Added
- **SAM Header Tools**: Added SAM header editor and fixer scripts for handling Sarek-generated headers
- **Claude Code Integration**: Added Claude Code configuration and documentation (CLAUDE.md)
- **Documentation**: Updated README with correct branch references

### Changed
- **Header Processing**: Updated sarekCramToBam.sh to include Sarek header fixes
- **Script Improvements**: Enhanced collectWgsMetrics.sh SDIR assignment logic
- **Module Loading**: Added samtools module loading in getGenomeBuildBAM.sh

### Technical Details

#### SLURM Configuration Issues Resolved
The iris cluster configuration now properly handles:
- Memory allocation that results in integer values when divided by CPU count
- Process-specific resource settings optimized for GATK tools
- Scratch space management with proper TMPDIR and SINGULARITY_TMPDIR setup

#### Header Processing Enhancements
- `bin/fix_sarek_headers.py`: Fixes issues with Sarek-generated SAM headers
- `bin/sam_header_editor.py`: General-purpose SAM header editing utility
- Integration with CRAM-to-BAM conversion pipeline

## Previous Versions

### [2.1.1] - Previous
- Added B38 genome support

### [2.0.3] - Previous
- Using devs branch of soccin/sarek based on v3.4.4
- Fixed Nextflow compatibility issues
- Updated LSF/SLURM memory configuration requirements

---

**Note**: This is the first official release with proper versioning and changelog tracking. Previous version numbers (2.1.1, 2.0.3) were development versions. For historical changes before v2.2.0, see git commit history.

[4.0.0]: https://github.com/soccin/SMap/releases/tag/v4.0.0
[3.1.0]: https://github.com/soccin/SMap/releases/tag/v3.1.0
[3.0.0]: https://github.com/soccin/SMap/releases/tag/v3.0.0
[2.3.0]: https://github.com/soccin/SMap/releases/tag/v2.3.0
[2.2.0]: https://github.com/soccin/SMap/releases/tag/v2.2.0
