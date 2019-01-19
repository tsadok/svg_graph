#!/usr/bin/perl
# -*- cperl -*-

use strict;
use HTML::Entities;
use Math::Tau; # Needed for pie charts.
my $eltnum = "00001"; # This exists to be incremented for each element to ensure unique id attributes.

sub areagraph {
  my %arg = @_;
  my (@elt, @area);
  push @elt, backdrop(%arg);
  my ($max, $hcnt, $totals) = get_maxima($arg{data}, stacked => 'yes', %arg);
  push @elt, $_ for legend('rect', %arg);
  push @elt, $_ for grid($max, $hcnt, $arg{data}, %arg);
  my @runningtotal;
  for my $d (@{$arg{data}}) {
    my $n = 0;
    my @point = map {
      $runningtotal[$n] += $_;
      my $x = 100 + ($n / ($hcnt - 1) * (825 - ($arg{legendwidth} || 100)));
      my $y = 700 - ($runningtotal[$n] / ($arg{aspercent} ? ($$totals[$n] * 124 / 100) : $max) * 600);
      $n++;
      [$x, $y]
    } @{$$d{values}};
    unshift @area, line( color   => $$d{color},
                         width   => 5,
                         fill    => ($$d{fillcolor} || $$d{color}),
                         points  => [ [100, 700], @point, [(925 - ($arg{legendwidth} || 100)), 700] ] );
  }
  push @elt, $_ for @area;
  push @elt, title(%arg);
  push @elt, subtitle(%arg);
  return @elt;
}

sub linegraph {
  my %arg = @_;
  my @elt;
  push @elt, backdrop(%arg);
  my ($max, $hcnt) = get_maxima($arg{data}, %arg);
  warn "Very low hcnt: $hcnt" if $hcnt < 2;
  push @elt, $_ for legend('line', %arg);
  push @elt, $_ for grid($max, $hcnt, $arg{data}, %arg);
  # Now the actual lines:
  for my $d (@{$arg{data}}) {
    my $n = 0;
    $d  ||= 0;
    my @point = map {
      my $y = 700 - ($_ / $max * 600);
      my $x = 100 + ($n / ($hcnt - 1) * (825 - ($arg{legendwidth} || 100)));
      $n++;
      [$x, $y]
    } @{$$d{values}};
    push @elt, line( color  => $$d{color},
                     width  => 5,
                     points => \@point );
  }
  # And finally do the title(s), if applicable:
  push @elt, title(%arg);
  push @elt, subtitle(%arg);
  return @elt;
}

sub bargraph {
  my %arg = @_;
  $arg{barborderopacity} = 1 if not defined $arg{barborderopacity}; # Allow explicit 0 but default to 1.
  $arg{baropacity}       = 1 if not defined $arg{baropacity};       # Ditto.
  # But note that barborderwidth defaults to 0, making the opacities irrelevant by default.
  # With this setup, calling code can just specify barborderwidth and get visible borders.
  my @elt;
  my ($max, $hcnt) = get_maxima($arg{data}, %arg);
  my $maxbars  = @{$arg{data}};
  my $hwidth   = (825 - ($arg{legendwidth} || 100)) / $hcnt;
  my $barspace = $hwidth / ($maxbars + 1);
  my $padding  = $barspace / 2;
  my $barpad   = $arg{barpadding} || 0;
  my $barwidth = $barspace - (2 * $barpad);
  # Draw the preliminaries:
  push @elt, backdrop(%arg);
  push @elt, $_ for legend('rect', %arg);
  push @elt, $_ for grid($max, $hcnt, $arg{data},
                         hideverticals => 'hide',
                         graphtype     => 'bargraph',
                         xlabelpadding =>  $barspace * 2,
                         %arg);
  # Now draw the bars:
  if ($barwidth <= 0) { warn "Bar padding is too large ($barpad), discarding it.";
                        $barpad = 0; $barwidth = $barspace; }
  my $barnum = 0;
  for my $d (@{$arg{data}}) {
    my $hnum = 0;
    for my $v (@{$$d{values}}) {
      my $hpos   = 100 + $hwidth * $hnum;
      my $barpos = $hpos + $padding + ($barspace * $barnum);
      my $height = $v / $max * 600;
      push @elt, rect( fillcolor     => $$d{color},
                       x             => $barpos + $barpad,
                       width         => $barwidth,
                       y             => 700 - $height,
                       height        => $height,
                       borderwidth   => $arg{barborderwidth} || 0,
                       borderopacity => $arg{barborderopacity},
                       bordercolor   => $$d{bordercolor} || $arg{bordercolor} || '#000000',
                       opacity       => (defined $$d{opacity}) ? $$d{opacity} : $arg{baropacity},
                     );
      $hnum++;
    }
    $barnum++;
  }
  # And finally do the title(s), if applicable:
  push @elt, title(%arg);
  push @elt, subtitle(%arg);
  return @elt;
}

