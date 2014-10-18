use warnings;
use POSIX qw( fmod );

$fs = 48000;
$pi = 3.141592653589793;
$tau = 2 * $pi;
$ampmax = 0x7fff;

$mainsfreq = 60;
$mainsamp = dBmax(-38);
$mainsclip = 0.82;

$t_global = 0;

open U, "|sox -t .raw -e sig -b 16 -c 1 -r $fs - ".
        "-e u-law -t .raw -r 8000 - sinc 450-3200 | ".
        "sox -t .raw -e u-law -t .raw -c 1 -r 8000 - ".
        "-b 16 -e sig -r $fs full.wav";

#open U, "|sox -t .raw -e sig -b 16 -c 1 -r $fs - full.wav";

ring_1(2);
exit();

onhook  ();
offline ();
silent  (2);
offhook ();
silent  (0.1);
dt_city (2);
dtmf    ("5554823");
silent  (2);
online  (1);
silent  (.2);
bluebox ("5554823");
silent  (1);
online  (2);

silent  (1);

playfile("oonaonihana.wav");

exit();

v8bis_signals();

#v8bis_fsk(1, pack("C*", 0x7e, 0x7e, 0x7e, 0x48, 0x93, 0x01, 0x01, 0x01, 0x90, 0xad, 0x40, 0x00, 0x29, 0x81, 0xc1, 0xc2, 0xe2, 0x23, 0xe4, 0x37, 0x7e, 0x7e));
v8bis_fsk(1, pack("C*", 0x7e, 0x7e, 0x7e).
 "SaveTheClocktower".
 pack("C*", 0x7e, 0x7e));
silent (0.150);

#v8bis_fsk(2, pack("C*", 0x7e, 0x3f, 0x7e, 0x7e, 0x88, 0x81, 0x01, 0x01, 0x01, 0x81, 0x2d, 0x40, 0x00, 0x29, 0x81, 0xc1, 0x00, 0xe0, 0x80, 0x7e, 0xdc, 0x7e, 0x7e, 0x7e));
v8bis_fsk(2, pack("C*", 0x7e, 0x3f, 0x7e, 0x7e).
 "RUN FOR IT MARTY!".
 pack("C*",0x7e, 0x7e, 0x7e));
v8bis_fsk(1, pack("C*", 0x7e, 0x7e, 0x28, 0xbb, 0x65, 0x7e, 0x7e));

silent (0.85);

ansam   (2.1);

v8_fsk(2, 3, "88 mph!!");
#pack("C*",0x07, 0x83, 0xa6, 0xc8, 0x09, 0xe2, 0xb0, 0x54));

v34_probe();

v34_info_dpsk(1, "88 mph!!asdiojsdoifjsdoifjdsoifjsdoifjsoidfjosdifjosidfjosidfjoisdfjoisdfjoisdjfosdijfosidjfosidjfoijklj");

close U;

sub offline { $online  = 0; }
sub online  { $online  = $_[0]; if ($online == 1) { $t_online = 0; } }
sub onhook  { $offhook = 0; }
sub offhook { $offhook = 1; }

sub dB {
  10 ** ($_[0]/20);
}

# relative to saturated amplitude
sub dBmax {
  $ampmax * dB($_[0]);
}

# relative to nominal power per regulations
sub dBnom {
  dBmax(-13) * dB($_[0]);
}

sub dt_us {
  my $dur = $_[0];
  my $t;
  for $n (0..int($dur*$fs+.5)-1) {
    $t = $n/$fs;
    sample(dBmax(-12) * mf($t, 350, 440));
  }
}

sub dt_city {
  my $dur = $_[0];
  my $t;
  for $n (0..int($dur*$fs+.5)-1) {
    $t = $n/$fs;
    sample(dBmax(-12) * tone(600, $t) * tone(120, $t));
  }
}

sub dt_eu {
  my $dur = $_[0];
  my $t;
  for $n (0..int($dur*$fs+.5)-1) {
    $t = $n/$fs;
    sample(dBmax(-12) * tone(425, $t));
  }
}

