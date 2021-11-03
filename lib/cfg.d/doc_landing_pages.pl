$c->{doc_landing_pages_enabled} = 1;

$c->add_trigger( EP_TRIGGER_URL_REWRITE, sub
{
    my( %args ) = @_;

    my( $uri, $rc, $request ) = @args{ qw( uri return_code request ) };

    if( defined $uri && ($uri =~ m#^/document/(.*)$# ) )
    {
        $request->handler('perl-script');
        $request->set_handlers(PerlResponseHandler => [ 'EPrints::Apache::Document' ] );
        ${$rc} = EPrints::Const::OK;
    }
    
    return EP_TRIGGER_OK;

}, priority => 100 );