sub piechart {
  my %arg = @_;
  my @elt;
  push @elt, backdrop(%arg);
  push @elt, legend('rect', %arg);
  if ($arg{bordercolor}) {
    my $opacity = (defined $arg{borderopacity}) ? $arg{borderopacity} : 1;
    my $radius  = 275 + ($arg{borderwidth} || 7);
    push @elt, circle( fillopacity => $opacity,
                       fillcolor   => $arg{bordercolor},
                       stroke      => 'none',
                       x           => 425,
                       y           => 435,
                       radius      => $radius, );
  }
  my $total = 0; for my $d (@{$arg{data}}) {
    $total += $$d{value};
  }
  push @elt, qq[<!-- total value of pie is $total -->];
  my $theta = $arg{startangle} || 0;
  for my $d (@{$arg{data}}) {
    my $deltatheta = 360 * $$d{value} / $total;
    push @elt, pieslice($d, $theta % 360, ($theta + $deltatheta) % 360);
    $theta += $deltatheta;
  }
  push @elt, title(%arg);
  push @elt, subtitle(%arg);
  return @elt;
}

sub get_stacked_maxima {
  # Calculate the vertical and horizontal maxima and totals at each point,
  # for the data set for a "stacked" graph (stacked bar, area, etc.).
  my ($data, %arg) = @_;
  my ($vmax, $hmax, @total) = (0,0);
  for my $d (@$data) {
    my @val = @{$$d{values}};
    $hmax = scalar @val if $hmax < scalar @val;
  }
  for my $n (0 .. ($hmax - 1)) {
    for my $d (@$data) {
      $total[$n] += $$d{values}[$n];
    }
    $vmax = $total[$n] if $vmax < $total[$n];
  }
  $vmax = padmaximum($vmax, %arg);
  return ($vmax, $hmax, \@total);
}

sub get_maxima {
  # Calculate the vertical and horizontal maxima for a data set.
  my ($data, %arg) = @_;
  if ($arg{stacked}) { return get_stacked_maxima($data, %arg); }
  my ($vmax, $hmax) = (0,0);
  for my $d (@$data) {
    my @val = @{$$d{values}};
    $hmax = scalar @val if $hmax < scalar @val;
    for my $v (@val) {
      $vmax = $v if $vmax < $v;
    }}
  $vmax = padmaximum($vmax, %arg);
  # TODO: support logarithmic scale.
  return ($vmax, $hmax);
}

sub padmaximum {
  my ($max, %arg) = @_;
  # We want to round the max up a bit, so none of the elements (lines,
  # bars, whatever) quite hit the top of the chart, and so the scale
  # looks reasonable.
  return $max + $arg{padmaximum} if defined $arg{padmaximum};
  $max = int($max + 1.99999);
  while ($max % 5)   { $max++; }
  if ($max > 15 )    { while ($max % 25)     { $max += 5;      }}
  if ($max > 70 )    { while ($max % 100)    { $max += 25;     }}
  if ($max > 250 )   { while ($max % 500)    { $max += 100;    }}
  if ($max > 2500)   { while ($max % 5000)   { $max += 500;    }}
  if ($max > 25000)  { while ($max % 50000)  { $max += 5000;   }}
  if ($max > 250000) { while ($max % 500000) { $max += 50000;  }}
  return $max;
}

