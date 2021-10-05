=head1 NAME

EPrints::Plugin::Screen::Document

=cut


package EPrints::Plugin::Screen::Document;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
    my( $class, %params ) = @_;

    my $self = $class->SUPER::new(%params);

    return $self;
}

sub properties_from
{
    my( $self ) = @_;

    $self->{processor}->{eprint} = $self->{processor}->{document}->get_eprint;

    $self->SUPER::properties_from;
}

sub render_title
{
    my( $self ) = @_;

    my $session = $self->{session};

    my $f = $self->{session}->make_doc_fragment;

    my $eprint = $self->{processor}->{eprint};
    my $doc = $self->{processor}->{document};

    $f->appendChild( $self->{processor}->{eprint}->render_citation( "screen" ) );

    $f->appendChild( $self->{session}->html_phrase( "document_join" ) );

    $f->appendChild( $self->{processor}->{document}->render_citation( "screen" ) );

    return $f;

#    return $session->html_phrase( "Plugin/Screen/Document:page_title",
#    dataset => $session->html_phrase( "datasetname_".$self->{processor}->{dataset}->id ) );
}

sub render
{
    my( $self ) = @_;
    
    my $repo = $self->{repository};
    my $doc =  $self->{processor}->{document};

    my $page = $repo->make_doc_fragment;

    my $div = $repo->make_element( "div", class => "datacite_doc_citation" );
    
    my $table = $div->appendChild( $repo->make_element( "div", class => "ep_table" ) );
    my $tr = $table->appendChild( $repo->make_element( "div", class => "ep_table_row" ) );

    my $icon = $tr->appendChild( $repo->make_element( "div", class => "ep_table_cell" ) );
    $icon->appendChild( $doc->render_icon_link );

    my $citation = $tr->appendChild( $repo->make_element( "div", class => "ep_table_cell" ) );
    $citation->appendChild( $doc->render_citation_link );

    return( $div );
}

1;


=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2000-2011 University of Southampton.

=for COPYRIGHT END

=for LICENSE BEGIN

This file is part of EPrints L<http://www.eprints.org/>.

EPrints is free software: you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

EPrints is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints.  If not, see L<http://www.gnu.org/licenses/>.

=for LICENSE END

