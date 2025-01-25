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

fix_fcid<-function(fcid,fastq_1) {
    if(is.na(fcid)) {
        return(strsplit(readLines(fastq_1,n=1),":")[[1]][3])
    } else {
        return(fcid)
    }
}

fdir = fdir %>% rowwise %>% mutate(fcid=fix_fcid(fcid,fastq_1)) %>% ungroup

mfile=gsub("_sample_mapping.txt","_metadata_samples.csv",argv[1]) %>% gsub(".txt",".csv",.)

if(!file.exists(mfile)) {
    md=fdir %>% 
        select(sampleName=sample) %>%
        mutate(cmoPatientId="",tumorOrNormal="Tumor|Normal")
    MD_TEMPLATE=cc("TEMPLATE_",mfile)
    write_csv(md,MD_TEMPLATE)
    cat("\n\nMetadata file not found\n")
    cat("Template file created in",MD_TEMPLATE,"\n")
    cat("Please fill in the metadata, rename file to\n")
    cat("\n\t",paste0("[",mfile,"]"),"\n\nand run again\n\n")
    quit()
}

manifest=read_csv(mfile,show_col_types = FALSE) %>%
    select(sample=sampleName,patient=cmoPatientId,type=tumorOrNormal) %>%
    mutate(status=ifelse(type=="Tumor",1,0))

sarekInput=left_join(fdir,manifest) %>% 
    mutate(lane=cc(fcid,str_extract(fastq_1,"_(L\\d+)_",group=1))) %>%
    select(patient,sample,status,lane,matches("fastq"))

write_csv(sarekInput,"input_sarek_somatic.csv")

