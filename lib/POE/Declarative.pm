use strict;
use warnings;

package POE::Declarative;

our $VERSION = '0.001';

require Exporter;
our @ISA = qw( Exporter );

use Carp;

our @EXPORT = qw(
    call delay post yield

    get

    on run
);

=head1 NAME

POE::Declarative - write POE applications without the mess

=head1 SYNOPSIS

  use POE;
  use POE::Declarative;

  on _start => run {
      yield 'count_to_10';
  };

  on count_to_10 => run {
      for ( 1 .. 10 ) {
          yield say => $_;
      }
  };

  on say => run {
      print get(ARG0);
  };

  POE::Declarative->setup;
  POE::Kernel->run;

=head1 DESCRIPTION

Taking the lessons learned from writing dispatchers and templates in L<Jifty> and L<Template::Declare>, I've applied the same declarative language to L<POE>. The goal is to make writing a POE application less painful so that I can concentrate on the more important aspects of my programming.

This module is still B<VERY EXPERIMENTAL>. I just wrote it this evening and it needs lots of work.

=head1 DECLARATIONS

=head2 on STATE => CODE

Use the C<on> rule to specify what code to run on a given state. The usual way to say this is:

  on _start => run { ... };

But you could also say:

  on _start => sub { ... };

or:

  on _start => run _start_handler;

or:

  on _start => \&_start_handler;

=cut

sub on($$) {
    my $state   = shift;
    my $code    = shift;

    croak qq{"on" expects a code reference as the second argument, found $code instead}
        unless ref $code eq 'CODE';

    my $package = caller;
    my $states  = _states();
    $states->{ $state } = sub { _args($package, @_); $code->(@_) };
}

=head2 run CODE

This is mostly a replacement keyword for C<sub> because:

  on _start => run { ... };

reads better than:

  on _start => sub { ... };

=cut

sub run(&) { $_[0] }

=head1 HELPERS

In addition to providing the declarative syntax the system also provides some helpers to shorten up the guts of your POE applications as well.

=head2 get INDEX

Rather than doing this (which you can still do inside your handlers):

  my ($kernel, $heap, $session, $flam, $floob, $flib)
      = @_[KERNEL, HEAP, SESSION, ARG0, ARG1, ARG2];

You can use the C<get> subroutine for a short hand, like:

  my $kernel = get KERNEL;
  get(HEAP)->{flubber} = 'doo';

If you don't like C<get>, don't use it. As I said, the code above will run exactly as you're used to if you're used to writing regular POE applications.

=cut

sub get($) {
    my $pos = shift;
    my $package = caller;
    return _args($package)->[ $pos ];
}

=head2 call SESSION, STATE, ARGS

This is just a shorthand for L<POE::Kernel/call>.

=cut

sub call($$;@) {
    POE::Kernel->call( @_ );
}

=head2 delay STATE, SECONDS, ARGS

This is just a shorthand for L<POE::Kernel/delay>.

=cut

sub delay($$;@) {
    POE::Kernel->delay( @_ );
}

=head2 post SESSION, STATE, ARGS

This is just a shorthand for L<POE::Kernel/post>.

=cut

sub post($$;@) {
    POE::Kernel->post( @_ );
}

=head2 yield STATE, ARGS

This is just a shorthand for L<POE::Kernel/yield>.

=cut

sub yield($;@) {
    POE::Kernel->yield( @_ );
}

=head1 SETUP METHODS

The setup methods setup your session and such and generally get your session read for the POE kernel to do its thing.

=head2 setup PACKAGE

Typically, this is called via:

  POE::Declarative->setup;

If called within the package defining the session, this should DWIM nicely. However, if you call it from outside the package (for example, you have several session packages that are then each set up from a central loader), you can also run:

  POE::Declarative->setup('MyPOEApp::Component::FlabbyBo');

=cut

sub _args {
    my $package = shift;
    my $args_var = $package . '::POE_ARGS';

    no strict 'refs';
    ${ $args_var } = [ @_ ] if scalar(@_) > 0;
    return ${ $args_var } || [];
}

sub _states {
    my $package = shift || caller(1);

    no strict 'refs';
    return (${ $package . '::STATES' } ||= {});
}

sub setup {
    my $class   = shift;
    unshift @_, $class if defined $class and $class ne __PACKAGE__;

    my $package = shift || caller;

    my $session = POE::Session->create(
        inline_states => _states($package),
    );
}

=head1 TODO

Lots and lots as of this writing. It doesn't handle much of the useful features of POE. I haven't tested it with other components. I haven't tested or made sure this properly supports inheritance.

There's probably more that I haven't thought of yet.

=head1 NONSENSE WORDS

My examples in this module feature some of my favorite nonsense words. I've picked up quite a few of them having a small child.

=head1 SEE ALSO

L<POE>

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
