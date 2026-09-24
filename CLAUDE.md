# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

SMap is a collection of accessory scripts for running nf-core/sarek in mapping mode, optimized for WGS samples on HPC clusters. This is a bioinformatics pipeline wrapper that uses Nextflow and Singularity for WGS sequencing data processing.

## Key Scripts and Usage

### Main Pipeline Execution
- `runSarekHuman.sh` - Primary script for running Sarek pipeline
  - Usage: `runSarekHuman.sh [-g|--genome GATK.GRCh37|GATK.GRCh38] [-s|--skip_bsqr] input_sarek.csv`
  - Supports GRCh37 (default) and GRCh38 genomes
  - Uses Singularity containers and SLURM scheduler
  - Creates temporary working directories and manages environment variables
  - Passes `--save_output_as_bam`: Sarek publishes BAM only, never CRAM
    (`md.bam` under `markduplicates/`, `recal.bam` under `recalibrated/`)
  - Touches all `*.bai` under `$ODIR/preprocessing` after the run so each
    index is newer than its BAM

### Setup and Installation
- `00.SETUP.sh` - Downloads and installs Nextflow binary to `bin/` directory
  - Pins Nextflow via `NXF_VER=25.10.4` (must stay >= 25.10.2 and < 26.0.0)

### Data Processing Utilities
- `bin/collectWgsMetrics.sh` - Runs Picard CollectWgsMetrics for quality assessment
- `bin/collectAlignmentSummaryMetrics.sh` - Picard CollectAlignmentSummaryMetrics
- `bin/collectInsertSizeMetrics.sh` - Picard CollectInsertSizeMetrics
- All metrics scripts take BAM only and name output by the `SM` tag
  (the sample name in SMap 4.0.0 BAMs)
- `bin/getGenomeBuildBAM.sh` - Determines genome build from BAM headers
- `tests/read_group/run.sh` - Regression test for `config/read_group.config`; runs Sarek's real BWA_MEM module and checks the @RG. Run after every Sarek update
- `bin/bic2sarek.R` - R script for format conversion to Sarek input format
- `bin/cleanup.sh` - Cleanup utilities

## Configuration

### Cluster Configurations
- `config/read_group.config` - Included by iris and neo. Replaces Sarek's
  BWA `ext.args` (same selector as `sarek/conf/modules/aligner.config`)
  so bwa writes `SM:<sample>`, `LB:<patient>_<sample>` (Sarek writes the
  reverse). Stops the run if there is no SM/LB pair to swap. Must be
  re-checked against `aligner.config` on every Sarek update
- `config/iris.config` - SLURM configuration for iris cluster
  - Default partition: `cmobic_cpu`
  - Memory allocation rules: memory/cpus must equal integer values
  - Process-specific resource settings for GATK tools
  - Optimized for WGS samples with high memory requirements
  - The BQSR MERGE_BAM uses samtools `ext.args = "-c -p"` to preserve
    @RG/@PG IDs
  - GATK4_MARKDUPLICATES `ext.args` replaces Sarek's, so it re-adds
    `--CREATE_INDEX true` when `--save_output_as_bam` is set; without it
    no `.bai` is written and the run fails
  - Enforces `manifest.nextflowVersion = '!>=25.10.2, <26.0.0'`
- `config/neo.config` - Alternative cluster configuration (JUNO/LSF)
  - MERGE_BAM likewise uses `-c -p`
  - Same GATK4_MARKDUPLICATES `--CREATE_INDEX` handling as iris
  - Same Nextflow version constraint as iris

### Key Configuration Parameters
- Uses Singularity profile by default
- Scratch space management with `TMPDIR` and `SINGULARITY_TMPDIR`
- Process memory scaling based on attempt number
- Specific optimizations for GATK4_MARKDUPLICATES (up to 352GB + 160GB per retry)

## Architecture

### Directory Structure
- `bin/` - Utility scripts and Nextflow binary
- `bin/attic/` - Retired scripts, not used since 4.0.0; do not use or
  reference them: `sarekCramToBam.sh` (CRAM to BAM with header fix) and
  `fix_sarek_headers.py` (SM/LB swap). The swap is now done at alignment
  by `config/read_group.config`, and running it again would undo it
- `config/` - Cluster-specific configuration files
- `sarek/` - nf-core/sarek submodule (official v3.9.0)
- `sbam/` - Default output directory for processed BAM files
- `out/metrics/` - Quality metrics output directory

### Pipeline Flow
1. Input validation and parameter parsing
2. Environment setup (paths, temp directories, caches)
3. Nextflow execution with Sarek pipeline
4. Touch published `.bai` files
5. Optional post-processing (metrics collection)

## Development Notes

### Branch Naming Convention
Follow these naming patterns for branches:
- Development branches: `devs/{topic}` (e.g., `devs/iris`, `devs/juno`)
- Feature/fix branches: `feat/{topic}`, `fix/{topic}`
- Release branches: `rel/v{version}` (e.g., `rel/v4.0.0`)

### Current Branches
- `master` - Stable release line
- `rel/v4.0.0` - Release preparation for v4.0.0
- `devs/sarek-3.9.0` - Sarek 3.9.0 update and BAM output (merged into `rel/v4.0.0`)
- `fix/rg-sm-lb` - SM/LB swap at alignment (merged into `rel/v4.0.0`)
- `devs/iris` - Iris cluster customizations
- `devs/juno` - Juno cluster configuration

### Commit Message Format
Use conventional commits with scopes: `type(scope): description`
- Types: feat, fix, docs, style, refactor, test, chore
- Scopes: sarek, pipeline, docs, scripts, conf

### Version Information
- Current release line: v4.0.0 on official nf-core/sarek v3.9.0
- Nextflow: >= 25.10.2 and < 26.0.0 (setup pins 25.10.4; 26.x is incompatible)
- See VERSION.md and CHANGELOG.md for release details

### Memory Management
Critical constraint: process memory divided by CPU count must be an integer value for LSF/SLURM compatibility. This affects resource allocation in config files.

## Dependencies
- Nextflow (>= 25.10.2, < 26.0.0)
- Singularity/Apptainer
- SLURM scheduler (iris) / LSF (neo/JUNO)
- Samtools module
- Picard tools
- GATK4
