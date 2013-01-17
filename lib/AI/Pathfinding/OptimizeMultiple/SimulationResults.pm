package AI::Pathfinding::OptimizeMultiple::SimulationResults;

use MooX qw/late/;

has status => (isa => 'Str', is => 'ro', required => 1,);
has total_iters => (isa => 'Int', is => 'ro', required => 1,);
has scan_runs => (isa => 'ArrayRef[AI::Pathfinding::OptimizeMultiple::ScanRun]', is => 'ro', required => 1,);

sub get_total_iters
{
    return shift->total_iters();
}

sub get_status
{
    return shift->status();
}

1;

__END__

=pod

=head1 NAME

AI::Pathfinding::OptimizeMultiple::SimulationResults

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

=head1 DESCRIPTION

A class for simulation results.

=head1 NAME

AI::Pathfinding::OptimizeMultiple::SimulationResults - the simulation results.

=head1 VERSION

version 0.0.1

=head1 SLOTS

=head2 $scan_run->status()

The status.

=head2 $scan_run->total_iters()

The total iterations count so far.

=head2 my $aref = $self->scan_runs()

An array reference of L<AI::Pathfinding::OptimizeMultiple::ScanRun> .

=head1 METHODS

=head2 $self->get_total_iters()

Returns the total iterations.

=head2 $self->get_status()

Returns the status.

=head1 VERSION

version 0.0.1

=head1 SEE ALSO

L<AI::Pathfinding::OptimizeMultiple> , L<AI::Pathfinding::OptimizeMultiple::ScanRun> .

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

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
