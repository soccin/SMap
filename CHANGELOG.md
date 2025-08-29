# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

This changelog was created to track recent improvements. For historical changes, see git commit history.