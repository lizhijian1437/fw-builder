#!/usr/bin/perl

#@brief 将输入文件写到输出文件的某个地址上，空段默认填充0
#@param -i 输入文件
#@param -o 输出文件
#@param -a 地址(十进制)
use Getopt::Std;
use vars qw($opt_i $opt_o $opt_a);
getopts('i:o:a:');

open(INPUT, "<$opt_i") or die "input $opt_i file can't open";
open(OUTPUT, "+<$opt_o") or die "output $opt_o file can't open";

seek OUTPUT, $opt_a, 0;

$buffer = "";

while (read(INPUT, $buffer, 1073741824)) {
	print OUTPUT "$buffer";
}

close(INPUT);
close(OUTPUT);
