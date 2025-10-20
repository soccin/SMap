#' Extract lane identifier from FASTQ file
#'
#' Reads the first line of a FASTQ file and extracts flow cell ID and lane number
#' from the Illumina header format.
#'
#' @param fastq_file Path to FASTQ file
#' @return Lane identifier string in format "AXXXX_LNNN"
get_lane <- function(fastq_file) {
  desc <- (readLines(fastq_file, 1) |> strsplit(":"))[[1]]
  sprintf("A%s_L%03d", desc[3], as.numeric(desc[4]))
}

#' Convert R1 FASTQ filename to R2 filename
#'
#' @param fq1 R1 FASTQ filename
#' @return Corresponding R2 FASTQ filename
sub_r1_r2 <- function(fq1) {
  r1_pattern <- str_extract(fq1, "L\\d+_R1_\\d+\\.fastq\\.gz$")
  r2_pattern <- gsub("_R1_", "_R2_", r1_pattern)
  gsub(r1_pattern, r2_pattern, fq1)
}

argv <- commandArgs(trailing = TRUE)

if (len(argv) < 2) {
  cat("\nUsage: simpleMap2sarek.R SIMPLE_MAP.CSV PAIRING.CSV\n\n")
  cat("Converts sample mapping and pairing files to Sarek somatic input format.\n\n")
  cat("Input files:\n")
  cat("  SIMPLE_MAP.CSV (no headers):\n")
  cat("    Column 1: SAMPLE_ID\n")
  cat("    Column 2: FASTQ_1 (R1 file path)\n\n")
  cat("  PAIRING.CSV (no headers):\n")
  cat("    Column 1: PATIENT_ID\n")
  cat("    Column 2: NORMAL_SAMPLE_ID\n")
  cat("    Column 3: TUMOR_SAMPLE_ID\n\n")
  cat("Output: input_sarek_somatic.00.csv\n\n")
  quit()
}

require(tidyverse)

# Load and transform pairing information
pair0 <- read_csv(
  argv[2],
  col_names = c("patient", "normal", "tumor"),
  show_col_types = FALSE
) |>
  gather(type, sample, -patient) |>
  mutate(status = ifelse(type == "normal", 0, 1)) |>
  select(-type)

# Load sample mapping and generate Sarek input format
map0 <- read_csv(argv[1], col_names = FALSE, show_col_types = FALSE) |>
  rename(sample = X1, fastq_1 = X2) |>
  rowwise() |>
  mutate(lane = get_lane(fastq_1)) |>
  left_join(pair0, by = "sample") |>
  select(patient, sample, status, lane, fastq_1) |>
  mutate(fastq_2 = sub_r1_r2(fastq_1)) |>
  arrange(sample, lane)

# Validate R1/R2 filename pairing
if (!all(gsub("_R1_", "_R2_", map0$fastq_1) == map0$fastq_2)) {
  cat("\n\nFATAL ERROR: R1/R2 filename mismatch\n\n")
  rlang::abort("FATAL ERROR")
}

write_csv(map0, "input_sarek_somatic.00.csv")
