package MetaCPAN::Server::View::Pod;

use strict;
use warnings;

use MetaCPAN::Pod::Renderer;
use Moose;

extends 'Catalyst::View';

sub process {
    my ( $self, $c ) = @_;

    my $content = $c->res->body || $c->stash->{source};
    my $link_mappings = $c->stash->{link_mappings};
    $content = eval { join( q{}, $content->getlines ) };

    my ( $body, $content_type );
    my $accept = eval { $c->req->preferred_content_type } || 'text/html';
    my $show_errors = $c->req->params->{show_errors};

    my $x_codes = $c->req->params->{x_codes};
    $x_codes = $c->config->{pod_html_x_codes} unless defined $x_codes;

    my $renderer = $self->_factory(
        no_errata_section => !$show_errors,
        nix_X_codes       => !$x_codes,
        ( $link_mappings ? ( link_mappings => $link_mappings ) : () ),
    );
    if ( $accept eq 'text/plain' ) {
        $body         = $renderer->to_text($content);
        $content_type = 'text/plain';
    }
    elsif ( $accept eq 'text/x-pod' ) {
        $body         = $renderer->to_pod($content);
        $content_type = 'text/plain';
    }
    elsif ( $accept eq 'text/x-markdown' ) {
        $body         = $renderer->to_markdown($content);
        $content_type = 'text/plain';
    }
    else {
        $body         = $renderer->to_html($content);
        $content_type = 'text/html';
    }

    $c->res->content_type($content_type);
    $c->res->body($body);
}

sub _factory {
    my $self = shift;
    return MetaCPAN::Pod::Renderer->new(@_);
}

1;
