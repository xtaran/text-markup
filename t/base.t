#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;
#use Test::More tests => 32;
use Test::More 'no_plan';
use HTML::Entities;

BEGIN { use_ok 'Text::Markup' or die; }

can_ok 'Text::Markup' => qw(
    register
    formats
    new
    parse
    default_format
    get_parser
);

is_deeply [Text::Markup->formats], [],
    'Should be no registered parsers';

# Register one.
PARSER: {
    package My::Cool::Parser;
    use Text::Markup;
    Text::Markup->register(cool => qr{cool});
    sub parser {
        return $_[1] ? $_[1]->[0] : 'hello';
    }
}

is_deeply [Text::Markup->formats], ['cool'],
    'Should be now have the "cool" parser';

my $parser = new_ok 'Text::Markup';
is $parser->default_format, undef, 'Should have no default format';

$parser = new_ok 'Text::Markup', [default_format => 'cool'];
is $parser->default_format, 'cool', 'Should have default format';

is $parser->get_parser({ format => 'cool' }), My::Cool::Parser->can('parser'),
    'Should be able to find specific parser';

is $parser->get_parser({ file => 'foo' }), My::Cool::Parser->can('parser'),
    'Should be able to find default format parser';

is $parser->get_parser({format => 'default'}), Text::Markup::None->can('parser'),
    'Should be able to find the default parser';

ok $parser->default_format('none'), 'Set the default format to "none"';
is $parser->get_parser({ file => 'foo'}), Text::Markup::None->can('parser'),
    'Should be find the specified default parser';

# Now make it guess the format.
$parser->default_format(undef);
is $parser->get_parser({ file => 'foo.cool'}), My::Cool::Parser->can('parser'),
    'Should be able to guess the parser file the file name';

# Now test guess_format.
is $parser->guess_format('foo.cool'), 'cool',
    'Should guess "cool" format file "foo.cool"';
is $parser->guess_format('foocool'), undef,
    'Should not guess "cool" format file "foocool"';
is $parser->guess_format('foo.cool.txt'), undef,
    'Should not guess "cool" format file "foo.cool.txt"';

# Add another parser.
PARSER: {
    package My::Funky::Parser;
    Text::Markup->register(funky => qr{funky(?:[.]txt)?});
    sub parser {
        use utf8;
        return 'fünky';
    }
}

is_deeply [Text::Markup->formats], ['cool', 'funky'],
    'Should be now have the "cool" and "funky" parsers';
is $parser->guess_format('foo.cool'), 'cool',
    'Should still guess "cool" format file "foo.cool"';
is $parser->guess_format('foo.funky'), 'funky',
    'Should guess "funky" format file "foo.funky"';
is $parser->guess_format('foo.funky.txt'), 'funky',
    'Should guess "funky" format file "foo.funky.txt"';

# Now try parsing.
is $parser->parse(
    file   => 'README',
    format => 'cool',
), 'hello', 'Test the "cool" parser';

# Send output to a file.
is $parser->parse(
    file   => 'README',
    format => 'funky',
), 'fünky', 'Test the "funky" parser';

# Test opts to the parser.
is $parser->parse(
    file    => 'README',
    format  => 'cool',
    options => ['goodbye'],
), 'goodbye', 'Test the "cool" parser with options';

# Test the "none" parser.
my $output = do {
    open my $fh, '<:utf8', __FILE__ or die 'Cannot open ' . __FILE__ . ": $!\n";
    local $/;
    '<pre>' . encode_entities(<$fh>) . '</pre>';
};
$parser->default_format(undef);
is $parser->parse(
    file => __FILE__,
), $output, 'Test the "none" parser';
