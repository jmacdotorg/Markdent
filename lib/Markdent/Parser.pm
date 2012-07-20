package Markdent::Parser;

use strict;
use warnings;
use namespace::autoclean 0.09;

use Class::Load qw( load_optional_class );
use Markdent::Dialect::Standard::BlockParser;
use Markdent::Dialect::Standard::SpanParser;
use Markdent::Types
    qw( ArrayRef HashRef BlockParserClass BlockParserDialectRole SpanParserClass SpanParserDialectRole Str );
use Moose::Meta::Class;
use MooseX::Params::Validate qw( validated_list );
use Try::Tiny;

use Moose 0.92;
use MooseX::SemiAffordanceAccessor 0.05;
use MooseX::StrictConstructor 0.08;

with 'Markdent::Role::AnyParser';

has _block_parser_class => (
    is       => 'rw',
    isa      => BlockParserClass,
    init_arg => 'block_parser_class',
    default  => 'Markdent::Dialect::Standard::BlockParser',
);

has _block_parser => (
    is       => 'rw',
    does     => 'Markdent::Role::BlockParser',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_block_parser',
);

has _block_parser_args => (
    is       => 'rw',
    does     => HashRef,
    init_arg => undef,
);

has _span_parser_class => (
    is       => 'rw',
    isa      => SpanParserClass,
    init_arg => 'span_parser_class',
    default  => 'Markdent::Dialect::Standard::SpanParser',
);

has _span_parser => (
    is       => 'ro',
    does     => 'Markdent::Role::SpanParser',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_span_parser',
);

has _span_parser_args => (
    is       => 'rw',
    does     => HashRef,
    init_arg => undef,
);

override BUILDARGS => sub {
    my $class = shift;

    my $args = super();

    if ( exists $args->{dialect} ) {

        # XXX - deprecation warning
        $args->{dialects} = [ delete $args->{dialect} ];
    }
    elsif ( exists $args->{dialects} ) {
        $args->{dialects} = [ $args->{dialects} ]
            unless ref $args->{dialects};
    }

    return $args;
};

sub BUILD {
    my $self = shift;
    my $args = shift;

    $self->_set_classes_for_dialects($args);

    my %sp_args;
    for my $key (
        grep { defined }
        map  { $_->init_arg() }
        $self->_span_parser_class()->meta()->get_all_attributes()
        ) {

        $sp_args{$key} = $args->{$key}
            if exists $args->{$key};
    }

    $sp_args{handler} = $self->handler();

    $self->_set_span_parser_args( \%sp_args );

    my %bp_args;
    for my $key (
        grep { defined }
        map  { $_->init_arg() }
        $self->_block_parser_class()->meta()->get_all_attributes()
        ) {

        $bp_args{$key} = $args->{$key}
            if exists $args->{$key};
    }

    $bp_args{handler}     = $self->handler();
    $bp_args{span_parser} = $self->_span_parser();

    $self->_set_block_parser_args( \%bp_args );
}

sub _set_classes_for_dialects {
    my $self = shift;
    my $args = shift;

    my $dialects = delete $args->{dialects};

    return unless @{ $dialects // [] };

    for my $thing (qw( block_parser span_parser )) {
        my @roles;

        for my $dialect ( @{$dialects} ) {
            my $role = $self->_role_name_for_dialect( $dialect, $thing );

            load_optional_class($role)
                or next;

            my $specified_class = $args->{ $thing . '_class' };

            next
                if $specified_class
                && $specified_class->can('meta')
                && $specified_class->meta()->does_role($role);

            push @roles, $role;
        }

        next unless @roles;

        my $class_meth = q{_} . $thing . '_class';

        my $class = Moose::Meta::Class->create_anon_class(
            superclasses => [ $self->$class_meth() ],
            roles        => \@roles,
            cache        => 1,
        )->name();

        my $set_meth = '_set' . $class_meth;
        $self->$set_meth($class);
    }
}

sub _role_name_for_dialect {
    my $self    = shift;
    my $dialect = shift;
    my $type    = shift;

    my $suffix = join q{}, map { ucfirst } split /_/, $type;

    if ( $dialect =~ /::/ ) {
        return join '::', $dialect, $suffix;
    }
    else {
        return join '::', 'Markdent::Dialect', $dialect, $suffix;
    }
}

sub _build_block_parser {
    my $self = shift;

    return $self->_block_parser_class()->new( $self->_block_parser_args() );
}

sub _build_span_parser {
    my $self = shift;

    return $self->_span_parser_class()->new( $self->_span_parser_args() );
}

sub parse {
    my $self = shift;
    my ($text) = validated_list(
        \@_,
        markdown => { isa => Str },
    );

    $self->_clean_text( \$text );

    $self->_send_event('StartDocument');

    $self->_block_parser()->parse_document( \$text );

    $self->_send_event('EndDocument');

    return;
}

sub _clean_text {
    my $self = shift;
    my $text = shift;

    ${$text} =~ s/\r\n?/\n/g;
    ${$text} .= "\n"
        unless substr( ${$text}, -1, 1 ) eq "\n";

    return;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A markdown parser

__END__

=pod

=head1 SYNOPSIS

  my $handler = Markdent::Handler::HTMLStream->new( ... );

  my $parser = Markdent::Parser->new(
      dialect => ...,
      handler => $handler,
  );

  $parse->parse( markdown => $markdown );

=head1 DESCRIPTION

This class provides the primary interface for creating a parser. It ties a
block and span parser together with a handler.

By default, it will parse the standard Markdown dialect, but you can provide
alternate block or span parser classes.

=head1 METHODS

This class provides the following methods:

=head2 Markdent::Parser->new(...)

This method creates a new parser. It accepts the following parameters:

=over 4

=item * dialect => $name

You can use this as a shorthand to pick a block and/or span parser class.

If the dialect parameter does not contain a namespace separator (::), the
constructor looks for classes named
C<Markdent::Dialect::${dialect}::BlockParser> and
C<Markdent::Dialect::${dialect}::SpanParser>.

If the dialect parameter does contain a namespace separator, it is used a
prefix - C<$dialect::BlockParser> and C<$dialect::SpanParser>.

If any relevant classes are found, they will be used by the parser.

You can I<also> specify an explicit block or span parser, but if the dialect
has its own class of that type, an error will be thrown.

If the dialect only specifies a block or span parser, but not both, then we
fall back to using the appropriate parser for the Standard dialect.

=item * block_parser_class => $class

This default to L<Markdent::Dialect::Standard::BlockParser>, but can be any
class which implements the L<Markdent::Role::BlockParser> role.

=item * span_parser_class => $class

This default to L<Markdent::Dialect::Standard::SpanParser>, but can be any
class which implements the L<Markdent::Role::SpanParser> role.

=item * handler => $handler

This can be any object which implements the L<Markdent::Role::Handler>
role. It is required.

=back

=head2 $parser->parse( markdown => $markdown )

This method parses the given document. The parsing will cause events to be
fired which will be passed to the parser's handler.

=head1 ROLES

This class does the L<Markdent::Role::EventsAsMethods> and
L<Markdent::Role::Handler> roles.

=head1 BUGS

See L<Markdent> for bug reporting details.

=cut
