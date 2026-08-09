# Installation

## Nextflow

Prefer the repo setup script, which pins a known-good version:

```
./00.SETUP.sh
```

That sets `NXF_VER=25.10.4` before downloading into `bin/`.

SMap requires Nextflow **>= 25.10.2 and < 26.0.0**. Always pin a 25.10.x
release; do not install unpinned latest.

Nextflow 26 (26.04) makes the v2 strict syntax parser the default and
tightens type handling. Pipelines written against v1 syntax, Sarek 3.7.1
included, do not run under it. This is not a wait-and-retest situation:
26.x requires the pipeline itself to be ported.

Manual install of a specific 25.10.x version:

```
cd bin
export NXF_VER=25.10.4
curl -s https://get.nextflow.io | bash
```

## Sarek

Sarek is a git submodule (official nf-core/sarek), pinned to the commit
recorded in this repo. Clone with:

```
git clone --recurse-submodules <url>
```

(aliased to `clonesub` in my gitconfig:
`git config --global alias.clonesub "clone --recurse-submodules"`)

If you already cloned without it:

```
git submodule update --init
```

That checks out the pinned Sarek commit. Do **not** `cd sarek` and check out
a branch: that moves the submodule off the pinned commit and you are no
longer running the version this release was tested against. See VERSION.md
for the pinned tag.
