package AI::Pathfinding::OptimizeMultiple::IterState;

use strict;
use warnings;

use MooX qw/late/;

use PDL ();

our $VERSION = '0.0.6';

use vars (qw(@fields));

has _main => (is => 'rw');
has _num_solved => (isa => 'Int', is => 'ro', init_arg => 'num_solved', required => 1);
has _quota => (isa => 'Int', is => 'ro', init_arg => 'quota', required => 1);
has _scan_idx => (isa => 'Int', is => 'ro', init_arg => 'scan_idx', required => 1);

use Exception::Class
(
    'AI::Pathfinding::OptimizeMultiple::Error::OutOfQuotas'
);

sub attach_to
{
    my $self = shift;
    my $main_obj = shift;

    $self->_main($main_obj);

    return;
}


sub get_chosen_struct
{
    my $self = shift;
    return
        AI::Pathfinding::OptimizeMultiple::ScanRun->new(
            {
                iters => $self->_quota(),
                scan_idx => $self->_scan_idx()
            }
        );
}


sub detach
{
    my $self = shift;
    $self->_main(undef);
}


sub idx_slice
{
    my $self = shift;

    my $scans_data = $self->_main()->_scans_data();

    my @dims = $scans_data->dims();

    return $scans_data->slice(
        join(",",
            ":", $self->_scan_idx(), (("(0)") x (@dims-2))
        )
    );
}


sub update_total_iters
{
    my $state = shift;

    # $r is the result of this scan.
    my $r = $state->idx_slice();

    # Add the total iterations for all the states that were solved by
    # this scan.
    $state->_main()->_add_to_total_iters(
        PDL::sum((($r <= $state->_quota()) & ($r > 0)) * $r)
    );

    # Find all the states that weren't solved.
    my $indexes = PDL::which(($r > $state->_quota()) | ($r < 0));

    # Add the iterations for all the states that have not been solved
    # yet.
    $state->_main()->_add_to_total_iters($indexes->nelem() * $state->_quota());

    # Keep only the states that have not been solved yet.
    $state->_main()->_scans_data(
        $state->_main()->_scans_data()->dice($indexes, "X")->copy()
    );
}



sub update_idx_slice
{
    my $state = shift;
    my $r = $state->idx_slice()->copy();
    # $r cannot be 0, because the ones that were 0, were already solved
    # in $state->update_total_iters().
    my $idx_slice = $state->idx_slice();
    $idx_slice .=
        (($r > 0) * ($r - $state->_quota())) +
        (($r < 0) * ($r                  ));
}

sub _mark_as_used
{
    my $state = shift;

    $state->_main()->_selected_scans()->[$state->_scan_idx()]->mark_as_used();

    return;
}

sub _add_chosen
{
    my $state = shift;

    push @{$state->_main()->chosen_scans()}, $state->get_chosen_struct();

    return;
}

sub _update_total_boards_solved
{
    my $state = shift;

    $state->_main()->_add_to_total_boards_solved($state->_num_solved());

    return;
}

sub _trace_wrapper
{
    my $state = shift;

    $state->_main()->_trace(
        {
            'iters_quota' => $state->_quota(),
            'selected_scan_idx' => $state->_scan_idx(),
            'total_boards_solved' => $state->_main()->_total_boards_solved(),
        }
    );

    return;
}


sub register_params
{
    my $state = shift;

    $state->_add_chosen();
    $state->_mark_as_used();
    $state->_update_total_boards_solved();
    $state->_trace_wrapper();

    return;
}


1;

__END__

=pod

=head1 NAME

AI::Pathfinding::OptimizeMultiple::IterState - iteration state object.

=head1 VERSION

version 0.0.6

=head1 SUBROUTINES/METHODS

=head2 $self->attach_to()

Internal use.

=head2 $self->get_chosen_struct()

Internal use.

=head2 $self->detach()

Internal use.

=head2 $self->idx_slice()

Internal use.

=head2 $self->update_total_iters()

Internal use.

=head2 $self->update_idx_slice()

Internal use.

=head2 $self->register_params()

Internal use.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 Shlomi Fish

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=AI-Pathfinding-OptimizeMultiple or
by email to bug-ai-pathfinding-optimizemultiple@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc AI::Pathfinding::OptimizeMultiple

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/AI-Pathfinding-OptimizeMultiple>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/AI-Pathfinding-OptimizeMultiple>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AI-Pathfinding-OptimizeMultiple>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/AI-Pathfinding-OptimizeMultiple>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/AI-Pathfinding-OptimizeMultiple>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/AI-Pathfinding-OptimizeMultiple>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/AI-Pathfinding-OptimizeMultiple>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/AI-Pathfinding-OptimizeMultiple>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=AI-Pathfinding-OptimizeMultiple>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=AI::Pathfinding::OptimizeMultiple>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-ai-pathfinding-optimizemultiple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AI-Pathfinding-OptimizeMultiple>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://bitbucket.org/shlomif/fc-solve>

  hg clone ssh://hg@bitbucket.org/shlomif/fc-solve

=cut
