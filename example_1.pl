#!/usr/bin/perl
# -*- cperl -*-

do './svg_graph.pl';

open SVG, ">", "example_1.svg";
print SVG svg(linegraph( title    => "Sample Line Graph",
                         subtitle => 'http://www.github.com/tsadok/svg_graph.git',
                         data     => [ +{ name   => "Red",
                                          color  => "#ee0000",
                                          values => [17, 22, 27, 24, 25 ],
                                        },
                                       +{ name   => "Blue",
                                          color  => '#4499ff',
                                          values => [13, 16, 22, 25, 28 ],
                                        },
                                       +{ name   => 'Green',
                                          color  => '#00aa00',
                                          values => [20, 22, 21, 23, 22 ],
                                        },
                                     ],
                       ));
