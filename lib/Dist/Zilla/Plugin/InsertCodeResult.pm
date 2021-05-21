package Dist::Zilla::Plugin::InsertCodeResult;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dump qw(dump);

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles'],
    },
);

has make_verbatim => (is => 'rw', default => sub{1});

use namespace::autoclean;

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content_as_bytes = $file->encoded_content;
    if ($content_as_bytes =~ s{
                                  ^\#\s*CODE:\s*(.*)\s*(\R|\z) |
                                  ^\#\s*BEGIN_CODE\s*\R((?:.|\R)*?)^\#\s*END_CODE\s*(?:\R|\z)
                          }{
                              my $res = $self->_code_result($1 // $2);
                              $res .= "\n" unless $res =~ /\R\z/;
                              $res;
                          }egmx) {
        $self->log(["inserting result of code '%s' in %s", $1 // $2, $file->name]);
        $self->log_debug(["content of %s after code result insertion: '%s'", $file->name, $content_as_bytes]);
        $file->encoded_content($content_as_bytes);
    }
}

sub _code_result {
    my($self, $code) = @_;

    local @INC = @INC;
    unshift @INC, "lib";

    my $res = eval $code;

    if ($@) {
        die "eval '$code' failed: $@";
    } else {
        unless (defined($res) && !ref($res)) {
            $res = dump($res);
        }
    }

    $res =~ s/^/ /gm if $self->make_verbatim;
    $res;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert the result of Perl code into your POD

=for Pod::Coverage .+

=head1 SYNOPSIS

In dist.ini:

 [InsertCodeResult]
 ;make_verbatim=1

In your POD:

 # CODE: require MyLib; MyLib::gen_stuff("some", "param");

or for multiline code:

 # BEGIN_CODE
 require MyLib;
 MyLib::gen_stuff("some", "param");
 ...
 # END_CODE



=head1 DESCRIPTION

This module finds C<# CODE: ...> or C<# BEGIN_CODE> and C<# END CODE> directives
in your POD, evals the specified Perl code, and insert the result into your POD
as a verbatim paragraph (unless you set C<make_verbatim> to 0, in which case
output will be inserted as-is). If result is a simple scalar, it is printed as
is. If it is undef or a reference, it will be dumped using L<Data::Dump>. If
eval fails, build will be aborted.

The directives must be at the first column of the line.


=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertCodeOutput>

L<Dist::Zilla::Plugin::InsertExample>
