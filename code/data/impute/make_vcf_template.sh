#!/bin/bash
#   make_vcf_template.sh - make a VCF template for 23andMe genotype data
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

for zipfile in ${@:2}; do
  prefix=${zipfile%.zip}
  unzip -p $zipfile $prefix.txt | grep -v ^# | dos2unix
done | awk '($1 in pos) && (type[$1]!="UNK") {next}
  $4~"[ACGT]" {pos[$1]=$2"\t"$3; type[$1]="SNP"}
  $4~"[DI]" {pos[$1]=$2"\t"$3; type[$1]="DIV"}
  $4~"-" {pos[$1]=$2"\t"$3; type[$1]="UNK"}
  END {for (id in pos) print pos[id]"\t"id"\t"type[id]}' |
  sed -e 's/^X/23/g' -e 's/^Y/24/g' -e 's/^MT/26/g' | sort -k1,1n -k2,2n |
  sed -e 's/^23/X/g' -e 's/^24/Y/g' -e 's/^26/MT/g' | uniq > 23andme.tsv

zcat $1 | awk 'NR==FNR && $4=="DIV" {div[$3]++} NR==FNR && $4=="SNP" {snp[$1"_"$2]++}
  NR>FNR && ($0~"^#" || ($3 in div) || ($1"_"$2 in snp) && $4~"^[ACGT]$" && ($5~"^[ACGT]$" || $5~"^[ACGT],"))' \
  23andme.tsv - | bgzip > 23andme.vcf.gz

tabix -f 23andme.vcf.gz
