package Markdent::Event::StartEmphasis;

use strict;
use warnings;

our $VERSION = '0.09';

use Markdent::Types qw( Str );

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

has delimiter => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

with 'Markdent::Role::Event';

with 'Markdent::Role::BalancedEvent' => { compare => [ 'delimiter' ] };

with 'Markdent::Role::EventAsText';

sub as_text { $_[0]->delimiter() }

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 NAME

Markdent::Event::StartEmphasis - An event for the start of an emphasis span

=head1 DESCRIPTION

This class represents the start of an emphasis span.

=head1 ATTRIBUTES

This class has the following attributes:

=head2 delimiter

The delimiter for the emphasis span.

=head1 METHODS

This class has the following methods:

=head2 $event->as_text()

Returns the event's delimiter.

=head1 ROLES

This class does the L<Markdent::Role::Event> and
L<Markdent::Role::BalancedEvent> roles.

=head1 BUGS

See L<Markdent> for bug reporting details.

=head1 AUTHOR

Dave Rolsky, E<lt>autarch@urth.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
