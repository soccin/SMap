# Changelog

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

[2.3.0]: https://github.com/soccin/SMap/releases/tag/v2.3.0
[2.2.0]: https://github.com/soccin/SMap/releases/tag/v2.2.0