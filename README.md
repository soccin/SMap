# SMap

Accessory scripts to run nf-core/sarek in mapping mode. Optimized for WGS samples.

## Version: 3.0.0

Major release migrating to official nf-core/sarek v3.7.1. Includes workarounds for upstream validation bugs.

See [VERSION.md](VERSION.md) for complete version history and [CHANGELOG.md](CHANGELOG.md) for detailed release notes.

### Requirements
- **Nextflow**: >= 25.10.2

## Architecture

This version uses the official nf-core/sarek v3.7.1 with local workarounds for GRCh37 intervals validation bugs.

### Sarek Submodule
- **Commit**: 20f41d1ce
- **Tag**: 3.7.1
- **Origin**: nf-core/sarek (official)
- **Branch**: master

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