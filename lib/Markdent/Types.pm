package Markdent::Types;

use strict;
use warnings;

our $VERSION = '0.09';

use base 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw( Markdent::Types::Internal
        MooseX::Types::Moose ));

1;
