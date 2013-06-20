package PerlMongers::Bangalore::Yoda;

use 5.010;
use strict;
use warnings;

use Log::Log4perl qw(get_logger :nowarn);
use POE qw(Component::IRC);
use IRC::Utils qw(GREEN BLUE RED NORMAL);
use Acme::Yoda;

=head1 NAME

PerlMongers::Bangalore::Yoda - The Yoda Bot for the Bangalore.pm IRC Channel.

=cut

sub CHANNEL () { "#poe" }

# Create the component that will represent an IRC network.
my ($irc) = POE::Component::IRC->spawn();

sub run {
    my ( $class, %params ) = @_;

    my $logger = get_logger;
    Log::Log4perl::NDC->push('Yoda');
    $logger->info("Starting Yoda Bot");

    # Create the bot session. 
    my $session = POE::Session->create(
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
    POE::Kernel->run;
    $logger->warn("Yoda exited main loop terminating bot");
    return;
}

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
      #Server   => 'irc.perl.org',
      Server   => '127.0.0.1',
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
  my ($heap, $kernel, $who, $where, $msg) = @_[HEAP, KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $channel = $where->[0];
  my $ts      = scalar localtime;
  print " [$ts] <$nick:$channel> $msg\n";
  if (
      $msg =~ /yoda/i && $channel eq "#bangalore.pm" 
      && ($heap->{last_loggedin_times}->{$nick} - time) > 1200 # make sure that the last time nick left channel was more than 20 minutes ago
  ) {
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
  my ($heap, $kernel, $who, $where, $msg) = @_[HEAP, KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  $heap->{last_loggedin_times}{$nick} = time;
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
  my ($heap, $kernel, $who, $where, $msg) = @_[HEAP,KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $channel = $where;
  my $time_since_loggedout = time - $heap->{logged_hour}->{$nick};
  my $ts      = scalar localtime;
  if( $nick ne 'Yoda' && $time_since_loggedout > 1200 ){
    print " [$ts] <$nick:$channel> Joined, time since last login: $time_since_loggedout\n";
    if ($channel eq "#bangalore.pm") {
      $irc->yield(privmsg => "$channel", 
          GREEN . "Hello, " . NORMAL . $nick . GREEN . "! Welcome to Bangalore.pm. I am Yoda. I am just a bot (a perl program)." 
          . " There are humans around too, but you will have to be patient before they notice you. Please introduce yourself. " 
          . BLUE . "For more help type \"" . RED . "help me yoda" . BLUE . "\".");
    }
  } else {
      print "Joined back too soon. No greeting for you\n";
  }
}

# Someone left the channel. 
sub on_quit {
  my ($heap, $kernel, $who, $where, $msg) = @_[HEAP, KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];

  $heap->{logged_hour}->{$nick} = time;  
  my $channel = $where;
  my $ts      = scalar localtime;
  print " [$ts] <$nick:$channel> Left\n";
  if ($channel eq "#bangalore.pm") {
    $irc->yield(privmsg => "$channel", GREEN . "Goodbye " . NORMAL . $nick . GREEN . ", may the force be with you");
  }
}

1;
