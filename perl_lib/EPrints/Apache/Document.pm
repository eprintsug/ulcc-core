=head1 NAME

EPrints::Apache::Document

=cut

######################################################################
#
# EPrints::Apache::Document
#
######################################################################

package EPrints::Apache::Document;

use strict;

use EPrints;
use EPrints::Apache::AnApache;

sub handler
{
    my( $r ) = @_;

    my $uri = $r->uri;

    if( $uri =~ m#^/document/(.*)$# )
    {
        my $repository = $EPrints::HANDLE->current_repository;
        return DECLINED if( !defined $repository );

        # Document landing pages enabled for this repository?
        return DECLINED unless( $repository->config( "doc_landing_pages_enabled" ) );

        my $doc_id = $1;

        my $doc_ds = $repository->dataset( "document" );
        my $doc = $doc_ds->dataobj( $doc_id );

        if( defined $doc )
        {
            EPrints::ScreenProcessor->process(
                session => $repository,
                screenid => "Document",
                document => $doc,
            );
            return OK;
        }
    }

    return DECLINED;
}

1;