sub grid {
  my ($vmax, $hmax, $data, %arg) = @_;
  my @elt;
  $arg{graphtype} ||= 'linegraph'; # The default grid type.  Should also work for area graphs.
  push @elt, qq[<!--  *** *** ***  S T A R T   G R I D  *** *** ***  -->];
  my $v = 0;
  $vmax = 124 if $arg{aspercent};
  while ($v < $vmax) {
    my $y = 700 - ($v / $vmax * 600);
    push @elt, line(color  => (($v == 0) ? '#000000' : '#666666'),
                    width  => (($v == 0) ? 2 : 1),
                    points => [[95, $y], [925 - ($arg{legendwidth} || 100), $y]])
      if not $arg{hidegrid};
    # And the labels:
    my $label = $arg{aspercent} ? ($v . '%') :
      ($vmax > 5000000) ? (int($v / 1000000) . " M") :
      ($vmax > 5000) ? (int($v / 1000) . " k") : $v;
    push @elt, text(text  => $label,
                    size  => 10,
                    align => 'right',
                    x     => 90,
                    y     => 2 + $y,
                   );
    $v += ($vmax > 7000000) ? 1000000 : ($vmax > 2500000) ? 500000 : ($vmax > 800000) ? 250000 :
      ($vmax > 450000) ? 100000 : ($vmax > 250000) ? 50000 : ($vmax > 80000) ? 25000 :
      ($vmax > 35000) ? 10000 : ($vmax > 19000) ? 5000 : ($vmax > 8000) ? 2500 :
      ($vmax > 3000) ? 1000 : ($vmax > 700) ? 250 : ($vmax > 300) ? 100 :
      ($vmax > 70) ? 25 : ($vmax > 30) ? 10 : ($vmax > 15) ? 5 : 1;
  }
  push @elt, qq[<!--  *** *** ***  *** VERTICAL ***  *** *** ***  -->];
  # Vertical grid lines:
  $v = 0;
  while ($v < $hmax) {
    my $x = 100 + ($arg{xlabelpadding} || 0) + ($v / ($hmax - (($arg{graphtype} eq 'bargraph') ? 0 : 1)) * (825 - ($arg{legendwidth} || 100)));
    my $top = ($arg{hideverticals} and ($v > 0)) ? 685 :
      $arg{aspercent} ? 216 :
      $arg{subtitle} ? 160 : $arg{title} ? 135 : 100;
    push @elt, line( color  => (($v == 0) ? '#000000' : '#666666'),
                     width  => (($v == 0) ? 2 : 1),
                     points => [[$x, $top], [$x, 705]])
      unless (($arg{hidegrid}) or
              (($arg{hideverticals} || 'show') eq 'hide')); # 'partial' or 'stub' gives you just the stub.
    # And the labels:
    push @elt, text( text  => (($arg{xlabels} and ($v <= scalar @{$arg{xlabels}})) ? $arg{xlabels}[$v] : $v),
                     size  => 10,
                     align => 'center',
                     x     => $x, # TODO: this is correct for linegraph, wrong for bargraph, fix it.
                     y     => 715,);
    $v += ($hmax > 1000) ? 250 : ($hmax > 500) ? 100 : ($hmax > 150) ? 25 :
      ($hmax > 45) ? 10 : ($hmax > 18) ? 5 : 1;
  }
  push @elt, qq[<!--  *** *** ***    E N D   G R I D    *** *** ***  -->];
  return @elt;
}

