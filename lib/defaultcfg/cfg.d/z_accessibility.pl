# Accessibility Email
$c->{accessibilityemail} = undef;

# set default accessibility email if no email specified
if( !defined $c->{accessibilityemail} )
{
    $c->{accessibilityemail} = $c->{adminemail};
}

# Contact Page
$c->{contact_page} = undef;

# set default contact page if no email specified
if( !defined $c->{contact_page} )
{
    $c->{contact_page} = "/contact.html";
}
