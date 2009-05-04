package Log::Deep;

# Created on: 2008-10-19 04:44:02
# Create by:  ivan
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp qw/longmess/;
use List::MoreUtils qw/any/;
use Readonly;
use Data::Dump::Streamer;
use POSIX qw/strftime/;
use English qw/ -no_match_vars /;
use base qw/Exporter/;

our $VERSION     = version->new('0.0.1');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;

Readonly my @LOG_LEVELS => qw/note message debug warning error fatal/;

sub new {
	my $class  = shift;
	my %param  = @_;
	my $self   = {};

	bless $self, $class;

	$self->{dump} = Data::Dump::Streamer->new()->Indent(0);

	# set up log levels
	if (!$param{-level}) {
		$self->level(qw/warning error fatal/);
	}
	else {
		$self->level(ref $param{-level} ? @{$param{-level}} : $param{-level});
	}

	# set up the log file parameters
	$self->{file}     = $param{-file};
	$self->{log_dir}  = $param{-log_dir};
	$self->{log_name} = $param{-name};
	$self->{date_fmt} = $param{-date_fmt};
	$self->{style}    = $param{-style} || 'none';

	# set up the maximum random session id
	$self->{rand_max} = $param{-rand_max} || 10_000;

	# check if we are starting a session or not
	if ($param{-nosession}) {
		$self->{session} = $param{-session_id};
	}
	else {
		$self->session($param{-session_id});
	}

	return $self;
}

sub note {
	my ($self, @params) = @_;

	return if !$self->level(-log => 'note');

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'note';

	return $self->record(@params);
}

sub message {
	my ($self, @params) = @_;

	return if !$self->level(-log => 'message');

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'message';

	return $self->record(@params);
}

sub debug {
	my ($self, @params) = @_;

	return if !$self->level(-log => 'debug');

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'debug';

	return $self->record(@params);
}

sub warning {
	my ($self, @params) = @_;

	return if !$self->level(-log => 'warning');

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'warning';

	return $self->record(@params);
}

sub error {
	my ($self, @params) = @_;

	return if !$self->level(-log => 'error');

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'error';

	return $self->record(@params);
}

sub fatal {
	my ($self, @params) = @_;

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'fatal';

	return $self->record(@params);
}

sub security {
	my ($self, @params) = @_;

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'security';

	return $self->record(@params);
}

sub record {
	my ($self, $param, @message) = @_;
	my $dump = $self->{dump};

	# check that a session has been created
	$self->session($param->{-session_id}) if !$self->{session_id};

	my $level  = $param->{-level} || '(none)';
	delete $param->{-level};

	# set up
	$param->{-stack} = longmess;
	$param->{-stack} =~ s/^\s+[^\n]*Log::Deep::[^\n]*\n//gxms;

	my @log = (
		strftime('%Y-%m-%d %H:%M:%S', localtime),
		$self->{session_id},
		$level,
		(join ' ', @message),
		$dump->Data($param)->Out(),
	);

	# make each part safe for outputting to one line
	for my $col (@log) {
		chomp $col;
		# quote all back slashes
		$col =~ s{\\}{\\\\}g;
		# quote all new lines
		$col =~ s/\n/\\n/g;
	}

	my $log = $self->log_handle();
	print {$log} join ',', @log;
	print {$log} "\n";

	$self->{log_session_count}++;

	return ;
}

sub log_handle {
	my $self = shift;

	if ( !$self->{handle} ) {
		$self->{log_dir}  ||= '/tmp';
		$self->{log_name} ||= (split m{/}, $0)[-1] || 'deep';
		$self->{date_fmt} ||= '%Y-%m-%d';
		$self->{log_date}   = strftime $self->{date_fmt}, localtime;

		my $file = $self->{file} || "$self->{log_dir}/$self->{log_name}_$self->{log_date}.log";

		open my $fh, '>>', $file or die "Could not open log file $file: $!\n";
		$self->{handle} = $fh;
	}

	return $self->{handle};
}

