#!/usr/bin/perl
# -*- cperl -*-

do './svg_graph.pl';

open SVG, ">", "example_bargraph.svg";
print SVG svg(bargraph( title          => "Sample Bar Graph",
                        subtitle       => 'https://github.com/tsadok/svg_graph.git',
                        xlabels        => [ qw(Monday Tuesday Wednesday Thursday Friday Saturday) ],
                        barborderwidth => 0.75,
                        data           => [ +{ name   => "Purple",
                                               color  => "#9900bb",
                                               values => [18, 22, 27, 24, 21, 18 ],
                                             },
                                            +{ name   => "Gold",
                                               color  => '#e5b00f',
                                               values => [11, 16, 19, 25, 29, 32 ],
                                             },
                                            +{ name   => 'Slate',
                                               color  => '#3d736e',
                                               values => [20, 22, 21, 23, 21, 22 ],
                                             },
                                          ],
                      ));
