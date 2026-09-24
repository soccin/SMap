# CLAUDE.md

SMap: wrapper scripts and cluster configs for running nf-core/sarek in
mapping mode (WGS) on IRIS (SLURM) and JUNO (LSF).

## Rules
- BAM only: do not add CRAM output or CRAM handling anywhere.
- `bin/attic/` holds retired scripts (`sarekCramToBam.sh`,
  `fix_sarek_headers.py`). Do not use or reference them: the SM/LB swap
  is done at alignment by `config/read_group.config`, and running them
  would swap the tags back.
- Nextflow must stay >= 25.10.2 and < 26.0.0; 26.x is incompatible.
- Process memory divided by CPU count must be an integer (LSF/SLURM).

## Config gotchas
- `iris.config` and `neo.config` replace Sarek's `GATK4_MARKDUPLICATES`
  `ext.args`, which drops Sarek's own flags. They re-add
  `--CREATE_INDEX true` for BAM output; without it no `.bai` is written
  and the run fails.
- The BQSR `MERGE_BAM` needs samtools `-c -p` to keep the @RG/@PG IDs.

## After every Sarek update
- Re-check `config/read_group.config` against
  `sarek/conf/modules/aligner.config`: it replaces Sarek's BWA
  `ext.args` using the same selector.
- Run `tests/read_group/run.sh`.

## Git
- Branches: `devs/{topic}`, `feat/{topic}`, `fix/{topic}`,
  `rel/v{version}`.
- Commits: conventional, `type(scope): description`. Types: feat, fix,
  docs, style, refactor, test, chore. Scopes: sarek, pipeline, docs,
  scripts, conf.
