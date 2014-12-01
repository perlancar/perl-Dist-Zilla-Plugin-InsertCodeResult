package Dist::Zilla::Plugin::InsertCodeResult;

# DATE
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

use namespace::autoclean;

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content = $file->content;
    if($content =~ s{^#\s*CODE:\s*(.*)\s*$}{$self->_code_result($1)."\n"}egm) {
        $self->log(['inserting result of code '%s' in %s', $1, $file->name]);
        $file->content($content);
    }
}

sub _code_result {
    my($self, $code) = @_;

    my $res = eval $code;

    if ($@) {
        $res = "# InsertCodeResult: eval failed: $@";
    } else {
        unless (defined($res) && !ref($res)) {
            $res = dump($res);
        }
    }

    $res =~ s/^/ /gm;
    $res;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert the result of Perl code into your POD

=for Pod::Coverage .+

=head1 SYNOPSIS

In dist.ini:

 [InsertCodeResult]

In your POD:

 # CODE:


=head1 DESCRIPTION

This module finds C<# CODE: ...> directives in your POD, evals the specified
Perl code, and insert the result into your POD as a verbatim paragraph. If
result is a simple scalar, it is printed as is. If it is undef or a reference,
it will be dumped using L<Data::Dump>. If eval fails, a message like this will be inserted instead:

 # eval failed: syntax error at -e line 1, near ""x;" say"


=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertExample>
