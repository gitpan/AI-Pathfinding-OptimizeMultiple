package AI::Pathfinding::OptimizeMultiple::DataInputObj;

use strict;
use warnings;

use MooX qw/late/;

use File::Path qw(mkpath);

use AI::Pathfinding::OptimizeMultiple::Scan;

use PDL;
use PDL::IO::FastRaw;

our $VERSION = '0.0.2';

has start_board => (isa => 'Int', is => 'ro', required => 1);
has num_boards => (isa => 'Int', is => 'ro', required => 1);
has selected_scans => (isa => 'ArrayRef', is => 'ro', required => 1,
    default => sub {
        my ($self) = @_;

        return $self->_calc_selected_scan_list();
    },
    lazy => 1,
);

sub _slurp
{
    my $filename = shift;

    open my $in, "<", $filename
        or die "Could not open $filename";

    binmode $in;
    local $/;
    my $content = <$in>;
    close($in);
    return $content;
}

sub _read_text_ints_file
{
    my $self = shift;

    my $filename = shift;

    my $text = _slurp($filename);

    return [split(/[\n\r]+/, $text)];
}

# Number of selected scans.
sub _num_sel_scans
{
    my $self = shift;

    return scalar(@{$self->selected_scans()});
}

sub _gen_initial_scans_tensor
{
    my $self = shift;
    my $extra_dims = shift || [];

    return zeroes($self->num_boards(), $self->_num_sel_scans, @$extra_dims);
}

sub _should_update
{
    my ($self, $src_path, $dest_path) = @_;

    my @orig_stat = stat($src_path);
    my @proc_stat = stat($dest_path);

    return ((! @proc_stat) || ($orig_stat[9] > $proc_stat[9]));
}

# Number of numbers in the header of the solutions' iteration counts
my $NUM_NUMBERS_IN_HEADER = 3;

my $HEADER_START_BOARD_IDX = 0;
my $HEADER_NUM_BOARDS = 1;
my $HEADER_ITERATIONS_LIMIT = 2;

sub _get_scans_data_helper
{
    my $self = shift;

    my $selected_scans = $self->selected_scans();

    my $start_board = $self->start_board();

    my $scans_data = {};
    my $scans_lens_data = {};

    my $scan_idx = 0;

    my $data_dir = ".data-proc";
    my $lens_dir = ".data-len-proc";

    mkpath([$data_dir, $lens_dir]);

    foreach my $scan (@$selected_scans)
    {
        {
            my $dest_path = $data_dir . "/" . $scan->id();
            {
                if ($self->_should_update($scan->data_file_path(), $dest_path))
                {
                    my $data_s = _slurp($scan->data_file_path());
                    my @array = unpack("l*", $data_s);
                    if (($array[$HEADER_START_BOARD_IDX] != 1) ||
                        ($array[$HEADER_NUM_BOARDS] < $self->num_boards) ||
                        ($array[$HEADER_ITERATIONS_LIMIT] != 100000)
                    )
                    {
                        die "Incorrect file format in scan " . $scan->{'id'} . "!\n";
                    }

                    my $c = pdl(\@array);

                    writefraw($c, $dest_path);
                }
            }
            {
                my $start_idx = $NUM_NUMBERS_IN_HEADER + ($start_board - 1);
                my $scan_vec = readfraw($dest_path);
                $scans_data->{$scan->id()} = $scan_vec->slice(
                    $start_idx.":".($start_idx + $self->num_boards()-1)
                );
            }
        }
        {
            my $src = $scan->data_file_path();
            my $dest = "$lens_dir/" . $scan->id();

            if ($self->_should_update($src, $dest))
            {
                my $data_s = _slurp($src);

                my @iters = unpack("l*", $data_s);
                if (($iters[0] != 1) || ($iters[1] < $self->num_boards())
                    || ($iters[2] != 100000)
                )
                {
                    die "Incorrect file format in scan " . $scan->id() . "!\n";
                }

                # Remove the header
                splice @iters, 0, $NUM_NUMBERS_IN_HEADER;

                my $c = pdl(
                    [\@iters,
                    $self->_read_text_ints_file(
                        "data/" . $scan->id() . ".fcs.moves.txt"
                    ),
                    $self->_read_text_ints_file(
                        "data/" . $scan->id() . ".fcpro.moves.txt"
                    ),
                    ]
                );

                writefraw($c, $dest);
            }
            {
                my $scan_vec = readfraw($dest);
                $scans_lens_data->{$scan->id()} = $scan_vec->slice(
                    sprintf(
                        "%d:%d,:,*",
                        ($start_board-1),
                        (($self->num_boards()-1)+($start_board-1))
                    )
                )->xchg(1,2);
            }
        }
    }
    continue
    {
        $scan_idx++;
    }

    return { 'scans' => $scans_data, 'with_lens' => $scans_lens_data };
}

sub _get_scans_data_generic
{
    my ($self, $id) = @_;

    return $self->_get_scans_data_helper()->{$id};
}

sub get_scans_iters_pdls
{
    my $self = shift;

    return $self->_get_scans_data_generic('scans');
}

