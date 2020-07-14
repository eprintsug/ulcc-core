$c->{accessibilityemail} = undef;

# set default accessibility email if no email specified
if( !defined $c->{accessibilityemail} )
{
    $c->{accessibilityemail} = $c->{adminemail};
}

