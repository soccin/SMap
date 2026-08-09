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

### Setup and Installation
- `00.SETUP.sh` - Downloads and installs Nextflow binary to `bin/` directory
  - Pins Nextflow via `NXF_VER=25.10.4` (must stay >= 25.10.2 and < 26.0.0)

### Data Processing Utilities
- `bin/sarekCramToBam.sh` - Converts CRAM files to BAM format with header fixes
- `bin/collectWgsMetrics.sh` - Runs Picard CollectWgsMetrics for quality assessment
- `bin/collectAlignmentSummaryMetrics.sh` - Picard CollectAlignmentSummaryMetrics
- `bin/collectInsertSizeMetrics.sh` - Picard CollectInsertSizeMetrics (BAM only)
- `bin/getGenomeBuildBAM.sh` - Determines genome build from BAM/CRAM headers
- `bin/fix_sarek_headers.py` - Swaps the SM and LB tags in @RG records of a Sarek SAM header (Sarek puts the sample name in LB); writes to stdout
- `bin/bic2sarek.R` - R script for format conversion to Sarek input format
- `bin/cleanup.sh` - Cleanup utilities

## Configuration

### Cluster Configurations
- `config/iris.config` - SLURM configuration for iris cluster
  - Default partition: `cmobic_cpu`
  - Memory allocation rules: memory/cpus must equal integer values
  - Process-specific resource settings for GATK tools
  - Optimized for WGS samples with high memory requirements
  - MERGE_CRAM uses samtools `ext.args = "-c -p"` to preserve @RG/@PG IDs
  - Enforces `manifest.nextflowVersion = '!>=25.10.2, <26.0.0'`
- `config/neo.config` - Alternative cluster configuration (JUNO/LSF)
  - MERGE_CRAM likewise uses `-c -p`
  - Same Nextflow version constraint as iris

### Key Configuration Parameters
- Uses Singularity profile by default
- Scratch space management with `TMPDIR` and `SINGULARITY_TMPDIR`
- Process memory scaling based on attempt number
- Specific optimizations for GATK4_MARKDUPLICATES (up to 352GB + 160GB per retry)

## Architecture

### Directory Structure
- `bin/` - Utility scripts and Nextflow binary
- `config/` - Cluster-specific configuration files
- `sarek/` - nf-core/sarek submodule (official v3.7.1)
- `sbam/` - Default output directory for processed BAM files
- `out/metrics/` - Quality metrics output directory

### Pipeline Flow
1. Input validation and parameter parsing
2. Environment setup (paths, temp directories, caches)
3. Nextflow execution with Sarek pipeline
4. Optional post-processing (CRAM to BAM conversion, metrics collection)

## Development Notes

### Branch Naming Convention
Follow these naming patterns for branches:
- Development branches: `devs/{topic}` (e.g., `devs/iris`, `devs/juno`)
- Feature/fix branches: `feat/{topic}`, `fix/{topic}`
- Release branches: `rel/v{version}` (e.g., `rel/v3.1.0`)

### Current Branches
- `master` - Stable release line
- `rel/v3.1.0` - Release preparation for v3.1.0
- `devs/iris` - Iris cluster customizations
- `devs/juno` - Juno cluster configuration

### Commit Message Format
Use conventional commits with scopes: `type(scope): description`
- Types: feat, fix, docs, style, refactor, test, chore
- Scopes: sarek, pipeline, docs, scripts, conf

### Version Information
- Current release line: v3.1.0 on official nf-core/sarek v3.7.1
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
