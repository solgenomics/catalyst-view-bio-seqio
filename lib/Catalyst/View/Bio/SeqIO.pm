package Catalyst::View::Bio::SeqIO;
use Moose;
use namespace::autoclean;

=head1 NAME

Catalyst::View::Bio::SeqIO - use Bio::SeqIO as a Catalyst View

=cut

use IO::String;
use Bio::SeqIO;

extends 'Catalyst::View';

has 'sequences_stash_key' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'sequences',
  );

has 'format_stash_key' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'seqio_format',
  );

has 'object_stash_key' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'seqio_object',
  );

has 'default_seqio_args' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} },
  );

has 'content_type_map' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {
            'fasta' => 'application/fasta',
        }
    },
  );

sub process {
    my ( $self, $c ) = @_;

    my $format = $c->stash->{ $self->format_stash_key } || 'fasta';

    my $out_string = '';
    my $seq_out =
      $c->stash->{ $self->object_stash_key }
      || Bio::SeqIO->new(
          %{ $self->default_seqio_args || {} },
          -format => $format,
          -fh     => IO::String->new( \$out_string ),
        );

    $seq_out->write_seq( $_ )
        for @{ $c->stash->{ $self->sequences_stash_key } || [] };

    $c->res->content_length( length $out_string );
    $c->res->content_type(
        $self->content_type_map->{'format'} || 'text/plain'
      );
    $c->res->body( IO::String->new( \$out_string ) );
}

1;
