#!/usr/bin/env perl

#-- Part of SqueezeMeta distribution. 01/05/2018 Original version, (c) Javier Tamames, CNB-CSIC
#-- Runs checkM for evaluating bins
#

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

our($installpath,$datapath,$taxlist,$binresultsdir,$checkm_soft,$alllog,$resultpath,$tempdir,$minsize17,$numthreads,$interdir,$methodsfile,$syslogfile,$checkmfile);

open(outsyslog,">>$syslogfile") || warn "Cannot open syslog file $syslogfile for writing the program log\n";

print "  Evaluating bins with CheckM (Parks et al 2015, Genome Res 25, 1043-55)\n\n";

my $markerdir="$datapath/checkm_markers";
my $checktemp="$tempdir/checkm_batch";
my $tempc="$tempdir/checkm_prov.txt";
my %branks=('k','domain','p','phylum','c','class','o','order','f','family','g','genus','s','species');

if(-d $markerdir) {} else { system "mkdir $markerdir"; }
if(-d $checktemp) {} else { system "mkdir $checktemp"; print "  Creating $checktemp\n";  }

my(%tax,%bins,%consensus,%alltaxa);

#-- Read NCBI's taxonomy 

open(infile1,$taxlist) || die "Can't find taxonomy list $taxlist\n";
print "  Reading $taxlist\n";
while(<infile1>) {
	chomp;
	next if !$_;
	my @t=split(/\t/,$_);
	my $nctax=$t[1];
	$nctax=~s/ \<.*//;
	$tax{$nctax}=$t[2];
	}
close infile1;

	#-- Read bin directories

	my $binmethod="DAS";
	my $bindir=$binresultsdir;
	print "  Looking for $binmethod bins in $bindir\n";
	
	#-- Read contigs in bins
	
	open(infile2,$alllog) || die "Can't open $alllog\n";
	while(<infile2>) {
		chomp;
		next if !$_;
		my @t=split(/\t/,$_);
		$tax{$t[0]}=$t[1];
		}
	close infile2;

	#-- Read all bins

opendir(indir,$bindir) || die "Can't open $bindir directory\n";
my @files=grep(/tax$/,readdir indir);
my $numbins=$#files+1;
print "  $numbins bins found\n\n";
closedir indir;


my $currentbin;
if(-e $checkmfile) { system("rm $checkmfile"); }

	#-- Working for each bin

foreach my $m(@files) { 
	$currentbin++;
	#if($exclude{$m}) { print "**Excluding $m\n"; next; }
	my $binname=$m;
	my $binname=~s/\.tax//g;
	my $thisfile="$bindir/$m";
	$bins{$thisfile}=$binname;
	print "  Bin $currentbin/$numbins: $m\n";
 
	#-- Reading the consensus taxa for the bin
 
	open(infile3,$thisfile) || die "Can't open $thisfile\n";
	while(<infile3>) { 
		chomp;
		if($_=~/Consensus/) {
			my($cons,$size,$chim,$chimlev)=split(/\t/,$_);
			$cons=~s/Consensus\: //;
			$size=~s/Total size\: //g;
			if($size<$minsize17) { print "  Skipping bin because of low size ($size<$minsize17)\n"; next; }
			$consensus{$thisfile}=$cons;
			my @k=split(/\;/,$cons);
		
			#-- We store the full taxonomy for the bin because not all taxa have checkm markers
		
			foreach my $ftax(reverse @k) { 
				my($ntax,$rank);
				if($ftax!~/\_/) { $ntax=$ftax; } else { ($rank,$ntax)=split(/\_/,$ftax); }
				$ntax=~s/unclassified //gi;
				$ntax=~s/ \<.*\>//gi; 
				if(($tax{$ntax}) && ($rank ne "n") && ($rank ne "s") && ($branks{$rank})) { 
				push( @{ $alltaxa{$thisfile} },"$branks{$rank}\_$ntax");
				#   print "$m\t$ntax\t$tax{$ntax}\n";
				}
			}
		}
	}
	close infile3;

	my $inloop=1;

	#-- We will find the deepest taxa with checkm markers
	while($inloop) {  
		my $taxf=shift(@{ $alltaxa{$thisfile}  }); 
		if(!$taxf) { last; $inloop=0; }
		my($rank,$tax)=split(/\_/,$taxf);
		$tax=~s/ \<.*//g;
                $tax=~s/\s+/\_/g;
		# my $rank=$equival{$grank};
		if($rank eq "superkingdom") { $rank="domain"; }
		print "  Using profile for $rank rank : $tax\n";   
		my $marker="$markerdir/$tax.ms"; 
	
		#-- Use already existing tax profile or create it
	
		if(-e $marker) {} else { 
			my $command="$checkm_soft taxon_set $rank $tax $marker >> $syslogfile 2>&1";
			print outsyslog "$command\n";
                        my $ecode = system $command;
			if($ecode!=0) { die "Error running command:    $command"; }
			}
	
		#-- If it was not possible to create the profile, go for the upper rank
		
		if(-e $marker) {} else { next; }
	
		my $fastafile=$thisfile;
		$fastafile=~s/\.tax//;
		$fastafile=~s/.*\///;
		# print ">>> $checkm_soft analyze -t $numthreads -x $fastafile $marker $bindir $checktemp > /dev/null\n";
		# system("$checkm_soft analyze -t $numthreads -x $bins{$thisfile} $marker $bindir $checktemp > /dev/null");
		my $command = "$checkm_soft analyze -t $numthreads -x $fastafile $marker $bindir $checktemp >> $syslogfile 2>&1";
		print outsyslog "$command\n";
		my $ecode = system $command;
		if($ecode!=0) { die "Error running command:    $command"; }

		my $command = "$checkm_soft qa -t $numthreads $marker $checktemp -f $tempc >> $syslogfile 2>&1";
		print outsyslog "$command\n";
		my $ecode = system $command;
		if($ecode!=0) { die "Error running command:    $command"; }
	#	system("rm -r $checktemp");
		$inloop=0;
		if(-e $checkmfile) { system("cat $checkmfile $tempc > $checkmfile.prov; mv $checkmfile.prov $checkmfile"); }
		else { system("mv $tempc $checkmfile"); }
		}
 	} 
print "\n  Storing results for $binmethod in $checkmfile\n";


open(outmet,">>$methodsfile") || warn "Cannot open methods file $methodsfile for writing methods and references\n";
print outmet "Bin statistics were computed using CheckM (Parks et al 2015, Genome Res 25, 1043-55)\n";
close outmet;
close outsyslog;
