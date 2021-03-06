package Hello::Controller::site;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Hello::Controller::site - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Hello::Controller::site in site.');
}

sub test : Local {
        my ( $self, $c ) = @_;
        # called via URL site/test 
        $c->stash->{username} = "John";
        $c->stash->{template} = 'site/test.tt';
}

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
