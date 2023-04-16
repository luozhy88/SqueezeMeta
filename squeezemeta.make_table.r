
print("
    example: Rscript /home/zhiyu/data/script/shotgun/squeezemeta.make_table.r -f /data2/zhiyu/database/test.data -s hsa
      ")
library("dplyr")
library(stringr)
library(optparse)

# 描述参数的解析方式
option_list <- list(
  make_option(c("-f", "--first"), type = "character", default = FALSE,
              action = "store", help = "This is first!  raw_fq_dir"
  ),
  make_option(c("-s", "--second"), type = "character", default = FALSE,
              action = "store", help = "This is second! hsa or mmu"
  )

  # make_option(c("-h", "--help"), type = "logical", default = FALSE,
  #             action = "store_TRUE", help = "This is Help!"
  # )
)
# 解析参数
opt = parse_args(OptionParser(option_list = option_list, usage = "This Script is a test for arguments!"))
print(opt$f)
#
#
#
rawfq_path<-opt$f
source<-opt$s

# rawfq_path<-"/data2/zhiyu/test.data/shotgun"
# source="hsa"



host_hsa<-"/data_bk/yizhou/database/squeezemeta_databases/db/hosts/Homo_sapiens.GRCh38.dna_rm.primary_assembly.fa.gz"
host_mmu<-"/data_bk/yizhou/database/squeezemeta_databases/db/hosts/Mus_musculus.GRCm39.dna_rm.primary_assembly.fa.gz"
host<-ifelse(source=="hsa",host_hsa,host_mmu)
files<-list.files(rawfq_path,pattern="q.gz")
# ID<- stringr::word(files ,1,1,sep="_[1|2].fastq.gz"  ) 
ID<- stringr::word(files ,1,1,sep="_"  ) 
# pair<-purrr::map_chr(files,)
tidy_df<-data.frame(ID=ID,files=files)

tidy_df$pair <- dplyr::case_when(
                               grepl("_1.fastq.gz|R1_001.fastq.gz",tidy_df$files) ~ "pair1",
                               grepl("_2.fastq.gz|R2_001.fastq.gz",tidy_df$files) ~ "pair2" )
write.table(tidy_df,"test.sample",row.names = F,col.names = F,quote = F,sep = "\t")


tidy_df$files <- gsub("fastq.gz","filtered.fastq.gz",tidy_df$files)

write.table(tidy_df,"test.sample.rm_host",row.names = F,col.names = F,quote = F,sep = "\t")





rm_host_str<-sprintf("sqm_mapper.pl -r %s -s test.sample -f %s -o rm_host --filter -t 50 \n",host,rawfq_path)
SqueezeMeta.pl_str<-sprintf("SqueezeMeta.pl -m seqmerge -p PJ1 -s test.sample.rm_host -f  rm_host  -miniden 50 -t 100 \n")
out.str<-paste(rm_host_str,SqueezeMeta.pl_str)
writeChar(out.str,"run.sh")