sub legend {
  my ($legendtype, %arg) = @_;
  $arg{legendwidth}      ||= 100;
  $arg{legenditemheight} ||= 30;
  my @elt = (qq[<!-- *** *** *** ***  L E G E N D  *** *** *** *** -->\n]);
  # Make sure all the data series have names, colors, legend positions:
  my @defaultcolor = default_colors();
  my $dnum = 0;
  for my $d (@{$arg{data}}) {
    $dnum++;
    if (not $$d{color}) { $$d{color} = shift @defaultcolor; }
    if (not $$d{name})  { $$d{name}  = "Series " . $dnum;   }
    $$d{__LEGEND_POS__} = $dnum;
  }
  if ($arg{hidelegend}) {
    return (qq[<!-- no legend -->]);
  } else {
    my $lheight = 15 + ($arg{legenditemheight} * (scalar @{$arg{data}}));
    push @elt, rect( width       => $arg{legendwidth},
                     height      => $lheight,
                     x           => (950 - $arg{legendwidth}),
                     y           => (365 - $lheight / 2),
                     opacity     => $arg{legendopacity} || 0.75,
                     fillcolor   => ($arg{legendbackground} || '#eeeeee'),
                     borderwidth => (defined $arg{legendborderwidth}) ? $arg{legendborderwidth} : 3,
                   );
    for my $d (@{$arg{data}}) {
      my $y = (365 - $lheight / 2) + $arg{legenditemheight} * $$d{__LEGEND_POS__};
      if ($legendtype eq 'line') {
        push @elt, line( color     => $$d{color},
                         width     => 3,
                         points    => [[955 - $arg{legendwidth}, $y], [965 - $arg{legendwidth}, $y]],);
      } else {
        push @elt, rect( fillcolor   => $$d{color},
                         borderwidth => 1,
                         x           => 957 - $arg{legendwidth},
                         y           => $y - 4,
                         width       => 8,
                         height      => 8,
                       );
      }
      push @elt, text( x         => 970 - $arg{legendwidth},
                       y         => $y + 4,
                       text      => $$d{name});
    }
  }
  push @elt, qq[<!-- *** *** ***  E N D   L E G E N D  *** *** *** -->\n];
  return @elt;
}

sub subtitle {
  my %arg = @_;
  return $arg{subtitle} ? text(text   => $arg{subtitle},
                               align  => 'center',
                               font   => 'Georgia',
                               size   => 31,
                               x      => 495,
                               y      => 145,)
    : qq[<!-- no subtitle -->\n];
}

sub title {
  my %arg = @_;
  return $arg{title} ? text(text  => $arg{title},
                            align => 'center',
                            font  => 'Georgia',
                            size  => 78,
                            x     => 494,
                            y     => 100)
    : "<!-- no title -->\n";
}

sub text {
  my %arg = @_;
  my $num = $eltnum++;
  $arg{size}    ||= 12;
  $arg{style}   ||= 'normal';
  $arg{weight}  ||= 'normal';
  $arg{align}   ||= 'left';
  $arg{anchor}  ||= ($arg{align} eq 'center') ? 'middle' :
                    ($arg{align} eq 'left') ? 'start' : 'end';
  $arg{color}   ||= '#000000';
  $arg{opacity} ||= 1;
  $arg{font}    ||= 'Bitstream Vera Sans Mono';
  return qq[<text
       xml:space="preserve"
       style="font-size:$arg{size}px;font-style:$arg{style};font-variant:normal;font-weight:$arg{weight};font-stretch:normal;text-align:$arg{align};line-height:100%;writing-mode:lr-tb;text-anchor:$arg{anchor};fill:$arg{color};fill-opacity:$arg{opacity};stroke:none;font-family:$arg{font};-inkscape-font-specification:$arg{font}"
       x="$arg{x}"
       y="$arg{y}"
       id="text$num"
       sodipodi:linespacing="100%"><tspan
         sodipodi:role="line"
         id="tspan3594-3"
         x="$arg{x}"
         y="$arg{y}">] . encode_entities($arg{text}) . qq[</tspan></text>];
}

sub pieslice {
  my ($d, $startangle, $endangle) = @_;
  # Note that pieslice takes startangle and endangle in degrees.
  # We convert them here to radians.
  return "<!-- pieslice for $$d{name}, value $$d{value}, color $$d{color}, from $startangle to $endangle -->",
    arc( stroke      => 'none',
         fillopacity => 1,
         fillcolor   => $$d{color},
         x           => 425,
         y           => 435,
         radius      => 275,
         start       => $startangle * tau / 360,
         end         => $endangle   * tau / 360,
       );
}

