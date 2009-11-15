use strict;
use warnings;

use Test::More;

plan 'no_plan';

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<'EOF';
> blockquote
>
> * with list
> * more list
>
> back to blockquote
EOF

    my $expect = [
        { type => 'blockquote' },
        [
            { type => 'paragraph' },
            [
                {
                    type => 'text',
                    text => "blockquote\n",
                },
            ],
            { type => 'unordered_list' },
            [
                { type => 'list_item' },
                [
                    {
                        type => 'text',
                        text => "with list\n",
                    },
                ],
                { type => 'list_item' },
                [
                    {
                        type => 'text',
                        text => "more list\n",
                    },
                ],
            ],
            { type => 'paragraph' },
            [
                {
                    type => 'text',
                    text => "back to blockquote\n",
                },
            ],
        ],
    ];

    parse_ok( $text, $expect, 'blockquote contains a list' );
}

{
    my $text = <<'EOF';
> Email-style angle brackets
> are used for blockquotes.

> > And, they can be nested.

> #### Headers in blockquotes
> 
> * You can quote a list.
> * Etc.
EOF

    my $expect = [
        { type => 'blockquote' },
        [
            { type => 'paragraph' },
            [
                {
                    type => 'text',
                    text =>
                        "Email-style angle brackets\nare used for blockquotes.\n",
                },
            ],
            { type => 'blockquote' },
            [
                { type => 'paragraph' },
                [
                    {
                        type => 'text',
                        text => "And, they can be nested.\n",
                    },
                ],
            ], {
                type  => 'header',
                level => 4,
            },
            [
                {
                    type => 'text',
                    text => "Headers in blockquotes\n",
                },
            ],
            { type => 'unordered_list' },
            [
                { type => 'list_item' },
                [
                    {
                        type => 'text',
                        text => "You can quote a list.\n",
                    },
                ],
                { type => 'list_item' },
                [
                    {
                        type => 'text',
                        text => "Etc.\n",
                    },
                ],
            ],
        ],
    ];

    parse_ok( $text, $expect, 'blockquote contains headers, blockquote and list (from Dingus examples)' );
}
