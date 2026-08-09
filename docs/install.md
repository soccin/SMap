# Installation

## Nextflow

Prefer the repo setup script, which pins a known-good version:

```
./00.SETUP.sh
```

That sets `NXF_VER=25.10.4` before downloading into `bin/`.

SMap requires Nextflow **>= 25.10.2 and < 26.0.0**. Nextflow 26.x breaks
this stack; always pin a 25.10.x release (do not install unpinned latest).

Manual install of a specific 25.10.x version:

```
cd bin
export NXF_VER=25.10.4
curl -s https://get.nextflow.io | bash
```

## Sarek

Sarek is a git submodule (official nf-core/sarek). Clone with
`clone --recurse-submodules` (or your local `clonesub` alias).
If you forgot then do:
```
git submodule update --init
cd sarek
git checkout master
```
