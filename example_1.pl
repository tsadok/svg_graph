#!/usr/bin/perl
# -*- cperl -*-

do './svg_graph.pl';

open SVG, ">", "example_1.svg";
print SVG svg(linegraph( title    => "Sample Line Graph",
                         subtitle => 'https://github.com/tsadok/svg_graph.git',
                         xlabels  => [ qw(Monday Tuesday Wednesday Thursday Friday Saturday) ],
                         data     => [ +{ name   => "Red",
                                          color  => "#ee0000",
                                          values => [17135, 22356, 27819, 24310, 25714 ],
                                        },
                                       +{ name   => "Blue",
                                          color  => '#4499ff',
                                          values => [13819, 16124, 22684, 25319, 28174 ],
                                        },
                                       +{ name   => 'Green',
                                          color  => '#00aa00',
                                          values => [20316, 22654, 21819, 23124, 22188 ],
                                        },
                                     ],
                       ));
