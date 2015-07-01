#!/usr/bin/perl

use strict;
use warnings;

use File::Find ();
use File::Basename;
use Cwd;

# Set the variable $File::Find::dont_use_nlink if you're using AFS,
# since AFS cheats.

# for the convenience of &wanted calls, including -eval statements:
use vars qw/*name *dir *prune/;
*name   = *File::Find::name;
*dir    = *File::Find::dir;
*prune  = *File::Find::prune;

sub wanted;


print <<'EOF';
CREATE TABLE global_symbols   (	symbol TEXT,
dir TEXT,
file TEXT,
line INTEGER);
EOF

# Traverse desired filesystems
File::Find::find({wanted => \&wanted}, '.');

sub wanted {
    my ($dev,$ino,$mode,$nlink,$uid,$gid);

    (
	(($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) &&
	$File::Find::name =~ /^\.\/lib\z/s
	||
	$File::Find::name =~ /^\.\/arch\/x86\/lib\z/s
	||
	$File::Find::name =~ /^\.\/drivers\z/s
    ) &&
    ($File::Find::prune = 1)
    ||
    (
	/^.*\.dwo\z/s &&
	($nlink || (($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_))) &&
	! /^.*built-in.*\z/s
    ) &&
    look_for_symbols_in_file($name);
}


sub look_for_symbols_in_file
{
	my $file = shift;
	my ($base,$path,$suffix) = fileparse($file,('.dwo'));
	if (! -e "$base.mod.c" && -e "$base.o")
	{
		#print STDERR "$base\n";
		my $nm_output;
		open ($nm_output, "-|", "nm -l -g --defined-only --no-sort $base.o");
		while (<$nm_output>)
		{
			if (/.*\s+T\s+(\w+).*:(\d+)/)
			{
				# print STDERR $_;
				my ($symbol,$line) = ($1,$2);
				# Special case for system calls
				next if $symbol =~ /^SyS_/;
				$symbol =~ s/^sys_/SYSC_/;

				print "INSERT INTO global_symbols (symbol,dir,file,line) VALUES ('$symbol', '$path', '$base.c', '$line');\n"
			}
		}
	}
}

1;

__END__
