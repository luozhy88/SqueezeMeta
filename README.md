# SqueezeMeta
## 仅做功能分析
将SqueezeMeta161_function下的scripts拷贝到*anaconda3/envs/SqueezeMeta161/SqueezeMeta下
## 安装后需要确认数据库是否完整
configure_nodb.pl ../../db

## fq格式要求
_1.fastq.gz 或 _2.fastq.gz
## 要求
跑 SqueezeMeta.pl 需要sample_meta_rm.host/L8337.txt  
跑  sqm_mapper.pl 需要sample_meta/L8337.txt  


## sqm
sed -n "4,10p" run_bash_sqm_no_finished.sh |parallel -j 20 #并行跑5-10行

## create a kegg table
mkdir merge_table  
cat \*/results/12.*.kegg.funcover >merge_table/m12.all.kegg.funcover  
grep -v "Created by " merge_table/m12.all.kegg.funcover > merge_table/m12.all.kegg.funcover.filtered   
awk '!arr[$0]++' merge_table/m12.all.kegg.funcover.filtered  > merge_table/m12.all.kegg.funcover.unique  