sub circle {
  return arc(start => 0, end => tau, @_);
}

sub arc {
  my %arg = @_;
  $arg{color}       ||= '#000000';
  $arg{fillcolor}   ||= '#7f7f7f';
  $arg{fillopacity} ||= 0;
  $arg{stroke}      ||= $arg{color};
  $arg{width}       ||= 1;
  $arg{radius}      ||= 50;
  $arg{xradius}     ||= $arg{radius};
  $arg{yradius}     ||= $arg{radius};
  $arg{start}         = 0 if not defined $arg{start};
  $arg{end}           = tau if not defined $arg{end};
  $arg{x}             = 100 if not defined $arg{x};
  $arg{y}             = 100 if not defined $arg{y};
  my $num = $eltnum++;
  # TODO: support xradius/yradius here:
  my ($xstart,$ystart) = polar_to_rectangular($arg{start}, $arg{radius});
  my ($xend,$yend)     = polar_to_rectangular($arg{end}, $arg{radius});
  $xstart += $arg{x}; $xend += $arg{x};
  # Y coords are inverted (because they start at the top of the screen in SVG):
  $ystart = $arg{y} - $ystart; $yend = $arg{y} - $yend;
  my $largeflag  = ((($arg{start} > $arg{end}) and ($arg{end} != 0)) or (($arg{end} - $arg{start}) > (tau / 2))) ? 1 : 0;
  my $epsilon    = $arg{epsilon} || 0.0000001;
  my $fullcircle = ((abs($arg{start}) > $epsilon) or
                    (abs($arg{end} - tau) > $epsilon)) ? 0 : 1;
  my $sweepflag = $fullcircle ? 1 : 0;
  my $arcto = qq[A $arg{xradius},$arg{yradius} 0 $largeflag $sweepflag ];
  my $path = qq[m $xstart,$ystart $arcto]
    . ($fullcircle # Use four easily-calculated points to define a complete circle:
       ? (qq[ $arg{x},] . ($arg{y} - $arg{yradius}) . $arcto . ($arg{x} - $arg{xradius}) . qq[,$arg{y} ]
          . qq[$arcto $arg{x},] . ($arg{y} + $arg{yradius}) . qq[ $arcto $xstart,$ystart])
       : qq[ $xend,$yend L $arg{x},$arg{y}]) . ' z';
  return qq[<path
       sodipodi:type="arc"
       style="color:$arg{color};fill:$arg{fillcolor};fill-opacity:$arg{fillopacity};fill-rule:nonzero;stroke:$arg{stroke};stroke-width:$arg{width};marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate"
       id="path$num"
       sodipodi:cx="$arg{x}"
       sodipodi:cy="$arg{y}"
       sodipodi:rx="$arg{xradius}"
       sodipodi:ry="$arg{yradius}"
       d="$path"
       sodipodi:start="$arg{start}"
       sodipodi:end="$arg{end}" />];
}

sub polar_to_rectangular {
  my ($theta, $radius) = @_;
  my $x = $radius * cos($theta);
  my $y = $radius * sin($theta);
  return ($x, $y);
}

sub line {
  my %arg = @_;
  my $num = $eltnum++;
  $arg{color}       ||= '#7f7f7f';
  $arg{width}       ||= 1;
  $arg{opacity}     ||= 1;
  $arg{fill}        ||= 'none';
  $arg{fillopacity} ||= $arg{opacity};
  return qq[<path
       style="fill:$arg{fill};stroke:$arg{color};stroke-width:$arg{width};stroke-linecap:butt;stroke-linejoin:miter;fill-opacity:$arg{fillopacity};stroke-opacity:$arg{opacity};stroke-miterlimit:4;stroke-dasharray:none"
       d="M ] . (join " ", map { $$_[0] . "," . $$_[1] } @{$arg{points}}) . qq["
       id="path$num" />]
}

