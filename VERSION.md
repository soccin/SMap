# SMap Version Information

## Version:
- tag: 4.0.0
- base-branch: master
- date: 2026-09-23

## Submodules

### sarek
- commit: b97952e5b
- tag: 3.9.0
- origin: nf-core/sarek (official)
- pinned: submodule tracks the commit above, not a branch

## Requirements
- Nextflow: >= 25.10.2 and < 26.0.0 (setup installs 25.10.4)
  - Nextflow 26.x defaults to the v2 strict syntax parser and does not run
    v1-syntax pipelines such as Sarek 3.7.1. The cap is kept for Sarek
    3.9.0, which has not been tested on 26.x
