# SMap Version Information

## Version:
- tag: 3.1.0
- base-branch: master
- date: 2026-08-09

## Submodules

### sarek
- commit: 20f41d1ce
- tag: 3.7.1
- origin: nf-core/sarek (official)
- pinned: submodule tracks the commit above, not a branch

## Requirements
- Nextflow: >= 25.10.2 and < 26.0.0 (setup installs 25.10.4)
  - Nextflow 26.x defaults to the v2 strict syntax parser and does not run
    v1-syntax pipelines such as Sarek 3.7.1
