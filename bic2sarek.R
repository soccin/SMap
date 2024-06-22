getFastqFiles<-function(fdir,read) {
   fs::dir_ls(fdir,recur=T,regex=paste0("_R",read,"_\\d+.fastq.gz")) %>% sort %>% list
}

require(tidyverse)

argv=commandArgs(trailing=T)

if(len(argv)<1) {
    cat("\n   usage: makeSarekInputSomatic.R SAMPLE_MAPPING.txt\n\n")
    quit()
}

fdir=map(argv[1],read_tsv,col_names=F,show_col_types = FALSE) %>%
    bind_rows %>%
    select(sample=X2,fcid=X3,fdir=X4) %>%
    mutate(sample=gsub("^s_","",sample)) %>%
    mutate(fcid=str_extract(fcid,"[^_]+_[^_]+_(.*)",group=T)) %>%
    rowwise %>%
    mutate(fastq_1=getFastqFiles(fdir,1),fastq_2=getFastqFiles(fdir,2)) %>%
    unnest(cols=c(fastq_1,fastq_2)) %>%
    select(-fdir)

if(!all(gsub("_R1_","_R2_",fdir$fastq_1)==fdir$fastq_2)) {
    cat("\n\nFATAL ERROR R1,R2 mismatch\n\n")
    rlang:abort("FATAL ERROR")
}

mfile=gsub("_sample_mapping.txt","_metadata_samples.csv",argv[1]) %>% gsub(".txt",".csv",.)
manifest=read_csv(mfile,show_col_types = FALSE) %>%
    select(sample=sampleName,patient=cmoPatientId,type=tumorOrNormal) %>%
    mutate(status=ifelse(type=="Tumor",1,0))

sarekInput=left_join(fdir,manifest) %>% 
    mutate(lane=cc(fcid,str_extract(fastq_1,"_(L\\d+)_",group=1))) %>%
    select(patient,sample,status,lane,matches("fastq"))

write_csv(sarekInput,"input_sarek_somatic.csv")

