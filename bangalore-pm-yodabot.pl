#!/usr/bin/perl
use warnings;
use strict;
use POE;
use POE::Component::IRC;
use IRC::Utils qw(GREEN NORMAL);
use Acme::Yoda;
sub CHANNEL () { "#poe" }

# Create the component that will represent an IRC network.
my ($irc) = POE::Component::IRC->spawn();

# Create the bot session. 
POE::Session->create(
  inline_states => {
    _start     => \&bot_start,
    irc_001    => \&on_connect,
    irc_public => \&on_public,
    irc_msg    => \&on_private,
    irc_join    => \&on_join,
    irc_quit    => \&on_quit,
    irc_part    => \&on_quit,
    irc_kick    => \&on_quit,
  },
);

# The bot session has started.  Register this bot with the "magnet"
# IRC component.  Select a nickname.  Connect to a server.
sub bot_start {
  $irc->yield(register => "all");
  my $nick = 'Yoda';
  $irc->yield(
    connect => {
      Nick     => $nick,
      Username => 'masteryoda',
      Ircname  => 'Yoda bot by Shantanu Bhadoria<shantanu at cpann dott org>',
      Server   => 'irc.perl.org',
      Port     => '6667',
    }
  );
}

# The bot has successfully connected to a server.  Join a channel.
sub on_connect {
  $irc->yield(join => "#bangalore.pm");
}

# The bot has received a public message.  Parse it for commands, and
# respond to interesting things.
sub on_public {
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $channel = $where->[0];
  my $ts      = scalar localtime;
  print " [$ts] <$nick:$channel> $msg\n";
  if ($msg =~ /yoda/i && $channel eq "#bangalore.pm") {
    #Respond with Yoda Speak
    my $yodifier = Acme::Yoda->new();
    my $yodaspeak = $yodifier->yoda($msg);
    print $yodaspeak."\n";

    # Send a response back to the server.
    $irc->yield(privmsg => "$channel", $yodaspeak);
  }
}

# The bot has received a private message. Respond with yodaspeak 
sub on_private {
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $channel = $where->[0];
  my $ts      = scalar localtime;
  print " [$ts] <$nick:$channel> $msg\n";

  #Respond with Yoda Speak
  my $yodifier = Acme::Yoda->new();
  my $yodaspeak = $yodifier->yoda($msg);
  $irc->yield('privmsg' => $nick => GREEN . $yodaspeak);
}

# Someone joined the channel. 
sub on_join {
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $channel = $where;
  my $ts      = scalar localtime;
  if( $nick ne 'Yoda' ){
    print " [$ts] <$nick:$channel> Joined\n";
    if ($channel eq "#bangalore.pm") {
      $irc->yield(privmsg => "$channel", GREEN . "To this channel, welcome you are " . NORMAL . $nick);
    }
  }
}

# Someone left the channel. 
sub on_quit {
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $channel = $where;
  my $ts      = scalar localtime;
  print " [$ts] <$nick:$channel> Left\n";
  if ($channel eq "#bangalore.pm") {
    $irc->yield(privmsg => "$channel", GREEN . "Goodbye " . NORMAL . $nick . GREEN . ", may the force be with you");
  }
}

# Run the bot until it is done.
$poe_kernel->run();
exit 0;
