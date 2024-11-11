# SMap

Accessory scripts to run nf-core/sarek in mapping mode. Optimized for WGS samples. 

## Version: 2.0.1

This version is using the devs branch of `soccin/sarek`. Stay on this branch so my work hopefully does not get broadcasted on the `nfcore/sarek` repo. This version of `sarek` is based on `v3.4.4` but fixes a bug that occurs with the latest version of nextflow.

This version has an updated version of `config/neo.config` that is fixed to work with JUNO's LSF config specificially the memory settings. To get things to work properly we set:
```
executor {
  name = "lsf"
  perJobMemLimit = false
  perTaskReserve = true
}
```
*N.B.*, In the process blocks `memory` is **TOTAL MEMORY** which will get divided by the number of cpus. There appears to be a constraint that this needs to be an integer, i.e.;
```
	memory/cpus == 1,2,3,...
```