sub backdrop {
  my %arg = @_;
  my $bdnum = $eltnum++;
  return rect( x           => 12.5,
               y           => 12.5,
               width       => 965,
               height      => 725,
               fillcolor   => ($arg{backgroundcolor} || "#dfdfdf"),
               opacity     => '0.5',
               borderwidth => 2, );
}

sub rect {
  my %arg = @_;
  my $num = $eltnum++;
  $arg{bordercolor}   ||= '#000000';
  $arg{fillcolor}     ||= '#FF0000';
  $arg{borderwidth}     = '5' if not defined $arg{borderwidth};             # Allow explicit 0
  $arg{opacity}         = '1.0' if not defined $arg{opacity};               # Ditto
  $arg{borderopacity}   = $arg{opacity} if not defined $arg{borderopacity}; # Ditto
  die "No x coordinate for rect()" if not $arg{x};
  die "No y coordinate for rect()" if not $arg{y};
  $arg{width}         ||= 50;
  $arg{height}        ||= 50;
  return qq[<rect
       style="color:$arg{bordercolor};fill:$arg{fillcolor};fill-opacity:$arg{opacity};fill-rule:nonzero;stroke:#000000;stroke-width:$arg{borderwidth};marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate;stroke-opacity:$arg{borderopacity};stroke-miterlimit:4;stroke-dasharray:none"
       id="rect$num"
       width="$arg{width}"
       height="$arg{height}"
       x="$arg{x}"
       y="$arg{y}" />];
}

sub svg {
  my (@elt) = @_;
  return qq{<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!-- Created by svg_graph.pl -->

<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"

   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   width="990"
   height="765"
   id="svg2"
   version="1.1"
   inkscape:version="0.47 r22583"
   sodipodi:docname="New document 1">
  <defs
     id="defs4">
    <inkscape:perspective
       sodipodi:type="inkscape:persp3d"
       inkscape:vp_x="0 : 526.18109 : 1"
       inkscape:vp_y="0 : 1000 : 0"
       inkscape:vp_z="744.09448 : 526.18109 : 1"
       inkscape:persp3d-origin="372.04724 : 350.78739 : 1"
       id="perspective10" />
    <inkscape:perspective
       id="perspective3604"
       inkscape:persp3d-origin="0.5 : 0.33333333 : 1"
       inkscape:vp_z="1 : 0.5 : 1"
       inkscape:vp_y="0 : 1000 : 0"
       inkscape:vp_x="0 : 0.5 : 1"
       sodipodi:type="inkscape:persp3d" />
  </defs>
  <sodipodi:namedview
     id="base"
     pagecolor="#ffffff"
     bordercolor="#666666"
     borderopacity="1.0"
     inkscape:pageopacity="0.0"
     inkscape:pageshadow="2"
     inkscape:zoom="0.69989734"
     inkscape:cx="505.08813"
     inkscape:cy="357.57471"
     inkscape:document-units="px"
     inkscape:current-layer="layer1"
     showgrid="false"
     inkscape:window-width="1191"
     inkscape:window-height="946"
     inkscape:window-x="47"
     inkscape:window-y="8"
     inkscape:window-maximized="0" />
  <g
     inkscape:label="Layer 1"
     inkscape:groupmode="layer"
     id="layer1">
  } . (join "\n  ", @elt) . qq{
  </g>
</svg>};
}

sub default_colors {
  return
    '#cc0000', '#00aa00', '#000099', '#eeee00', '#bb00bb', '#0099cc', '#888888',
    '#7e1e9c', '#ff81c0', '#653700', '#95d0fc', '#f97306', '#029386', '#96f97b',
    '#c20078', '#929591', '#bf77f6', '#89fe05', '#033500', '#9a0eea', '#13eac9',
    '#ae7181', '#650021', '#6e750e', '#ff796c', '#e6daa6', '#0504aa', '#cea2fd',
    '#ff028d', '#ad8150', '#c7fdb5', '#ffb07c', '#677a04', '#cb416b', '#8e82fe',
    '#53fca1', '#380282', '#ceb301', '#ffd1df', '#000000', '#555555',
}

42;