sub session {
	my ($self, $session_id) = @_;

	return if defined $self->{log_session_count} && $self->{log_session_count} == 0;

	# use the supplied session id or create a new session id
	$self->{session_id} = $session_id || int rand $self->{rand_max};

	$self->record({-env => \%ENV}, '"START"');

	$self->{log_session_count} = 0;

	return;
}

sub level {
	my ($self, @level) = @_;

	$self->{level} ||= { map { $_ => 0 } @LOG_LEVELS };

	# if not called with any parameters return the level hash
	return $self->{level} if !@level;

	# return log state if asked about that state
	return $self->{level}{$level[1]}     if $level[0] eq '-log';

	# Set a log state if requested
	return $self->{level}{$level[1]} = 1 if $level[0] eq '-set';

	# if there is only one parameter that is a single digit set the all levels of that digit and higher
	if (@level == 1 && $level[0] =~ /^\d$/) {
		return $self->{level} = { map {$_ => 1} @LOG_LEVELS[$level[0] .. @LOG_LEVELS-1] };
	}

	# if the is one parameter and it is a string turn on that level and highter
	if ( @level == 1 && any { $_ eq $level[0] } @LOG_LEVELS ) {

		# flag that we have found the starting level
		my $found = 0;

		for my $log_level (@LOG_LEVELS) {

			# skip this level if it is not the starting level of higher
			next if $log_level ne $level[0] && !$found;

			# flag that we have the start level
			$found = 1;

			# mark the current level active
			$self->{level}{$log_level} = 1;
		}

		return $self->{level};
	}

	# set all levels passed in as active levels.
	for my $level (@level) {
		$self->{level}{$level} = 1;
	}

	return $self->{level};
}

1;

__END__

=head1 NAME

Log::Deep - Deep Logging of information about a script state

=head1 VERSION

This documentation refers to Log::Deep version 0.1.


=head1 SYNOPSIS

   use Log::Deep;

   # create or append a log file with the current users name in the current
   # directory (if possible) else in the tmp directory. The session id will be
   # randomly generated.
   my $log = Log::Deep->new();

   $log->debug({-data => $object}, 'Message text');

=head1 DESCRIPTION

C<Log::Deep> creates a object for detailed logging of the state of the running
script.

=head2 Plugins

One of the aims of C<Log::Deep> is to be able to record deeper information
about the state of a running script. For example a CGI script (using CGI.pm)
has a CGI query object which stores its parameters and cookies, using the
CGI plugin this extra information is logged in the data section of the log
file.

Some plugins add data only when the a logging session starts, others will
add data every time a log message is written.

=head2 The Log File

C<Log::Deep> log file format looks something like

 iso-timestamp;session id;level;message;caller;data

All values are url encoded so that one log line will always represent one log
message, the line should be reasonably human readable except for the data
section which is a dump of all the deep details logged. A script C<deeper> is
provided with C<Log::Deeper> that allows for easier reading/searching of
C<Log::Deep> log files.

=head1 SUBROUTINES/METHODS

=head3 C<new ( %args )>

Arg: B<-level> - array ref | string - If an array ref turns on all levels
specified, if a string turns on that level and higher

Arg: B<-file> - string - The name of the log file to write to

Arg: B<-log_dir> - string - The name of the directory that the log file is
written to.

Arg: B<-name> - string - The name of the file in -log_dir

Arg: B<-date_fmt> - string - The date format to use for appending to log
file -names

Arg: B<-style> -  -

Arg: B<-rand_max> -  -

Arg: B<-session_id> - string - A specific session id to use.

Return: Log::Deep - A new Log::Deep object

Description: This creates a new log object.

=head3 C<note ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<message ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<debug ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<warning ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<error ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<fatal ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<security ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<record ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<log_handle ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<session ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<level ( $var )>

Param: C<$> - type -

Return:  -

Description:


=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
