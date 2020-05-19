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

chdir "$FindBin::Bin/../lib/epm/$pluginid/lib" or die("Could not find $pluginid in lib/epm/lib");
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
print "Suggest installing any required modeules and/or running 'tools/epm link_lib $pluginid' to ensure that all the epm packages are available\n\n" if $use_fail;
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

    if($pkg =~ /package EPrints::Plugin::(.*);/){
        my $plugin_pkg = $1;
        next if $seen->{$plugin_pkg};
        
        # Modules that are abstract or otherwise DISABLED should not be checked as they won't have been loaded
        my ($file,$package) = split/:package /,$pkg;
        $package =~ s/;$//;
        my $str = "grep -rP \"\$$package\:\:DISABLE\\s*=\\s*1\" $file";
        next if `$str`;
        my $class = $repo->get_plugin_factory->get_plugin_class( $plugin_pkg );
        if( defined $class ){
            printf "%-50s %s \n", $plugin_pkg, print_ok;
        }else{
            printf "%-50s %s \n", $plugin_pkg, print_fail;
            $pkg_fail=1;
        }
        $seen->{$plugin_pkg} = 1;
    }
}

print "\n";
print "Suggest running 'tools/epm link_lib $pluginid' to ensure that all the epm packages are available\n" if $pkg_fail;
print "DONE\n";
