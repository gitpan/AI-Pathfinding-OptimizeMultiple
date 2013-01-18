
use strict;
use warnings;

use Module::Build 0.3601;
use lib qw{inc}; use Test::Run::Builder;

my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::Differences" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "optimize path finding searches for a large\nset of initial conditions (for better average performance).",
  "dist_author" => [
    "Shlomi Fish <shlomif\@cpan.org>"
  ],
  "dist_name" => "AI-Pathfinding-OptimizeMultiple",
  "dist_version" => "0.0.3",
  "license" => "mit",
  "module_name" => "AI::Pathfinding::OptimizeMultiple",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Exception::Class" => 0,
    "File::Path" => 0,
    "Getopt::Long" => 0,
    "IO::File" => 0,
    "IO::Handle" => 0,
    "MooX" => 0,
    "PDL" => 0,
    "PDL::IO::FastRaw" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/optimize-game-ai-multi-tasking"
  ]
);


my $build = Test::Run::Builder->new(%module_build_args);

$build->create_build_script;
