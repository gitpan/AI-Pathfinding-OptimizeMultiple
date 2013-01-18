
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "optimize path finding searches for a large\nset of initial conditions (for better average performance).",
  "AUTHOR" => "Shlomi Fish <shlomif\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601",
    "Test::Differences" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "AI-Pathfinding-OptimizeMultiple",
  "EXE_FILES" => [
    "bin/optimize-game-ai-multi-tasking"
  ],
  "LICENSE" => "mit",
  "NAME" => "AI::Pathfinding::OptimizeMultiple",
  "PREREQ_PM" => {
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
  "VERSION" => "0.0.3",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