sub ring_1 {
  my $dur = $_[0];
  my $t;
  my $pwr;
  for $n (0..int($dur*$fs+.5)-1) {
    $t = $n/$fs;
    $pwr = fmod($t, 0.025) < 0.0125 ? -12 : -23.7;
    sample(dBmax($pwr) * tone(800, $t) * tone(400, $t));
  }
}

sub dtmf {

  my %tones = ( 1 => [697,1209], 2 => [697,1336], 3 => [697,1477], "A"=>[697,1633],
                4 => [770,1209], 5 => [770,1336], 6 => [770,1477], "B"=>[770,1633],
                7 => [852,1209], 8 => [852,1336], 9 => [852,1477], "C"=>[852,1633],
                "*"=>[941,1209], 0 => [941,1336], "#"=>[941,1477], "D"=>[941,1633] );

  my $tdur = 0.1;
  my $pdur = 0.1;

  my $amp = dBmax(-5.2);

  for $char (split(//,$_[0])) {
    my $ph = 0;
    my $t = 0;
    my $n;

    for $n (0..int($tdur*$fs+.5)-1) {
      $t = $n/$fs;
      sample($amp * mf($t, @{$tones{$char}}[0], @{$tones{$char}}[1]));
    }
    silent($pdur);
  }
}

sub bluebox {

  my %tones = ( 1   => [700,900],  2 => [700,1100],    3 => [900,1100],
                4   => [700,1300], 5 => [900,1300],    6 => [1100,1300],
                7   => [700,1500], 8 => [900,1500],    9 => [1100,1500],
                "KP"=>[1100,1700], 0 => [1300,1500], "ST"=> [1500,1700], );

  my $amp = dBmax(-50);

  for $char ("KP", split(//,$_[0]), "ST") {
    my $ph = 0;
    my $t = 0;
    my $n;
    $tdur = ($char eq "KP" ? 0.1 : 0.06);

    for $n (0..int($tdur*$fs+.5)-1) {
      $t = $n/$fs;
      sample($amp * mf($t, @{$tones{$char}}[0], @{$tones{$char}}[1]));
    }
    silent(0.06);
  }
}

sub v8bis_signals {
  my $t = 0;

  while (1) {

    #CRe
    if    ($t < .400)
      { sample(dBnom(-12) * mf($t, 1375, 2002)); }
    elsif ($t < .400 + .100)
      { sample(dBnom(-12) * tone(400, $t)); }

    #CRd
    elsif ($t < .400 + .100 + .400)
      { sample(dBnom(0) * mf($t, 1529, 2225)); }
    elsif ($t < .400 + .100 + .400 + .100)
      { sample(dBnom(0) * tone(1900, $t)); }

    #ESr
    elsif ($t < .400 + .100 + .400 + .100 + .100)
      { sample(dBnom(0) * tone(1650, $t)); }
    else
      { last; }
    
    $t += 1/$fs;
  }
}



sub ansam {
  my $dur = $_[0];
  my $amp = dBnom(0);

  my $f = 2100;
  my $fam = 15;
  my $ampam = 0.2;

  my $ph = 0;
  my $nextsnap = 0;
  my $t = 0;
  my $n;

  for $n (0..$dur*$fs-1) {
    $t = $n/$fs;

    if ($t >= $nextsnap) {
      $ph += $pi;
      $nextsnap += .450;
    }

    sample($amp*(tone($f, $t, $ph) * (1+$ampam * tone($fam, $t))));

  }
}

sub v8bis_fsk {
  my ($chan, $dta) = @_;

  my @bits = ();

  push(@bits,split(//,sprintf("%08b",ord($_)))) for (split(//,$dta));

  v_21($chan, 0.1, @bits);
}

sub v8_fsk {
  my ($chan, $repeats, $dta) = @_;

  my @bits = (split(//,"1111111111"));

  push(@bits,0,split(//,sprintf("%08b",ord($_))),1) for (split(//,$dta));

  v_21($chan, 0, (@bits) x $repeats);

}

sub v_21 {
  my $chan = shift;
  my $preamble = shift;
  my @bits = @_;
  my $bps = 300;
  my $t = 0;
  my $a;
  my $fN = ($chan == 1 ? 1080 : 1750);
  my $ph=0;
  my $prevf = 0;

  while ($t < 0.1 + @bits/$bps) {
    if ($t < 0.1) {
      $f = $fN - 100;
    } else {
      $t_dta = $t - 0.1;
      $f = ($bits[int($t_dta * $bps + .5)] ? $fN - 100 : $fN + 100);
      if ($f != $prevf) {
        $dph += phase($prevf, $t) - phase($f,$t);
      }
      $prevf = $f;
    }
    sample(dBnom(0) * tone($f, $t, $dph));
    $t += 1/$fs;
  }
}

sub v34_probe {
  my $t = 0;
  while ($t < .160) {
    sample(dBnom(6) * mf($t, 150,-300,450,600,750,1050,1350,1500,-1650,
        1950,2100,-2250,2700,2850,-3000,-3150,-3300,-3450,3600,3750));
    $t += 1/$fs;
  }
  while ($t < 2*.160) {
    sample(dBnom(0) * mf($t, 150,-300,450,600,750,1050,1350,1500,-1650,
        1950,2100,-2250,2700,2850,-3000,-3150,-3300,-3450,3600,3750));
    $t += 1/$fs;
  }
}

sub silent {
  for (0..int($_[0]*$fs+.5)-1) {
    sample(0);
  }
}

sub mf {
  my $t = shift;
  my @f = @_;
  my $a = 0;
  $a += tone($_, $t) for (@f);
  $a/@f;
}

sub tone {
  my ($f,$t,$ph) = @_;
  sin(2*$pi*$f*($t // $t_global) + ($ph // 0));
}

sub sample {
  my $a = $_[0] + ($online ? linenoise() : 0) + ($offhook ? mainshum() : 0);
  
  print U pack("s", int($a+.5));

  $t_global += 1/$fs;
  $t_online += 1/$fs if ($online);
}

sub mainshum {

  my $hum = tone($mainsfreq);
  $hum = ($hum > $mainsclip ? $mainsclip : $hum);
  $hum = ($hum < -$mainsclip ? -$mainsclip : $hum);

  $mainsamp * $hum;

}

sub linenoise {

  $noise = (rand()-.5);
  $noiseamp = dBmax($online == 2 ? -36 : -40);

  $noiseamp * $noise + dBmax($t_online < .1 ? -40 : -50) * dB($online == 2 ? -6 : 0) * tone(2600);

}

sub phase {
  my ($f,$t) = @_;

  2 * $pi * (($f*$t) - int($f*$t));
}

sub v34_info_dpsk {
  my $chan = shift;
  my $dta = shift;
  my @bits = ();
  push(@bits,split(//,sprintf("%08b",ord($_)))) for (split(//,$dta));
  my $bps = 600;
  my $t = 0;
  my $a;
  my $f = ($chan == 1 ? 1200 : 2400);
  my $ph=0;

  while ($t < @bits/$bps) {
    $t_dta = $t;
    $ph = ($bits[int($t_dta * $bps + .5)] ? $tau/2 : 0);
    if ($chan == 1) {
      sample(dBnom(0) * tone($f, $t, $ph));
    } else {
      sample(dBnom(-1) * tone($f, $t, $ph) + dBnom(-7) * tone(1800,$t));
    }
    $t += 1/$fs;
  }
}

sub playfile {
  my $fname = shift;
  open F, "sox $fname -t .raw -e sig -b 16 -c 1 -r $fs -|";
  while (not eof F) {
    read(F, $a, 2);
    sample(dBnom(7) * pcm2double(unpack("s",$a)));
  }
  close F;
}

sub pcm2double {
  $_[0]/ 32767.5;
}
