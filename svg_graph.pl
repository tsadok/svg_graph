#!/usr/bin/perl
# -*- cperl -*-

use HTML::Entities;
use Math::Tau; # Needed for pie charts.
my $eltnum = "00001"; # This exists to be incremented for each element to ensure unique id attributes.

sub linegraph {
  my %arg = @_;
  my @elt;
  push @elt, backdrop(%arg);
  my ($max, $hcnt) = (0,0); {
    for my $d (@{$arg{data}}) {
      my @val = @{$$d{values}};
      $hcnt = scalar @val if $hcnt < scalar @val;
      for my $v (@val) {
        $max = $v if $max < $v;
      }}
    # We want to round the max up a bit, so none of the lines quite
    # hit the top of the chart, and so the scale looks reasonable.
    $max = int($max + 1.99999);
    while ($max % 5)   { $max++; print "."; }
    if ($max > 15 )    { while ($max % 25)     { $max += 5;      }}
    if ($max > 70 )    { while ($max % 100)    { $max += 25;     }}
    if ($max > 250 )   { while ($max % 500)    { $max += 100;    }}
    if ($max > 2500)   { while ($max % 5000)   { $max += 500;    }}
    if ($max > 25000)  { while ($max % 50000)  { $max += 5000;   }}
    if ($max > 250000) { while ($max % 500000) { $max += 50000;  }}
    # TODO: support logarithmic scale.
  }
  push @elt, $_ for legend('line', %arg);
  # Now the grid:
  if (not $arg{hidegrid}) {
    my $v = 0;
    while ($v < $max) {
      my $y = 700 - ($v / $max * 600);
      push @elt, line(color  => (($v == 0) ? '#000000' : '#666666'),
                      width  => (($v == 0) ? 2 : 1),
                      points => [[100, $y], [825, $y]]);
      my $label = ($max > 5000000) ? (int($v / 1000000) . " M") :
        ($max > 5000) ? (int($v / 1000) . " k") : $v;
      push @elt, text(text  => $label,
                      size  => 10,
                      align => 'right',
                      x     => 95,
                      y     => 2 + $y,
                     );
      $v += ($max > 7000000) ? 1000000 : ($max > 2500000) ? 500000 : ($max > 800000) ? 250000 :
        ($max > 450000) ? 100000 : ($max > 250000) ? 50000 : ($max > 80000) ? 25000 :
        ($max > 35000) ? 10000 : ($max > 19000) ? 5000 : ($max > 8000) ? 2500 :
        ($max > 3000) ? 1000 : ($max > 700) ? 250 : ($max > 300) ? 100 :
        ($max > 70) ? 25 : ($max > 30) ? 10 : ($max > 15) ? 5 : 1;
    }
    $v = 0;
    while ($v <= $hcnt) {
      my $x = 100 + ($v / ($hcnt - 1) * 725);
      my $top = ($arg{hideverticals} and ($v > 0)) ? 685 :
        $arg{subtitle} ? 160 : $arg{title} ? 135 : 100;
      push @elt, line( color  => (($v == 0) ? '#000000' : '#666666'),
                       width  => (($v == 0) ? 2 : 1),
                       points => [[$x, $top], [$x, 705]]);
      push @elt, text( text  => (($arg{xlabels} and ($v <= scalar @{$arg{xlabels}})) ? $arg{xlabels}[$v] : $v),
                       size  => 10,
                       align => 'center',
                       x     => $x,
                       y     => 715,);
      $v += ($hcnt > 1000) ? 250 : ($hcnt > 500) ? 100 : ($hcnt > 150) ? 25 :
        ($hcnt > 45) ? 10 : ($hcnt > 18) ? 5 : 1;
    }
  }
  # Now the actual lines:
  for my $d (@{$arg{data}}) {
    my $n = 0;
    my @point = map {
      my $y = 700 - ($_ / $max * 600);
      my $x = 100 + ($n / ($hcnt - 1) * 725);
      $n++;
      [$x, $y]
    } @{$$d{values}};
    push @elt, line( color  => $$d{color},
                     width  => 5,
                     points => \@point );
  }
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

sub legend {
  my ($legendtype, %arg) = @_;
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
    my $lheight = 10 + (35 * (scalar @{$arg{data}}));
    push @elt, rect( width       => 100,
                     height      => $lheight,
                     x           => 850,
                     y           => (350 - $lheight / 2),
                     opacity     => $arg{legendopacity} || 0.75,
                     fillcolor   => ($arg{legendbackground} || '#eeeeee'),
                     borderwidth => $arg{legendborderwidth} || 3,
                   );
    for my $d (@{$arg{data}}) {
      my $y = (350 - $lheight / 2) + 30 * $$d{__LEGEND_POS__};
      if ($legendtype eq 'line') {
        push @elt, line( color     => $$d{color},
                         width     => 3,
                         points    => [[855, $y], [865, $y]],);
      } else {
        push @elt, rect( fillcolor   => $$d{color},
                         borderwidth => 1,
                         x           => 857,
                         y           => $y - 4,
                         width       => 8,
                         height      => 8,
                       );
      }
      push @elt, text( x         => 870,
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
  my $largeflag  = (($arg{start} > $arg{end}) or (($arg{end} - $arg{start}) > (tau / 2))) ? 1 : 0;
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
  $arg{color}   ||= '#7f7f7f';
  $arg{width}   ||= 1;
  $arg{opacity} ||= 1;
  return qq[<path
       style="fill:none;stroke:$arg{color};stroke-width:$arg{width};stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:$arg{opacity};stroke-miterlimit:4;stroke-dasharray:none"
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
  $arg{borderwidth}   ||= '5';
  $arg{fillcolor}     ||= '#FF0000';
  $arg{opacity}       ||= '1.0';
  $arg{borderopacity} ||= $arg{opacity};
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
