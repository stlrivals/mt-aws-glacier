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

package App::MtAws::SingleDownloadJob;

use strict;
use warnings;
use utf8;
use base qw/App::MtAws::Job/;
use App::MtAws::Utils;
use File::stat;
use Carp;


sub new
{
    my ($class, %args) = @_;
    my $self = \%args;
    bless $self, $class;
    $self->{archive}||confess;
    $self->{raised} = 0;
    return $self;
}

# returns "ok" "wait" "ok subtask"
sub get_task
{
	my ($self) = @_;
	if ($self->{raised}) {
		return ("wait");
	} else {
		$self->{raised} = 1;
		my $archive = $self->{archive};
		return ("ok",  App::MtAws::Task->new(id => $archive->{jobid}, action=>"retrieval_download_job", data => {
			archive_id => $archive->{archive_id}, relfilename => $archive->{relfilename}, filename => $archive->{filename},
			mtime => $archive->{mtime}, jobid => $archive->{jobid}, size => $archive->{size}, treehash => $archive->{treehash}
		}));
	}
}

# returns "ok" "ok replace" "done"
sub finish_task
{
	my ($self, $task) = @_;
	if ($self->{raised}) {
		my $mtime = $task->{data}{mtime};
		utime $mtime, $mtime, binaryfilename($task->{data}{filename}) or confess if defined $mtime;
		return ("done");
	} else {
		confess;
	}
}
	
1;