sub get_scans_lens_iters_pdls
{
    my $self = shift;

    return $self->_get_scans_data_generic('with_lens');
}

sub _filter_scans_based_on_black_list_ids
{
    my ($scans, $black_list_ids) = @_;

    my %black_list = (map { /(\d+)/?($1 => 1) : () } @$black_list_ids);

    return
        [grep
            {
                !exists($black_list{$_->id()})
            }
            @$scans
        ];
}

sub _is_scan_suitable
{
    my ($self, $scan) = @_;

    my @stat = stat($scan->data_file_path());
    return
    (
        scalar(@stat)
            &&
        ($stat[7] >= 12 + ($self->num_boards() + $self->start_board() -1) * 4)
    );
}

sub _get_all_scans_list_from_file
{
    my $self = shift;

    my @scans;

    open my $scans_fh, "<", "scans.txt"
        or die "Could not open 'scans.txt' - $!.";
    while (my $line = <$scans_fh>)
    {
        chomp($line);
        my ($id, $cmd_line) = split(/\t/, $line);
        push @scans,
            AI::Pathfinding::OptimizeMultiple::Scan->new(
                id => $id,
                cmd_line => $cmd_line
            );
    }
    close($scans_fh);

    return \@scans;
}

sub _black_list_ids_list
{
    my $self = shift;

    open my $black_list_fh, "<", "scans-black-list.txt"
        or die "Could not open 'scans-black-list.txt'! $!.";
    my @black_list_ids = <$black_list_fh>;
    chomp(@black_list_ids);
    close($black_list_fh);

    return \@black_list_ids;
}

sub _suitable_scans_list
{
    my $self = shift;

    return
    [
        grep
        {
            $self->_is_scan_suitable($_)
        }
        @{$self->_get_all_scans_list_from_file()}
    ];
}

sub _calc_selected_scan_list
{
    my $self = shift;

    return
        _filter_scans_based_on_black_list_ids(
            $self->_suitable_scans_list(),
            $self->_black_list_ids_list(),
        )
}

sub get_next_id
{
    my $id;

    open my $in, "<", "next-id.txt";
    $id = <$in>;
    chomp($id);
    close($in);
    open my $out, ">", "next-id.txt";
    print $out ($id+1);
    close($out);

    return $id;
}

sub get_prev_scans
{
    my @prev_scans;
    open my $in, "<", "scans.txt";
    while (my $line = <$in>)
    {
        chomp($line);
        my ($scan_id, $cmd_line) = split(/\t/, $line);
        push @prev_scans, { 'id' => $scan_id, 'cmd_line' => $cmd_line };
    }
    close($in);

    return \@prev_scans;
}

sub _get_scan_cmd_line
{
    my $self = shift;
    my $args = shift;

    my $min_board = $args->{'min'} || 1;
    my $max_board = $args->{'max'} || 32_000;
    my $id = $args->{'id'};
    my $argv = $args->{'argv'};

    return
    [
        qw(freecell-solver-fc-pro-range-solve),
        $min_board, $max_board, "20",
        qw(--total-iterations-limit 100000 --binary-output-to),
        "data/$id.data.bin",
        @$argv,
    ];
}

sub time_scan
{
    my $self = shift;
    my $args = shift;

    my $min_board = $args->{'min'} || 1;
    my $max_board = $args->{'max'} || 32_000;
    my $id = $args->{'id'};

    my $cmd_line = $self->_get_scan_cmd_line($args);

    open my $from_cmd, "-|", @$cmd_line
        or die "Could not start '@$cmd_line'";
    open my $fcs_out, ">", "data/$id.fcs.moves.txt";
    open my $fc_pro_out, ">", "data/$id.fcpro.moves.txt";
    $fcs_out->autoflush(1);
    $fc_pro_out->autoflush(1);
    while (my $line = <$from_cmd>)
    {
        print $line;
        chomp($line);
        if ($line =~ m{\A\[\[Num FCS Moves\]\]=(.*)\z}o)
        {
            print {$fcs_out} "$1\n";
        }
        elsif ($line =~ m{\A\[\[Num FCPro Moves\]\]=(.*)\z}o)
        {
            print {$fc_pro_out} "$1\n";
        }
    }
    close($from_cmd);
    close($fcs_out);
    close($fc_pro_out);
}

1;

__END__

=pod

=head1 NAME

AI::Pathfinding::OptimizeMultiple::DataInputObj - handle the data input.

=head1 VERSION

version 0.0.2

=head1 SUBROUTINES/METHODS

=head2 $self->get_next_id()

Retrieves the next scan ID and increment it.

=head2 $self->get_prev_scans()

Returns an array reference of previous scan hash-refs.

=head2 my $hash_ref = $self->get_scans_iters_pdls()

Returns the hash ref mapping scan IDs/names to iteration PDLs.

=head2 my $hash_ref = $self->get_scans_lens_iters_pdls()

Returns the hash ref mapping scan IDs/names to iteration+lengths PDLs.

=head2 $self->num_boards()

The number of boards.

=head2 $self->selected_scans()

An accessor for the selected scans.

=head2 $self->start_board()

The index of the board to start from.

=head2 $self->time_scan()

Times a new scan.

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
