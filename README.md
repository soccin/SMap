# SMap

Accessory scripts to run nf-core/sarek in mapping mode. Optimized for WGS samples.

## Version: 2.3.0

Current release with multi-cluster support, new QC tools, and enhanced format conversion utilities.

See [VERSION.md](VERSION.md) for complete version history and [CHANGELOG.md](CHANGELOG.md) for detailed release notes.

## Architecture

This version uses the dev branch of `soccin/sarek` based on `v3.4.4` with Nextflow compatibility fixes.

### Sarek Submodule
- **Commit**: 25a829b6
- **Tag**: 3.4.4-A~1  
- **Origin**: soccin/sarek
- **Branch**: dev

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

For SLURM on IRIS to make sure the `/tmp` is not used need to set
scratch in process
```
process {
  scratch = false 
}