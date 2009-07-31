use strict;
use utf8;
use Test::More;
use Data::Localize;

BEGIN
{
    eval "require HTML::FormFu; require CGI";
    if ($@) {
        plan(skip_all => "CGI/HTML::FormFu is not installed");
    } else {
        plan(tests => 1);
    }
}

my $cgi = CGI->new({
    submit => 'submit'
});

my $localize = Data::Localize->new();
$localize->add_localizer(
    class => "Namespace",
    namespace => "HTML::FormFu::I18N"
);

my $formfu = HTML::FormFu->new({
    languages => 'ja',
});
$formfu->add_default_localize_object($localize);

$formfu->populate({
    auto_fieldset => 1,
    indicator => 'submit',
    elements => [
        {
            type => "Text",
            name => "required_field",
            constraints => [
                'Required'
            ]
        },
        {
            type => "Submit",
            name => "submit",
            value => "submit",
        }
    ]
});
$formfu->process($cgi);
$formfu->submitted_and_valid;

my $output = $formfu->render;
like($output, qr/必須項目/, "error message is properly localized");
