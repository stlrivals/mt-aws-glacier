# mt-aws-glacier - Amazon Glacier sync client
# Copyright (C) 2012-2013  Victor Efimov
# http://mt-aws.com (also http://vs-dev.com) vs@vs-dev.com
# License: GPLv3
#
# This file is part of "mt-aws-glacier"
#
#    mt-aws-glacier is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    mt-aws-glacier is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

package TestUtils;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use strict;
use warnings;

use App::MtAws::ConfigDefinition;
use App::MtAws::ConfigEngine;
use Test::More;
use Test::Deep;
require Exporter;
use base qw/Exporter/;
use Carp;

our %disable_validations;
our @EXPORT = qw/fake_config config_create_and_parse disable_validations no_disable_validations warning_fatal
capture_stdout capture_stderr assert_raises_exception/;

sub warning_fatal
{
	$SIG{__WARN__} = sub {confess "Termination after a warning: $_[0]"};
}

sub fake_config(@)
{
	my ($cb, %data) = (pop @_, @_);
	no warnings 'redefine';
	local *App::MtAws::ConfigEngine::read_config = sub { %data ? { %data } : { (key=>'mykey', secret => 'mysecret', region => 'myregion') } };
	disable_validations($cb);
}

sub no_disable_validations
{
	local %disable_validations = ();
	shift->();
}

sub disable_validations
{
	my ($cb, @data) = (pop @_, @_);
	local %disable_validations = @data ?
	( 
		'override_validations' => {
			map { $_ => undef } @data
		},
	) :
	( 
		'override_validations' => {
			journal => undef,
			secret  => undef,
			key => undef,
			dir => undef,
		},
	);
	$cb->();
}

sub config_create_and_parse(@)
{
#	use Data::Dumper;
#	die Dumper {%disable_validations};
	my $c = App::MtAws::ConfigDefinition::get_config(%disable_validations);
	my $res = $c->parse_options(@_);
	$res->{_config} = $c;
	wantarray ? ($res->{error_texts}, $res->{warning_texts}, $res->{command}, $res->{options}) : $res;
}

sub capture_stdout($&)
{
	local(*STDOUT);
	open STDOUT, '>', \$_[0] or die "Can't open STDOUT: $!";
	$_[1]->();
}

sub capture_stderr($&)
{
	local(*STDERR);
	open STDERR, '>', \$_[0] or die "Can't open STDERR: $!";
	$_[1]->();
}

# TODO: call only as assert_raises_exception sub {}, $e - don't omit sub! 
sub assert_raises_exception(&@)
{
	my ($cb, $exception) = @_;
	ok !defined eval { $cb->(); 1 };
	my $err = $@;
	cmp_deeply $err, superhashof($exception);
	return ;
}

1;
