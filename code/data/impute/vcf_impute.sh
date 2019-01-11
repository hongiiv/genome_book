#!/bin/bash
#   vcf_impute.sh - imputes selected SNPs from KGP data
#   Copyright (C) 2013 Giulio Genovese
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#   Written by Giulio Genovese <giulio.genovese@gmail.com>

jar="$1"
bed="$2"
vcf="$3"

prefix=${vcf%.vcf.gz}
name=${prefix%_Full_*}; name=${name#genome_}
date=${prefix#genome_*_Full_};

chr=$(head -n1 $bed | cut -f1)
from=$(($(head -n1 $bed | cut -f2)-1000000))
to=$(($(tail -n1 $bed | cut -f2)+1000000))
reg="$chr:${from}-$to"

# pfx="ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase1/analysis_results/integrated_call_sets/ALL.chr"
# sfx=".integrated_phase1_v3.20101123.snps_indels_svs.genotypes.vcf.gz"

pfx="http://bochet.gcc.biostat.washington.edu/beagle/1000_Genomes_phase1_vcf/chr"
sfx=".1kg.ref.phase1_release_v3.20101123.vcf.gz"

(cat $bed; tabix -h $vcf $reg | bedtools merge) | bedtools sort | bedtools merge > regs.bed

(tabix -H $pfx$chr$sfx;
  tabix -h $pfx$chr$sfx $reg |
    bedtools intersect -a - -b regs.bed |
    uniq | grep -v esv[0-9]) |
  bgzip > ref.vcf.gz

tabix -h $vcf $reg | java -jar $jar ref=ref.vcf.gz gt=/dev/stdin out=regs_${name}_Full_$date
tabix -f regs_${name}_Full_$date.vcf.gz
tabix -hT $bed regs_${name}_Full_$date.vcf.gz
