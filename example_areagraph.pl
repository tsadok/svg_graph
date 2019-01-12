#!/usr/bin/perl
# -*- cperl -*-

do './svg_graph.pl';

open SVG, ">", "example_areagraph.svg";
print SVG svg(areagraph( title    => "Sample Area Graph",
                         subtitle => 'https://github.com/tsadok/svg_graph.git',
                         xlabels  => [ qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec) ],
                         data     => [
                                      +{ name   => "Corn",
                                          values => [ 103, 108, 112, 119, 134, 148,
                                                      169, 185, 195, 169, 147, 120, ],
                                       },
                                      +{ name   => "Wheat",
                                          values => [ 185, 207, 193, 171, 185, 197,
                                                      213, 218, 199, 182, 173, 180, ],
                                        },
                                       +{ name   => "Rice",
                                          values => [ 228, 235, 231, 223, 216, 209,
                                                      203, 209, 212, 209, 216, 220, ],
                                        },
                                       +{ name   => "Potatoes",
                                          values => [  67,  94, 127, 149, 162, 188,
                                                      193, 176, 151, 118,  88,  71, ],
                                        },
                                     ],
                       ));
