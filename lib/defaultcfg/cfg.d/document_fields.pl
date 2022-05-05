# id_number field used for storing document DOIs (or other PIDs).
# Primarily used by the DataCite DOI plugin
$c->{fields}->{document} = [
    {
        name => "id_number",
        type => "text",
        render_value => 'EPrints::Extras::render_possible_doi',
    },
];
