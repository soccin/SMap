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

### Data Processing Utilities
- `bin/sarekCramToBam.sh` - Converts CRAM files to BAM format with header fixes
- `bin/collectWgsMetrics.sh` - Runs Picard CollectWgsMetrics for quality assessment
- `bin/getGenomeBuildBAM.sh` - Determines genome build from BAM/CRAM headers
- `bin/fix_sarek_headers.py` - Python script for fixing Sarek-generated SAM headers
- `bin/sam_header_editor.py` - General SAM header editing utility
- `bin/bic2sarek.R` - R script for format conversion to Sarek input format
- `bin/cleanup.sh` - Cleanup utilities

## Configuration

### Cluster Configurations
- `config/iris.config` - SLURM configuration for iris cluster
  - Memory allocation rules: memory/cpus must equal integer values
  - Process-specific resource settings for GATK tools
  - Optimized for WGS samples with high memory requirements
- `config/neo.config` - Alternative cluster configuration

### Key Configuration Parameters
- Uses Singularity profile by default
- Scratch space management with `TMPDIR` and `SINGULARITY_TMPDIR`
- Process memory scaling based on attempt number
- Specific optimizations for GATK4_MARKDUPLICATES (up to 352GB + 160GB per retry)

## Architecture

### Directory Structure
- `bin/` - Utility scripts and Nextflow binary
- `config/` - Cluster-specific configuration files  
- `sarek/` - nf-core/sarek submodule (forked version based on v3.4.4)
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
- Version branches: `ver/{version}` (e.g., `ver/1.5.0`)

### Current Branches
- `devs/iris` - Iris cluster customizations (current branch)
- `devs/juno` - Juno cluster configuration
- `devs/juno-old` - Legacy branch preserved
- `ver/1.5.0` - Version 1.5.0 release

### Commit Message Format
Use conventional commits with scopes: `type(scope): description`
- Types: feat, fix, docs, style, refactor, test, chore  
- Scopes: sarek, pipeline, docs, scripts, conf

### Version Information
- Current branch: devs/iris (customized for iris cluster)
- Based on Sarek v3.4.4 with Nextflow compatibility fixes
- Uses soccin/sarek dev branch to avoid broadcasting changes

### Memory Management
Critical constraint: process memory divided by CPU count must be an integer value for LSF/SLURM compatibility. This affects resource allocation in config files.

## Dependencies
- Nextflow
- Singularity/Apptainer
- SLURM scheduler
- Samtools module
- Picard tools
- GATK4
