#' Get FASTQ files for a specific read direction
#'
#' @param fdir Directory to search for FASTQ files
#' @param read Read number (1 or 2)
#' @return List containing sorted FASTQ file paths
get_fastq_files <- function(fdir, read) {
  fs::dir_ls(fdir, recur = TRUE, regex = paste0("_R", read, "_\\d+.fastq.gz")) %>%
    sort() %>%
    list()
}

#' Fix or extract flowcell ID from FASTQ header
#'
#' @param fcid Flowcell ID (may be NA)
#' @param fastq_1 Path to R1 FASTQ file
#' @return Valid flowcell ID string
fix_fcid <- function(fcid, fastq_1) {
  if (is.na(fcid)) {
    return(strsplit(readLines(fastq_1, n = 1), ":")[[1]][3])
  } else {
    return(fcid)
  }
}

##############################################################################
# Main execution
##############################################################################

argv <- commandArgs(trailing = TRUE)

if (len(argv) < 1) {
  cat("\n   usage: makeSarekInputSomatic.R SAMPLE_MAPPING.txt\n\n")
  quit()
}

require(tidyverse)

# Read and process sample mapping file(s)
fdir <- map(argv[1], read_tsv, col_names = FALSE, show_col_types = FALSE) %>%
  bind_rows() %>%
  select(sample = X2, fcid = X3, fdir = X4) %>%
  mutate(sample = gsub("^s_", "", sample)) %>%
  mutate(fcid = str_extract(fcid, "[^_]+_[^_]+_(.*)", group = TRUE)) %>%
  rowwise() %>%
  mutate(fastq_1 = get_fastq_files(fdir, 1), fastq_2 = get_fastq_files(fdir, 2)) %>%
  unnest(cols = c(fastq_1, fastq_2)) %>%
  select(-fdir)

# Validate that R1 and R2 files are properly paired
if (!all(gsub("_R1_", "_R2_", fdir$fastq_1) == fdir$fastq_2)) {
  cat("\n\nFATAL ERROR: R1/R2 file mismatch\n\n")
  rlang::abort("FATAL ERROR")
}

# Fix flowcell IDs if needed
fdir <- fdir %>%
  rowwise() %>%
  mutate(fcid = fix_fcid(fcid, fastq_1)) %>%
  ungroup()

# Determine metadata file path
mfile <- gsub("_sample_mapping.txt", "_metadata_samples.csv", argv[1]) %>%
  gsub(".txt", ".csv", .)

# Create metadata template if file doesn't exist
if (!file.exists(mfile)) {
  md <- fdir %>%
    select(sampleName = sample) %>%
    mutate(cmoPatientId = "", tumorOrNormal = "Tumor|Normal") %>%
    distinct(sampleName, cmoPatientId, tumorOrNormal) %>%
    arrange(sampleName)
  MD_TEMPLATE <- cc("TEMPLATE_", mfile)
  write_csv(md, MD_TEMPLATE)
  cat("\n\nMetadata file not found\n")
  cat("Template file created in", MD_TEMPLATE, "\n")
  cat("Please fill in the metadata, rename file to\n")
  cat("\n\t", paste0("[", mfile, "]"), "\n\nand run again\n\n")
  quit()
}

# Read and process metadata
manifest <- read_csv(mfile, show_col_types = FALSE) %>%
  select(sample = sampleName, patient = cmoPatientId, type = tumorOrNormal) %>%
  mutate(status = ifelse(type == "Tumor", 1, 0))

# Combine FASTQ information with metadata to create Sarek input
sarek_input <- left_join(fdir, manifest) %>%
  mutate(lane = cc(fcid, str_extract(fastq_1, "_(L\\d+)_", group = 1))) %>%
  select(patient, sample, status, lane, matches("fastq"))

write_csv(sarek_input, "input_sarek_somatic.csv")

