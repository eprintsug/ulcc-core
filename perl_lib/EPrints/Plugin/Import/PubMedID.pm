=head1 NAME

EPrints::Plugin::Import::PubMedID

=cut

package EPrints::Plugin::Import::PubMedID;

use strict;


use EPrints::Plugin::Import;
use URI;
use LWP::Simple;
use LWP::UserAgent;
use XML::LibXML;

our @ISA = qw/ EPrints::Plugin::Import /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "PubMed ID";
	$self->{visible} = "all";
	$self->{produce} = [ 'list/eprint', 'dataobj/eprint' ];

    #RM update to use https
	$self->{EFETCH_URL} = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml&rettype=full';

	return $self;
}

sub input_fh
{
	my( $plugin, %opts ) = @_;

	my @ids;

	my $pubmedxml_plugin = $plugin->{session}->plugin( "Import::PubMedXML", Handler=>$plugin->handler );
	$pubmedxml_plugin->{parse_only} = $plugin->{parse_only};
	my $fh = $opts{fh};
	while( my $pmid = <$fh> )
	{
		$pmid =~ s/^\s+//;
		$pmid =~ s/\s+$//;
		if( $pmid !~ /^[0-9]+$/ ) # primary IDs are always an integer
		{
			$plugin->warning( "Invalid ID: $pmid" );
			next;
		}
		my $parser = XML::LibXML->new();
		$parser->validation(0);

		# Fetch metadata for individual PubMed ID 
		# NB. EFetch utility can be passed a list of PubMed IDs but
		# fails to return all available metadata if the list 
		# contains an invalid ID
		my $url = URI->new( $plugin->{EFETCH_URL} );
		$url->query_form( $url->query_form, id => $pmid );

		#my $xml = EPrints::XML::parse_url( $url );
        
        #RM Use LWP which works with https, 
        #Minimal additions from https://github.com/eprintsug/PubMedID-Import/blob/master/perl_lib/EPrints/Plugin/Import/PubMedID.pm to make Import functional
		my $host = $plugin->{session}->get_repository->config( 'host ');

		my $req = HTTP::Request->new( "GET", $url );
		$req->header( "Accept" => "text/xml" );
		$req->header( "Accept-Charset" => "utf-8" );
		$req->header( "User-Agent" => "EPrints 3.3.x; " . $host  );

		my $ua = LWP::UserAgent->new;
		$ua->env_proxy;
		$ua->timeout(60);
		my $response = $ua->request($req);
		my $success = $response->is_success;
		
		if ( $response->code != 200 )
		{
			print STDERR "HTTP status " . $response->code .  " from ncbi.nlm.nih.gov for PubMed ID $pmid\n";
		}

		my $xml;	

		if (!$success)
		{	
			$xml = $parser->parse_string( '<?xml version="1.0" ?><eFetchResult><ERROR>' . $response->code . '</ERROR></eFetchResult>' );
		}else{
			$xml = $parser->parse_string( $response->content );
		}
        ########## end additions for LWP/https #############

		my $root = $xml->documentElement;

		if( $root->nodeName eq 'ERROR' )
		{
			EPrints::XML::dispose( $xml );
			$plugin->warning( "No match: $pmid" );
			next;
		}

		foreach my $article ($root->getElementsByTagName( "PubmedArticle" ))
		{
			my $item = $pubmedxml_plugin->xml_to_dataobj( $opts{dataset}, $article );
			if( defined $item )
			{
				push @ids, $item->get_id;
			}
		}

		EPrints::XML::dispose( $xml );
	}

	return EPrints::List->new( 
		dataset => $opts{dataset}, 
		session => $plugin->{session},
		ids=>\@ids );
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

