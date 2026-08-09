# SMap

Accessory scripts to run nf-core/sarek in mapping mode. Optimized for WGS samples.

## Version: 3.1.0

Maintenance release: MERGE_CRAM preserves @RG/@PG IDs, simplified BAM header
fixing, CollectInsertSizeMetrics QC tool, cluster/resource tuning, and
Nextflow pinned to 25.10.x (< 26.0.0).

See [VERSION.md](VERSION.md) for the pinned submodule and requirements, and [CHANGELOG.md](CHANGELOG.md) for release notes and version history.

### Requirements
- **Nextflow**: >= 25.10.2 and < 26.0.0 (setup installs 25.10.4)
  - Nextflow 26.x makes the v2 strict syntax parser the default and breaks
    v1-syntax pipelines, Sarek 3.7.1 included. Do not upgrade past 25.x.

## Architecture

This version uses the official nf-core/sarek v3.7.1 with local workarounds for GRCh37 intervals validation bugs.

### Sarek Submodule
- **Commit**: 20f41d1ce
- **Tag**: 3.7.1
- **Origin**: nf-core/sarek (official)
- **Pinned**: submodule tracks the commit above, not a branch

### Memory Configuration Requirements

For LSF compatibility, process memory divided by CPU count must equal integer values:
```
memory/cpus == 1,2,3,...
```
Not needed for SLURM. Also need to set the `JobMem` and `TaskReserve` properly.
Again only for LSF.

### Executor Configuration
```
executor {
  name = "lsf"
  perJobMemLimit = false
  perTaskReserve = true
}
```

For SLURM on IRIS to avoid `/tmp` usage, explicitly set scratch to a
directory (not /tmp) as TMPDIR is not getting properly set on IRIS/SLURM
or set `scratch=false` to use work directory
```
process {
  scratch = "/localscratch/core001/soccin"
  // or scratch=false to use work directory
}
```
