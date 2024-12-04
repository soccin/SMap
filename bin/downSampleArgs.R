suppressPackageStartupMessages({require(tidyverse)})

if(file.exists("listOfBams")) {
    bamFiles=scan("listOfBams","",quiet=T)
} else {
    bamFiles=fs::dir_ls(recur=3,regex="sbam$") %>%
        map(fs::dir_ls,recur=T,regex="smap.bam$") %>%
        unlist %>%
        unname
}

bams=tibble(BAM=bamFiles) %>%
    mutate(SAMPLE=basename(dirname(BAM)))

cov=fs::dir_ls("out/metrics",recur=T,regex=".wgs.txt$") %>%
    map(read_tsv,comment="#",n_max=1,show_col_types = FALSE,progress=F) %>%
    bind_rows(.id="SAMPLE") %>%
    mutate(SAMPLE=basename(dirname(SAMPLE))) %>%
    select(SAMPLE,MEAN_COVERAGE) %>%
    mutate(TYPE=ifelse(grepl(".N$",SAMPLE),"Normal","Tumor")) %>%
    mutate(P=pmin(1,ifelse(TYPE=="Normal",30,60)/MEAN_COVERAGE))

argv=left_join(bams,cov,by = join_by(SAMPLE)) %>% select(BAM,P)

for(ai in transpose(argv)) {

    cat(ai$BAM,ai$P,"\n")

}
