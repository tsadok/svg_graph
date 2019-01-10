#!/usr/bin/perl
# -*- cperl -*-

do './svg_graph.pl';

open SVG, ">", "example_2.svg";
print SVG svg(piechart( title       => "Sample Pie Chart",
                        subtitle    => 'https://github.com/tsadok/svg_graph.git',
                        bordercolor => '#444444',
                        startangle  => 90, # Start at top, like OpenOffice Calc does.
                        data        => [ +{ name   => "Weeks",
                                            value  => 180,
                                          },
                                         +{ name   => "Months",
                                            value  => 42,
                                          },
                                         +{ name   => 'Days',
                                            value  => 1260,
                                          },
                                       ],
                      ));
