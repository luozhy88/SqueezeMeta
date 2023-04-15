#!/usr/bin/env perl

#-- Part of SqueezeMeta distribution. 01/11/2018 Version 0.3.1, (c) Javier Tamames, CNB-CSIC
#-- Runs DasTool for combining binning results

use strict;
use Cwd;
use lib ".";

$|=1;

my $pwd=cwd();
my $projectdir=$ARGV[0];
if(!$projectdir) { die "Please provide a valid project name or project path\n"; }
if(-s "$projectdir/SqueezeMeta_conf.pl" <= 1) { die "Can't find SqueezeMeta_conf.pl in $projectdir. Is the project path ok?"; }
do "$projectdir/SqueezeMeta_conf.pl";
our($projectname);
my $project=$projectname;

do "$projectdir/parameters.pl";

#-- Configuration variables from conf file

our($installpath,$datapath,$databasepath,$resultpath,$interdir,$binresultsdir,$binners,$aafile,$contigsfna,$contigcov,$dastool_soft,$alllog,$tempdir,$methodsfile,$score_tres15,$numthreads,$syslogfile);

open(outsyslog,">>$syslogfile") || warn "Cannot open syslog file $syslogfile for writing the program log\n";

my $daspath="$interdir/binners/DAS";
if(-d $daspath) {system("rm -r $daspath/*"); } else { system("mkdir $daspath"); }
if(-d $binresultsdir) { system "rm $binresultsdir/*"; } else { system "mkdir $binresultsdir"; }

#-- Creating contigs in bins tables

print "Creating tables of contigs in bins... ";
my($tables,$methods,$thiseq,$numbinmethods);
my @files;
my @binner=split(/\,/,$binners);

foreach my $binmethod(@binner) {
	print "  Using results from $binmethod\n";
	my $bindir="$interdir/binners/$binmethod";
	opendir(indir1,$bindir) || die "Can't open $bindir directory\n";
	my @fastafiles=grep(/fasta$|fa$/,readdir indir1);
	closedir indir1;
	if($#fastafiles<0) { print "No results for $binmethod, skipping\n"; next; }	#-- This indicates that for some reason the binning for that method failed
	$numbinmethods++;
	$tables.="$daspath/$binmethod.table,";
	$methods.="$binmethod,";
	print outsyslog "Creating abundance file in $daspath/$binmethod.table\n";
	open(outfile1,">$daspath/$binmethod.table") || die "Can't open $daspath/$binmethod.table for writing\n";
	foreach my $tfil(@fastafiles) {
		my $bin=$tfil;
		$bin=~s/\.fa.tax|\.fasta.tax//g;
		open(infile1,"$bindir/$tfil") || die "Can't open $bindir/$tfil\n";
		while(<infile1>) { 
 			chomp;
			if($_=~/^>([^ ]+)/) { 
				$thiseq=$1; 
				if($thiseq) { print outfile1 "$thiseq\t$bin\n"; }
				}
			}
		close infile1;
		}
	close outfile1;
	}
chop $tables;
chop $methods;
print "done\n";


if($numbinmethods==1) {		#-- If there is just one result, simply copy the fasta files from it
	my $gmet=$methods;
	print "Only one binning result: Copying $gmet results and skipping DAS Tool\n";
	print outsyslog "Only one binning result: Copying $gmet results and skipping DAS Tool\n";
	my @binner=split(/\,/,$binners);
	foreach my $tbinner(@binner) { 
		my $bindir="$interdir/binners/$tbinner";
		my $command="cp $bindir/*fasta $binresultsdir";
		system $command;
		print outsyslog "$command\n";
		my $command="cp $bindir/*fa $binresultsdir";
		system $command;
		print outsyslog "$command\n";
		}
	}

else { 				#-- Otherwise, run DAS tool to combine results
	
	my $das_command="$dastool_soft -i $tables -l $methods -c $contigsfna --write_bins 1 --score_threshold $score_tres15 --search_engine diamond -t $numthreads -o $daspath/$project --db_directory $databasepath";
 
	print "Running DAS Tool (Sieber et al 2018, Nat Microbiol 3(7), 836-43) for $methods\n";
	print outsyslog "Running DAS Tool for $methods: $das_command\n";
	my $ecode = system $das_command;
	if($ecode!=0) { warn "Error running command:    $das_command"; }
	else {
		open(outmet,">>$methodsfile") || warn "Cannot open methods file $methodsfile for writing methods and references\n";
		print outmet "Combination of binning results was done using DAS Tool (Sieber et al 2018, Nat Microbiol 3(7), 836-43)\n";
		close outmet;
		}
	}

print "  Final binning results stored in $binresultsdir\n";	
system("mv $daspath/$project\_DASTool\_bins/* $binresultsdir");	
close outsyslog;
