##!/usr/bin/perl -w

use FindBin;
use lib "$FindBin::Bin/../perl_lib";
use Term::ANSIColor;
use EPrints;
use strict;
use Cwd;

sub print_ok {
        my $str = "[";
        $str.= color('bold green');
        $str.="OK";
        $str.= color('reset');
        $str.="]";
        return $str;

}
sub print_fail {
        my $str = "[";
        $str.= color('bold red');
        $str.= "FAIL";
        $str.= color('reset');
        $str.= "]";
        return $str;
}
my $eprints = EPrints->new();
my $repoid = shift @ARGV;
my $pluginid = shift @ARGV;

my $repo = $eprints->repository( $repoid );
if( !defined $repo )
{
	print STDERR "Failed to load repository: $repoid\n";
	exit 1;
}

chdir "$FindBin::Bin/../lib/epm/$pluginid" or die("Could not find $pluginid in lib/epm");
my $dir = getcwd;

print "\n";
print "#######################################\n";
print "  Checking dependancies for $pluginid  \n";
print "#######################################\n";
print "\n";


my $seen = {};
my $use_fail=0;
#imperfect way to gather epm dependencie
for my $use_stmt (`grep -rP '^use ' ./*`){
    next if $use_stmt =~ /use lib/;
    chomp $use_stmt;
    $use_stmt =~ /use (.*);/;
    next if $seen->{$1};
    eval "use $1; 1";
    if(!$@){
        printf "%-50s %s \n", $1, print_ok;
    }else{
        printf "%-50s %s \n", $1, print_fail;
        $use_fail=1;
    }
    $seen->{$1} =1;
}
print "\n";
print "Suggest running 'tools/epm link_lib $pluginid' to ensure that all the epm packages are available\n\n" if $use_fail;
print "#######################################################\n";
print "  Checking that all packages are loaded for $pluginid  \n";
print "#######################################################\n";
print "\n";

$seen = {};
my $pkg_fail=0;
#imperfect way to gather epm dependencie
for my $pkg (`grep -rP '^package ' ./*`){
#    next if $use_stmt =~ /use lib/;
    chomp $pkg;
    $pkg =~ /package EPrints::Plugin::(.*);/;
    next if $seen->{$1};
    my $class = $repo->get_plugin_factory->get_plugin_class( $1 );
    if( defined $class ){
        printf "%-50s %s \n", $1, print_ok;
    }else{
        printf "%-50s %s \n", $1, print_fail;
        $pkg_fail=1;
    }
}

print "\n";
print "Suggest running 'tools/epm link_lib $pluginid' to ensure that all the epm packages are available\n" if $pkg_fail;
print "DONE\n";
