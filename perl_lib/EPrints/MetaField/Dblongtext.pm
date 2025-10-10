######################################################################
#
# EPrints::MetaField::Dblongtext;
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Dblongtext> A Longtext field with a much bigger character count.

=head1 DESCRIPTION
The same as the Longtext field, but this time in the Database sense of LONGTEXT, meaning
we can store up to 4,294,967,295 characters - to be used sparingly and preferable not where
a user/service can automatically populate the field with rubbish!

=over 4

=cut

package EPrints::MetaField::Dblongtext;

use strict;
use warnings;

BEGIN
{
    our( @ISA );

    @ISA = qw( EPrints::MetaField::Longtext );
}

use EPrints::MetaField::Longtext;

sub get_property_defaults
{
        my( $self ) = @_;
        my %defaults = $self->SUPER::get_property_defaults;
        $defaults{maxlength} = 4294967295;
        return %defaults;
}

1;
