# SMap

Accessory scripts to run nf-core/sarek in mapping mode. Specializes for WGS samples. 

## Version:

This version tried to fix issue with memory allocation due to the odd setting of `perJobMemLimit = true` which probably should be `perJobMemLimit = false`

Working on new branch with `perJobMemLimit = false` which requires undoing the changes here which is better as they involve only changes to the config files and not the nf-core/module code which is probably a very bad idea.

