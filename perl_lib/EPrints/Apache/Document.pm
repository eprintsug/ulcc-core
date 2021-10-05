=head1 NAME

EPrints::Apache::Document

=cut

######################################################################
#
# EPrints::Apache::Document
#
######################################################################
#
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

        if( $uri =~ m! ^\/document\/([0-9a-zA-Z]+)(.*)$ !x )
        {
                my $repository = $EPrints::HANDLE->current_repository;
                return DECLINED if( !defined $repository );

                # Lists enabled for this repo?
                return DECLINED unless( $repository->config( "doc_landing_pages_enabled" ) );

                #get the lista
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

