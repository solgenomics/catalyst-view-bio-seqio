package Catalyst::View::Bio::SeqIO;
# ABSTRACT: use Bio::SeqIO as a Catalyst View

use Moose;
use namespace::autoclean;

use IO::String;
use Bio::SeqIO;

extends 'Catalyst::View';

=head1 SYNOPSIS

    package MyApp::View::SeqIO;
    use Moose;
    extends 'Catalyst::View::Bio::SeqIO';

    __PACKAGE__->config(
        default_seqio_args => {
            -width => 80,
         },
        default_format       => 'fasta',
        default_content_type => 'text/plain',
        content_type_map     => {
            fasta => 'application/x-fasta',
        },
      );

=head1 ATTRIBUTES

Like all Catalyst components, the values for these can be set in a
C<__PACKAGE__-&gtconfig> statement or in your myapp.conf file.

=cut

=head2 sequences_stash_key

Stash key for arrayref of sequences to print out.  Default
'sequences'.

=cut

has 'sequences_stash_key' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'sequences',
  );

=head2 format_stash_key

Stash key under which to look for the sequence format.  Default
'seqio_format'.

=cut

has 'format_stash_key' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'seqio_format',
  );

=head2 object_stash_key

Stash key under which to look for a custom-constructed
Bio::SeqIO-compliant object to use for rendering sequences.  Default
'seqio_object'.

=cut

has 'object_stash_key' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'seqio_object',
  );

=head2 default_seqio_args

Hashref of default arguments to pass to constructed SeqIO objects.
Defaults to empty.

=cut

has 'default_seqio_args' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
  );

=head2 content_type_map

Hashref giving the mapping of SeqIO formats to content types.
Currently defaults to just

    {  fasta => 'application/x-fasta' }

Do you know proper MIME types for other formats?  Please tell me and
I'll add them.

=cut

has 'content_type_map' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        {
            'fasta' => 'application/x-fasta',
        }
    },
  );

=head2 default_content_type

Default content type to use when a format is not found in the
content_type_map.  Defaults to 'text/plain'.

=cut

has 'default_content_type' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'text/plain',
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
        $self->content_type_map->{$format} || $self->default_content_type
      );
    $c->res->body( IO::String->new( \$out_string ) );
}

1;
