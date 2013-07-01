package PerlMongers::Bangalore::Yoda;

use 5.010;
use strict;
use warnings;

use PerlMongers::Bangalore::Yoda::Rules;
use Log::Log4perl qw(get_logger :nowarn);
use POE qw(Component::IRC);
use IRC::Utils qw(BLUE GREEN RED TEAL NORMAL);
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
            _start      => \&_bot_start,
            irc_001     => \&_on_connect,
            irc_public  => \&_on_public,
            irc_msg     => \&_on_private,
            irc_join    => \&_on_join,
            irc_quit    => \&_on_quit,
            irc_part    => \&_on_quit,
            irc_kick    => \&_on_quit,
        },
    );
    POE::Kernel->run;
    $logger->warn("Yoda exited main loop terminating bot");
    return;
}

# The bot session has started.  Register this bot with the "magnet"
# IRC component.  Select a nickname.  Connect to a server.
sub _bot_start {
    $irc->yield(register => "all");
    my $nick = 'Yoda';
    $irc->yield(
        connect => {
            Nick     => $nick,
            Username => 'masteryoda',
            Ircname  => 'Yoda bot by Shantanu Bhadoria<shantanu@cpan.org>',
            #Server   => 'irc.perl.org',
            Server   => '127.0.0.1',
            Port     => '6667',
        }
    );
}

# The bot has successfully connected to a server.  Join a channel.
sub _on_connect {
    $irc->yield(join => "#bangalore.pm");
}

# The bot has received a public message.  Parse it for commands, and
# respond to interesting things.
sub _on_public {
    my ($heap, $kernel, $who, $where, $msg) = @_[HEAP, KERNEL, ARG0, ARG1, ARG2];
    my $logger  = get_logger();
    my $nick    = (split /!/, $who)[0];
    my $channel = $where->[0];
    my $ts      = scalar localtime;
    $logger->info(" <$nick:$channel> $msg");

    # Send a response back to the server if applicable.

    if($msg =~ /^yoda,/ && $nick ne 'Yoda'){
        my $answer = PerlMongers::Bangalore::Yoda::Rules->process_msg({
            type => "public",
            heap => $heap, 
            nick => $nick, 
            channel => $channel,
            msg => $msg, 
        });
        for my $answer_line( split (/\n/,$answer)) {
            $irc->yield(privmsg => "$channel", $answer_line);
        }
    }

}

# The bot has received a private message. Respond with yodaspeak 
sub _on_private {
    my ($heap, $kernel, $who, $where, $msg) = @_[HEAP, KERNEL, ARG0, ARG1, ARG2];
    my $logger  = get_logger();
    my $nick    = (split /!/, $who)[0];
    $heap->{last_loggedin_times}{$nick} = time;
    my $channel = $where->[0];
    my $ts      = scalar localtime;
    $logger->info(" <$nick:$channel> $msg");

    if($nick ne 'Yoda'){
        my $answer = PerlMongers::Bangalore::Yoda::Rules->process_msg({
            type => "private",
            heap => $heap, 
            nick => $nick, 
            channel => $channel,
            msg => $msg, 
        });
        for my $answer_line( split (/\n/,$answer)) {
            $irc->yield(privmsg => "$nick", $answer_line);
        }
    }
}

# Someone joined the channel. 
sub _on_join {
    my ($heap, $kernel, $who, $where, $msg) = @_[HEAP,KERNEL, ARG0, ARG1, ARG2];
    my $logger               = get_logger();
    my $nick                 = (split /!/, $who)[0];
    my $channel              = $where;
    my $ts                   = scalar localtime;
    if( 
        $nick ne 'Yoda'
        && (time - $heap->{last_loggedin_times}->{$nick}) > 1200 # make sure that the last time nick left channel was more than 20 minutes ago
    ) {
        $logger->info(" <$nick:$channel> Joined");
        if ($channel eq "#bangalore.pm") {
            $irc->yield(privmsg => "$channel", 
                GREEN . "Hello, " . NORMAL . $nick . GREEN . "! Welcome to Bangalore.pm. I am Yoda. I am just a bot (a perl program)." 
                . " There are humans around too, but you will have to be patient before they notice you. Please introduce yourself. " 
                . BLUE . "For more help type \"" . RED . "yoda, guide me" . BLUE . "\". As a courtsey to others you might want to talk to me in private");
        }
    } else {
        $logger->trace("Joined back too soon. No greeting for you");
    }
}

# Someone left the channel. 
sub _on_quit {
    my ($heap, $kernel, $who, $where, $msg) = @_[HEAP, KERNEL, ARG0, ARG1, ARG2];
    my $logger  = get_logger();
    my $nick    = (split /!/, $who)[0];
    my $channel = $where;
    
    $heap->{logged_hour}->{$nick} = time;  
    
    $logger->info(" <$nick:$channel> Left");
    if ($channel eq "#bangalore.pm") {
        $irc->yield(privmsg => "$channel", GREEN . "Goodbye " . NORMAL . $nick . GREEN . ", may the force be with you");
    }
}

1;
