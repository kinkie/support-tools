#!/usr/bin/perl -w

# Finds some unwanted changes in patches. By Alex Rousskov.

use strict;
use warnings;

my $Verbose = 0;
if (@ARGV && $ARGV[0] eq '--verbose') {
	$Verbose = 1;
	shift @ARGV;
}

my $Fname = '?';
my $SawChange = 0;
my $SawDanger = undef();
my $SawLeadingSpace = 0;
my $SawLeadingTab = 0;
my $XxxCount = 0;
my @Oldies = ();
while (<>) {

	my $seeChange = /^[+-](?![+-])/ || /^[+-]$/;

	if ($SawDanger) {
		if ($seeChange) {
			$SawDanger = undef();
		} else {
			&redFlag('Empty line change', $Fname, $SawDanger->{lineno}, $SawDanger->{line});
			&redFlag('  ... followed by', $Fname, $., $_);
			$SawChange = 0;
			$SawDanger = undef();
			next;
		}
	}

	if (/^[+-]\s*$/ && !$SawChange) {
		$SawDanger = {
			line => $_,
			lineno => $.,
		};
	} else {
		$SawDanger = undef();
	}

	if ($seeChange) {
		$SawChange = 1;
	} else {
		$SawChange = 0;
		$SawDanger = undef();
	}

	chomp; # TODO: move up to make /^[+-]$/ work?

	if (my $seeAddition = /^[+](?![+-])/ || /^[+]$/) {
		&redFlag('Added trailing whitespace', $Fname, $., $_) if /\s$/;
		&redFlag('Expected leading spaces but found a tab', $Fname, $., $_) if /^[+]\s*\t/ && $SawLeadingSpace;
		&redFlag('Expected leading tabs but found a space', $Fname, $., $_) if /^[+]\t*\040/ && $SawLeadingTab;

		&checkRemovedOrChanged($_) || checkWhitespaceOnlyChange($_);

		++$XxxCount if /XXX/;
		&redFlag('FYI, an XXX', $Fname, $., $_) if $Verbose && /XXX/;
	}
	elsif (my $sawRemoval = /^[-](?![+-])/) {
		push @Oldies, {
				line => $_,
				lineno => $.,
				used => 0
		};
	}

	if (/^\Q+++\E\s/ || /^\Q---\E\s/) {
		$SawLeadingSpace = 0;
		$SawLeadingTab = 0;
		@Oldies = ();
		$Fname = $1 if /^\S+\s+(\S+)/;
	} 
	elsif (/^[^+]\040/) {
		$SawLeadingSpace = $.;
		$SawLeadingTab = 0;
	} 
	elsif (/^[^+]\t/) {
		$SawLeadingTab = $.;
		$SawLeadingSpace = 0;
	}

	#printf(STDERR "%d %d %s\n", $SawChange != 0, defined $SawDanger, $_);
}

printf(STDERR "New XXXs seen: %d\n", $XxxCount) if $XxxCount;

exit(0);

sub checkRemovedOrChanged {
	my ($newLine) = @_;

	my $newLineDigest = $newLine;
	$newLineDigest =~ s/==\s*(std::)?nullptr/.IsNuLl./g;
	$newLineDigest =~ s/!=\s*(std::)?nullptr/.IsNotNuLl./g;
	$newLineDigest =~ s/(std::)?nullptr/NULL/;
	return 0 if $newLineDigest eq $newLine;
	$newLineDigest =~ s/\s+//g; # whitespace change does not count
	$newLineDigest =~ s/^.//; # remove patch markup


	# the closes to $newLine match wins
	for (my $oldIdx = $#Oldies; $oldIdx >= 0; --$oldIdx) {
		my $old = $Oldies[$oldIdx];
		next if $old->{used};

		my $oldLineDigest = $old->{line};
		$oldLineDigest =~ s/\bHERE\b//g; # removed HERE
		$oldLineDigest =~ s/==\s*NULL/.IsNuLl./g;
		$oldLineDigest =~ s/!=\s*NULL/.IsNotNuLl./g;
		$oldLineDigest =~ s/\s+//g; # whitespace change does not count
		$oldLineDigest =~ s/^.//; # remove patch markup
		next unless $oldLineDigest eq $newLineDigest;

		&redFlag('Unnecessary code change of', $Fname, $old->{lineno}, $old->{line});
		&redFlag('                    ... to', $Fname, $., $newLine);
		$old->{used} = 1; # one violation per line
		return 1;
	}

	return 0;
}

sub checkWhitespaceOnlyChange {
	my ($newLine) = @_;

	my $newLineSuffix = $newLine;
	$newLineSuffix =~ s/^.(\s*)//; # remove patch markup and leading whitespace
	my $newLinePrefix = $1;
	return 0 unless $newLineSuffix =~ /\S/; # at least one non-space

	my $newLineDigest = $newLineSuffix;
	$newLineDigest =~ s/\s+//g; # remove whitespace

	# the closes to $newLine match wins
	for (my $oldIdx = $#Oldies; $oldIdx >= 0; --$oldIdx) {
		my $old = $Oldies[$oldIdx];
		next if $old->{used};

		my $oldLineSuffix = $old->{line};
		$oldLineSuffix =~ s/^.(\s*)//; # remove patch markup and leading whitespace
		my $oldLinePrefix = $1;
		next unless $oldLineSuffix =~ /\S/; # at least one non-space
		next if $oldLinePrefix ne $newLinePrefix; # prefix has changed
		next if $oldLineSuffix eq $newLineSuffix; # nothing has changed

		my $oldLineDigest = $oldLineSuffix;
		$oldLineDigest =~ s/\s+//g; # remove whitespace
		next unless $oldLineDigest eq $newLineDigest;

		&redFlag('Unnecessary whitespace change of', $Fname, $old->{lineno}, $old->{line});
		&redFlag('                          ... to', $Fname, $., $newLine);
		$old->{used} = 1; # one violation per line
		return 1;
	}

	return 0;
}

sub redFlag {
	my ($msg, $fname, $lineno, $line) = @_;
	chomp($line);
	printf(STDERR "%s:%d: %s: %s\n", $fname, $lineno, $msg, $line);
}
