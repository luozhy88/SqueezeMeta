
library(optparse)
library(dplyr)
`%+%` <- function(a,b) {paste0(a,b)}


option_list <- list(
  make_option(c("-f", "--first"), type = "character", default = "Finished!",
              action = "store", help = "This is a abs_path."
  ))
# 解析参数
opt = parse_args(OptionParser(option_list = option_list, usage = "This Script is a test for arguments!"))
print(opt$first)

file_name<-opt$first

test<-read.csv(file_name,header = F,sep = "\t")
#colnames(test)[1] <- "sampleID"
#split_file("test_rm_host.120samples,2")
dir.create("sample_meta")
for (i in unique(test$V1) ){
  df1<-filter(test,V1==i)
  print(df1)
  write.table(df1,"sample_meta/" %+% i %+% ".txt",quote = FALSE,row.names = FALSE,col.names = FALSE,sep="\t")
}
all_str=""
for (i in unique(test$V1) ){
  str1=sprintf("SqueezeMeta.pl -m coassembly -s sample_meta/%s.txt -f /data/zhiyu/save_220T_user/zhiyu/Projects/squeezemeta/sixhop/rm_host -t 60 --nobin -p %s  \n", i,i)
  print(str1) 
  all_str=all_str %+% str1
 
}

print(all_str)
writeLines(all_str,"run_bash.sh")
  
 

