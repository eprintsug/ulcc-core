######################################################################
#
# EPrints::MetaField::Pagerange;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Pagerange> - no description

=head1 DESCRIPTION

not done

=over 4

=cut

package EPrints::MetaField::Pagerange;

use EPrints::MetaField::Text;
@ISA = qw( EPrints::MetaField::Text );

use strict;

# note that this renders pages ranges differently from
# eprints 2.2
sub render_single_value
{
	my( $self, $session, $value ) = @_;

	my $frag = $session->make_doc_fragment;

	# If there are leading zeros it's probably electronic (so 'other')
	if( $value =~ /^([1-9]\d*)$/ )
	{
		$frag->appendChild( $session->html_phrase( "lib/metafield/pagerange:from_page",
			from => $session->make_text( $1 ),
			pagerange => $session->make_text( $value ),
		));
	}
	elsif( $value =~ m/^([1-9]\d*)-(\d+)$/ )
	{
		if( $1 == $2 )
		{
			$frag->appendChild( $session->html_phrase( "lib/metafield/pagerange:same_page",
				from => $session->make_text( $1 ),
				to => $session->make_text( $2 ),
				pagerange => $session->make_text( $value ),
			));
		}
		else
		{
			$frag->appendChild( $session->html_phrase( "lib/metafield/pagerange:range",
				from => $session->make_text( $1 ),
				to => $session->make_text( $2 ),
				pagerange => $session->make_text( $value ),
			));
		}
	}
	else
	{
		$frag->appendChild( $session->html_phrase( "lib/metafield/pagerange:other",
			pagerange => $session->make_text( $value )
		));
	}

	return $frag;
}

sub get_basic_input_elements
{
	my( $self, $session, $value, $basename, $staff, $obj ) = @_;

	my @pages = split /-/, $value if( defined $value );
 	my $fromid = $basename."_from";
 	my $toid = $basename."_to";
		
	my $frag = $session->make_doc_fragment;

	$frag->appendChild( $session->render_noenter_input_field(
		class => "ep_form_text",
		name => $fromid,
		id => $fromid,
		value => $pages[0],
		size => 6,
		maxlength => 120 ) );

	$frag->appendChild( $session->make_text(" ") );
	$frag->appendChild( $session->html_phrase( 
		"lib/metafield:to" ) );
	$frag->appendChild( $session->make_text(" ") );

	$frag->appendChild( $session->render_noenter_input_field(
		class => "ep_form_text",
		name => $toid,
		id => $toid,
		value => $pages[1],
		size => 6,
		maxlength => 120 ) );

	return [ [ { el=>$frag } ] ];
}

sub get_basic_input_ids
{
	my( $self, $session, $basename, $staff, $obj ) = @_;

	return( $basename."_from", $basename."_to" );
}

sub is_browsable
{
	return( 1 );
}

sub form_value_basic
{
	my( $self, $session, $basename ) = @_;
	
	my $from = $session->param( $basename."_from" );
	my $to = $session->param( $basename."_to" );

	if( !defined $to || $to eq "" )
	{
		return( $from );
	}
		
	return( $from . "-" . $to );
}

sub ordervalue_basic
{
	my( $self , $value ) = @_;

	unless( EPrints::Utils::is_set( $value ) )
	{
		return "";
	}

	my( $from, $to ) = split /-/, $value;

	$to = $from unless defined $to;

	# remove non digits
	$from =~ s/[^0-9]//g;
	$to =~ s/[^0-9]//g;

	# set to zero if undef
	$from = 0 if $from eq "";
	$to = 0 if $to eq "";

	return sprintf( "%08d-%08d", $from, $to );
}

sub render_search_input
{
	my( $self, $session, $searchfield ) = @_;
	
	return $session->render_input_field(
				class => "ep_form_text",
				name=>$searchfield->get_form_prefix,
				value=>$searchfield->get_value,
				size=>9,
				maxlength=>100,
                'aria-labelledby' => $searchfield->get_form_prefix . "_label" );
}

######################################################################
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

