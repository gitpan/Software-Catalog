package Software::Catalog;

use 5.010;
use strict;
use warnings;

use Perinci::Sub::Gen::AccessTable 0.17 qw(gen_read_table_func);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       get_software_info
                       list_software
               );

our $VERSION = '0.02'; # VERSION

our %SPEC;

# XXX import catalog from software-catalog
# (https://github.com/sharyanto/software-catalog)
my @software = (
    {
        id           => 'wordpress',
        debian_names => [qw/wordpress/],
        tags         => [qw/
                               implemented-in::php
                               interface::web
                               web::blog
                           /],
    },
    {
        id           => 'joomla',
        debian_names => undef,
        tags         => [qw/
                               implemented-in::php
                               interface::web
                               web::cms
                           /],
    },
    {
        id           => 'jquery',
        debian_names => [qw/libjs-jquery/],
        tags         => [qw/
                               implemented-in::javascript
                               devel::library
                           /],
    },
    {
        id           => 'nginx',
        debian_names => [qw/nginx/],
        tags         => [qw/
                               implemented-in::c
                               interface::daemon
                               protocol::http
                           /],
    },
);

my $deb_re = qr/\A[a-z0-9]+(-[a-z0-9]+)*\z/;
my $tag_re = qr/\A([a-z0-9]+(-[a-z0-9]+)*::)?[a-z0-9]+(-[a-z0-9]+)*\z/x;

my $table_spec = {
    fields => {
        id => {
            index      => 0,
            schema     => ['str*' => {
                match => $deb_re,
            }],
            searchable => 1,
        },
        debian_names => {
            index      => 2,
            schema     => ['array' => {
                of => ['str*' => {
                    match => $deb_re,
                }],
            }],
            sortable   => 0,
        },
        tags => {
            index      => 2,
            schema     => ['array' => {
                of => ['str*' => match => $tag_re],
            }],
            sortable   => 0,
        },
        # XXX field: summary (in various languages)
        # XXX field: description (in various languages)
        # XXX field: license
        # XXX field: url

        # for download_url and releases/latest release, see
        # Software::Release::Watch
    },
    pk => 'id',
};

my $res = gen_read_table_func(
    name => 'list_software',
    table_data => \@software,
    table_spec => $table_spec,
    langs => ['en_US'],
);
die "BUG: Can't generate func: $res->[0] - $res->[1]"
    unless $res->[0] == 200;

$SPEC{get_software_info} = {
    v => 1.1,
    summary => 'Get info on a software',
    args => {
        id => {
            summary  => $table_spec->{fields}{id}{summary},
            schema   => $table_spec->{fields}{id}{schema},
            req      => 1,
            pos      => 0,
        },
    },
    "_perinci.sub.wrapper.validate_args" => 0,
};
sub get_software_info {
    my %args = @_;
    my $id = $args{id}; my $arg_err; ((defined($id)) ? 1 : (($arg_err = 'TMPERRMSG: required data not specified'),0)) && ((!ref($id)) ? 1 : (($arg_err = 'TMPERRMSG: type check failed'),0)) && (($id =~ /(?^:\A[a-z0-9]+(-[a-z0-9]+)*\z)/) ? 1 : (($arg_err = 'TMPERRMSG: clause failed: match'),0)); if ($arg_err) { return [400, "Invalid argument value for id: $arg_err"] } # VALIDATE_ARG

    my $res = list_software("id" => $id, detail=>1);
    return [404, "No such software"] unless @{$res->[2]};

    [200, "OK", $res->[2][0]];
}

# XXX get_software_XXX_info (if later on we need more specific info, or when
# retrieving all info becomes heavy).

1;
# ABSTRACT: Software catalog



__END__
=pod

=head1 NAME

Software::Catalog - Software catalog

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Software::Catalog qw(list_software get_software_info);
 my $res = list_software();

=head1 DESCRIPTION

This module contains catalog of software.

Currently the main use for this module is to establish a common name for a
software and find the Debian source package name(s) (and possibly others too in
the future, like Fedora package, FreeBSD port, etc) for it.

Eventually, if the project takes off, this will also contain
summary/description/URL/license for each software.

=head1 STATUS

Proof of concept. Incomplete catalog.

=head1 FAQ

=head1 SEE ALSO

L<Software::Release::Watch>

L<Software::Installation::Detect>

=head1 DESCRIPTION


This module has L<Rinci> metadata.

=head1 FUNCTIONS


None are exported by default, but they are exportable.

=head2 get_software_info(%args) -> [status, msg, result, meta]

Get info on a software.

Arguments ('*' denotes required arguments):

=over 4

=item * B<id>* => I<str>

=back

Return value:

Returns an enveloped result (an array). First element (status) is an integer containing HTTP status code (200 means OK, 4xx caller error, 5xx function error). Second element (msg) is a string containing error message, or 'OK' if status is 200. Third element (result) is optional, the actual result. Fourth element (meta) is called result metadata and is optional, a hash that contains extra information.

=head2 list_software(%args) -> [status, msg, result, meta]

REPLACE ME.

REPLACE ME

Data is in table form. Table fields are as follow:

=over

=item *

I<id> (ID field)



=item *

I<debian_names>



=item *

I<tags>



=back

Arguments ('*' denotes required arguments):

=over 4

=item * B<debian_names> => I<array>

Only return records where the 'debian_names' field equals specified value.

=item * B<debian_names.has> => I<array>

Only return records where the 'debian_names' field is an array/list which contains specified value.

=item * B<debian_names.is> => I<array>

Only return records where the 'debian_names' field equals specified value.

=item * B<debian_names.lacks> => I<array>

Only return records where the 'debian_names' field is an array/list which does not contain specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<fields> => I<array>

Select fields to return.

=item * B<id> => I<str>

Only return records where the 'id' field equals specified value.

=item * B<id.contains> => I<str>

Only return records where the 'id' field contains specified text.

=item * B<id.is> => I<str>

Only return records where the 'id' field equals specified value.

=item * B<id.max> => I<str>

Only return records where the 'id' field is less than or equal to specified value.

=item * B<id.min> => I<array>

Only return records where the 'id' field is greater than or equal to specified value.

=item * B<id.not_contains> => I<str>

Only return records where the 'id' field does not contain a certain text.

=item * B<id.xmax> => I<str>

Only return records where the 'id' field is less than specified value.

=item * B<id.xmin> => I<array>

Only return records where the 'id' field is greater than specified value.

=item * B<q> => I<str>

Search.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<str>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<tags> => I<array>

Only return records where the 'tags' field equals specified value.

=item * B<tags.has> => I<array>

Only return records where the 'tags' field is an array/list which contains specified value.

=item * B<tags.is> => I<array>

Only return records where the 'tags' field equals specified value.

=item * B<tags.lacks> => I<array>

Only return records where the 'tags' field is an array/list which does not contain specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hash/associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).

=back

Return value:

Returns an enveloped result (an array). First element (status) is an integer containing HTTP status code (200 means OK, 4xx caller error, 5xx function error). Second element (msg) is a string containing error message, or 'OK' if status is 200. Third element (result) is optional, the actual result. Fourth element (meta) is called result metadata and is optional, a hash that contains extra information.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

