require(tidyverse)

# Find template manifest file in current directory
manifest_file <- fs::dir_ls(".", regex = "^TEMPLATE_")

# Process manifest: extract patient IDs and classify tumor/normal status
read_csv(manifest_file) |>
  mutate(
    cmo_patient_id = str_extract(sampleName, "(.*)_[NT]\\d+_", group = 1),
    tumor_or_normal = ifelse(grepl("_N\\d\\d_", sampleName), "Normal", "Tumor")
  ) |>
  write_csv(gsub("TEMPLATE__", "", manifest_file))

