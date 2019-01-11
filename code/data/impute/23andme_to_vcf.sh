#!/bin/bash
#   23andme_to_vcf.sh - convert 23andMe genotype data to VCF format
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

prefix=${2%.zip}
name=${prefix%_Full_*}; name=${name#genome_}
date=${prefix#genome_*_Full_};

(echo "##fileformat=VCFv4.1";
 echo "##fileDate=$date";
 echo "##FORMAT=<ID=GT,Number=1,Type=Integer,Description=\"Genotype\">";
 echo -e "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t$name";
unzip -p $2 $prefix.txt | dos2unix | grep -v ^# |
  awk 'NR==FNR {
    if (length($4)==1) $4=$4$4;
    if ($4~"[ACGT]") snp[$2"_"$3]=$4;
    else if ($4~"[ID]") div[$1]=$4}
  NR>FNR && $0!~"^#" {
  if ($1"_"$2 in snp) {
    split($5,alt,",");
    len=length(alt);
    a1=substr(snp[$1"_"$2],1,1);
    if (a1==$4) gt="0";
    else if (a1==alt[1]) gt="1";
    else if (a1==alt[2]) gt="2";
    else if (a1==alt[3]) gt="3";
    else {$5=$5","a1; len=len+1; alt[len]=a1; gt=len}
    a2=substr(snp[$1"_"$2],2,1);
    if (a2==$4) gt=gt"/0";
    else if (a2==alt[1]) gt=gt"/1";
    else if (a2==alt[2]) gt=gt"/2";
    else if (a2==alt[3]) gt=gt"/3";
    else {$5=$5","a2; len=len+1; alt[len]=a2; gt=gt"/"len}}
  if ($3 in div) {
    if ($4=="DI") gt="0/1";
    else if (length($4)<length($5) && $4=="DD" || length($4)>length($5) && $4=="II") gt="0/0";
    else if (length($4)<length($5) && $4=="II" || length($4)>length($5) && $4=="DD") gt="1/1"}
  if (($1"_"$2 in snp) || ($3 in div))
    print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t.\t.\t.\tGT\t"gt}' \
  - <(zcat $1)) | bgzip > $prefix.vcf.gz

tabix -f $prefix.vcf.gz
