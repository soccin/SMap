# SMap

Accessory scripts to run nf-core/sarek in mapping mode. Optimized for WGS samples.

## Version: 4.0.0

Major release: Sarek outputs BAM directly. No CRAM files are written or
published. Built on nf-core/sarek 3.9.0, which fixes the
`--save_output_as_bam` bug in 3.7.1 that lost the recalibrated BAMs.

Output (per sample, under `sbam/preprocessing/`):
- `markduplicates/<id>/<id>.md.bam` and `.md.bam.bai`
- `recalibrated/<id>/<id>.recal.bam` and `.recal.bam.bai` (not with `-s`)

Read groups are `SM:<sample>`, `LB:<patient>_<sample>`, the reverse of
what Sarek writes. The swap happens at alignment
(`config/read_group.config`); no post-processing is needed. After any
Sarek update, run `tests/read_group/run.sh`.

The old post-processing scripts (`sarekCramToBam.sh`,
`fix_sarek_headers.py`) are retired to `bin/attic/`. Do not use them.

See [VERSION.md](VERSION.md) for the pinned submodule and requirements, and [CHANGELOG.md](CHANGELOG.md) for release notes and version history.

### Requirements
- **Nextflow**: >= 25.10.2 and < 26.0.0 (setup installs 25.10.4)
  - Nextflow 26.x makes the v2 strict syntax parser the default and breaks
    v1-syntax pipelines, Sarek 3.7.1 included. The cap is kept for Sarek
    3.9.0, which has not been tested on 26.x. Do not upgrade past 25.x.

## Architecture

This version uses the official nf-core/sarek v3.9.0 with local workarounds for GRCh37 intervals validation bugs.

### Sarek Submodule
- **Commit**: b97952e5b
- **Tag**: 3.9.0
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
