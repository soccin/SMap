# Changelog

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

[2.3.0]: https://github.com/soccin/SMap/releases/tag/v2.3.0
[2.2.0]: https://github.com/soccin/SMap/releases/tag/v2.2.0