package EPrints::Plugin::Import::DCXML;

use strict;

use EPrints::Plugin::Import::DefaultXML;

use Data::Dumper;

our @ISA = qw/ EPrints::Plugin::Import::DefaultXML /;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new(%params);

        $self->{name} = "DC XML";
        $self->{visible} = "all";
        $self->{produce} = [ 'list/eprint', 'dataobj/eprint' ];

        return $self;
}

sub top_level_tag
{
        my( $plugin, $dataset ) = @_;
        return "OAI-PMH";
}

sub xml_to_dataobj
{
        my( $plugin, $dataset, $xml ) = @_;

        my $epdata = $plugin->xml_to_epdata( $dataset, $xml );

        return $plugin->epdata_to_dataobj( $dataset, $epdata );
}

sub handler_class { "EPrints::Plugin::Import::DefaultXML::DOMHandler" }

sub xml_to_epdata
{
        # $xml is the PubmedArticle element
        my( $plugin, $dataset, $xml ) = @_;

        my $epdata = {};

        my $this_repo = $plugin->xml_to_text($xml->getElementsByTagName("oai_source")->item(0));
        my $this_repo_q = quotemeta $this_repo;
        my $this_repo_name = $plugin->xml_to_text($xml->getElementsByTagName("oai_source_name")->item(0));
        my $this_repo_id = $plugin->xml_to_text($xml->getElementsByTagName("oai_source_repo_id")->item(0));
        my $this_subj_id = $plugin->xml_to_text($xml->getElementsByTagName("oai_source_subj_id")->item(0));


        #title
        my $title = $xml->getElementsByTagName("title")->item(0);
        if(defined $title){
                my $title_str = $plugin->xml_to_text($title);
                $title_str =~ s/&#13;//g;
                $epdata->{title} = $title_str;
        }
        #creators (these seem to be very random in nature so putting into the lastname of the eprints creators_name... can be sorted out by a human later)
        foreach my $dc_creator ( $xml->getElementsByTagName("creator") )
        {
                my $name = {};
        #       $plugin->{session}->get_repository->log($plugin->xml_to_text($creator));
                my $creator = $plugin->xml_to_text($dc_creator);
                $creator =~ /^(.*), (.*)/;
                $name->{family} = $1 if defined $1;
                $name->{given} = $2 if defined $2;

                push @{ $epdata->{creators_name} }, $name;
        }

        # (these seem to be very random in nature so putting into the lastname of the eprints creators_name... can be sorted out by a human later)
        foreach my $dc_contributor ( $xml->getElementsByTagName("contributor") )
        {
                my $ed = {};
        #       $plugin->{session}->get_repository->log($plugin->xml_to_text($contributor));
                my $contributor = $plugin->xml_to_text($dc_contributor);
                $contributor =~ /^(.*), (.*)/;
                $ed->{family} = $1 if defined $1;
                $ed->{given} = $2 if defined $2;

                push @{ $epdata->{editors_name} }, $ed;
        }

        #publisher
        my $publisher = $xml->getElementsByTagName("publisher")->item(0);
        if(defined $publisher){
                $epdata->{publisher} = $plugin->xml_to_text($publisher);
        }

        #description (appending multiple descriptions into a newline separated text block)
        my $description = undef;
        foreach my $desc ( $xml->getElementsByTagName("description") )
        {
#               $plugin->{session}->get_repository->log($plugin->xml_to_text($desc));
                my $desc_str = $plugin->xml_to_text($desc);
                $desc_str =~ s/&#13;//g;
                $epdata->{abstract} = $desc_str;
        }

        #date
        my $dc_date = $xml->getElementsByTagName("date")->item(0);
        if(defined $dc_date){
                $epdata->{date} = $plugin->xml_to_text($dc_date);

        }
        #type (type typically describes the item type and whether it is peer reviewed)
        #DC has type labels so we'll need to convert these to the actual type value (bearing in mind that each new repo could have different labels!)
        my $type_trans = {"article" => "article",
                        "book section" => "book_section",
                        "monograph" => "monograph",
                        "conference or workshop item" => "conference_item",
                        "book" => "book",
                        "thesis" => "thesis",
                        "patent" => "patent",
                        "artefact" => "artefact",
                        "art/design item" => "art_design_item",
                        "show/exhibition" => "exhibition",
                        "composition" => "composition",
                        "performance" => "performance",
                        "image" => "image",
                        "video" => "video",
                        "audio" => "audio",
                        "dataset" => "dataset",
                        "experiment" => "experiment",
                        "teaching resource" => "teaching_resource",
                        "other" => "other",
                        #Mappings added for items from Bucks http://dspace.bucks.ac.uk/dspace-oai/request?verb=ListRecords&metadataPrefix=oai_dc
                        "book chapter" => "book_section",
                        "presentation" => "conference_item",
                        #http://insight.cumbria.ac.uk/cgi/oai2?verb=ListRecords&metadataPrefix=oai_dc
                        "report" => "report",
                        "musical composition" => "composition",
                        # The Welsh one
                        "text" => "book",
                        # SMUC
                        "journal article" => "article",
                };
        foreach my $type ( $xml->getElementsByTagName("type") )
        {
#               $plugin->{session}->get_repository->log("TYPE: ".$plugin->xml_to_text($type));
                my $type_str = $plugin->xml_to_text($type);
                if($type_str =~ /PeerReviewed/){
#                       $plugin->{session}->get_repository->log("Is peer reviewed style type tag");
                        if($type_str =~ /Non/){
                                $epdata->{refereed} = "FALSE";
                        }else{
#                               $plugin->{session}->get_repository->log("Is peer reviewed");
                                $epdata->{refereed} = "TRUE";
                        }
                        next;
                }
                #not the refereed flag so must be item type... needs translated
                if(defined $type_trans->{lc $plugin->xml_to_text($type)}){
                        $epdata->{type} = $type_trans->{lc $plugin->xml_to_text($type)};
                }else{
                        $plugin->{session}->get_repository->log("NON-Standard type (going in as 'other'): ".$plugin->xml_to_text($type));
                        $epdata->{type} = "other";
                }
        }
        #relation
        foreach my $rel ( $xml->getElementsByTagName("relation") ){
                my $rel_str = $plugin->xml_to_text($rel);
                if(defined $this_repo && $rel_str =~ /$this_repo_q/){
                        my $rel_url = {};
                        $rel_url->{url} = $rel_str;
                        push @{ $epdata->{related_url} }, $rel_url;
                }else{
                        $epdata->{official_url} = $plugin->xml_to_text($rel);
                }
        }
        # Resource identifier
        # EPrints... url of object or citation | DSpace/DigitalCommons url of abstract
        foreach my $ident ( $xml->getElementsByTagName("identifier") )
        {
                my $ident_str = $plugin->xml_to_text($ident);
                if($ident_str =~ /^http:\/\/.*\d$/){ #this will do FOR NOW! (oh no it won't! added pattern for start of string too)
                        my $rel_url = {};
                        $rel_url->{url} = $ident_str;
                        push @{ $epdata->{related_url} }, $rel_url;
                }
        }
        # Info on the source repository
        $epdata->{source_repository} = {name => $this_repo_name, url=>$this_repo, item_url=>$epdata->{related_url}->[0]->{url}};
        my $oai_identifier = $xml->getElementsByTagName("identifier")->item(0);
        if(defined $oai_identifier){
                $epdata->{source_repository}->{oai_identifier} = $plugin->xml_to_text($oai_identifier);
        }
#       print $plugin->xml_to_text($oai_identifier)." ".$epdata->{source_repository}->{item_url}."\n";

        foreach my $subject ( $xml->getElementsByTagName("subject") ){
                my $subj = $plugin->xml_to_text($subject);
                $subj =~ /^(\w+)\s*/;
                my $subj_part = $1;
                next if(!$subj_part);
                my $search = $plugin->{session}->get_repository->dataset("subject")->prepare_search();
                $search->add_field( $plugin->{session}->get_repository->dataset("subject")->get_field( "subjectid" ), $subj_part );
                my $sub_list = $search->perform_search;
#               print "search for $subj_part ($subj) returned ".$sub_list->count."\n";
                if($sub_list->count){
                        push @{ $epdata->{subjects} }, $subj_part;
                }else{
                        push @{ $epdata->{subjects} }, $subj;
                }
        }

        push @{ $epdata->{divisions} }, $this_subj_id;

        #dc: subject, source, format and type will go into the note field for the delictation of someone who might know what they can be used for.
        my $keywords = "";
        foreach my $subject ( $xml->getElementsByTagName("subject") )
        {
                $keywords .= $plugin->xml_to_text($subject)."; ";
        }
        if($keywords ne ""){
                $keywords =~ s/;\s$//;
                $keywords =~ s/&amp;/&/g; #these are escaped somewhere else.. once is enough;

                $epdata->{keywords} = $keywords;
        }

        # AH 01/11/2016: the following block of code conducts a search of the repository
        # using the source_repository_oai_identifier value. If the resulting $list has
        # at least one search result, it obtains the eprint_id from the first search
        # result and adds the eprint_id to the $epdata object constructed above. Because
        # the $epdata object will already have an eprint_id value, the system will
        # update the record, rather than create a new record.
        # NOTE: the conditional if statement checks if the list has one or more search
        # results as there could be cases where an item has one or more versions created
        # manually by a repository administrator and each version shares the same
        # source_repository_oai_identifier value

        my $searchexp = EPrints::Search->new(
          session => $plugin->{session},
          dataset => $dataset,
        );

        $searchexp->add_field(
          fields => $dataset->field( "source_repository_oai_identifier" ),
          value => $plugin->xml_to_text($oai_identifier) ,
          match => "EQ",
        );

        my $list = $searchexp->perform_search;

        if($list->count >= 1){
          my @data = $list->get_records;
          $epdata->{eprintid} = $data[0]->get_id;
        }

        return $epdata;

}

1;
