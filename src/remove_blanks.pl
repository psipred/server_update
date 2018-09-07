#!/usr/bin/perl -w

use FileHandle;

my $file = $ARGV[0];

my $fhInput = new FileHandle($file, "r");

my $title = '';
while(my $line = $fhInput->getline)
{
	if($line =~ /^>/)
	{
		$title = $line;
		next;
	}
	if($line =~ /^.+/)
	{
		print $title;
		print $line;
	}
}
