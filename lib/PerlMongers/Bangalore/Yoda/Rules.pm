package PerlMongers::Bangalore::Yoda::Rules;

use IRC::Utils qw(BLUE GREEN RED TEAL NORMAL);
use PerlMongers::Bangalore;
use Log::Log4perl qw(get_logger :nowarn);

my $rules = {
    "guide me" => {
        description => "Help information and commands",
        answer      => sub {
            my $text = "This is the help menu,"
                . "you may use the following commands to return useful information, everything " 
                . "else that you say to me in a private message will be spoken back to you in " 
                . "yodaspeak\n";
            $text .= _rules_list();
            return $text;
        },
    },
    "tell me about bangalore.pm" => {
        description => "Gives you information about Bangalore.pm",
        answer      => sub {
            my $text = RED . "Website: " . GREEN . "http://bangalore.pm.org\n";
            $text .= RED . "Meetups: " . GREEN . "http://bangalore.pm.org/meetups\n";
            $text .= RED . "Mailing List: " . GREEN . "http://mail.pm.org/mailman/listinfo/bangalore-pm\n";
            $text .= RED . "Mail Archives: " . GREEN . "http://mail.pm.org/pipermail/bangalore-pm/\n";
            return $text;
        }
    },   
    "next meetup" => {
        description => "Gives you information about next meetup of Bangalore.pm, use \"yoda,next meetup: next meetup on 20/7/2012 at koramangala legends of rock\" to set the next meetup",
        answer      => sub {
            my ($params) = @_;
            my $string = $params->{string};
            my $heap   = $params->{heap};
            my $nick   = $params->{nick};
            my $text   = $heap->{next_meetup};
            if($string){
                $heap->{next_meetup} = TEAL . $string . RED . " - set by " . BLUE . "$nick";
                $text = " Set next meetup to $string " ;
            }
            return $text;
        },
    },
};

sub _rules_list {
    my $text;
    for my $command ( keys %$rules ){
        $text .= RED . "\"yoda,$command\"" . GREEN . ": " . $rules->{$command}->{description} . "\n";
    }
    return $text;
}

sub process_msg {
    my ($class,$params) = @_;
    my @responses = (
        "I have no idea"
        , "I don't understand, I was supposed to know what that means?"
        , "That does not compute"
        , "Ummm, What??"
    );
    $logger = get_logger();
    my $msg = $params->{msg};
    if ($msg =~ /^yoda, *([^:]*?) *(: *(.*))?$/ ){
        my $cmd = $1;
        my $string = $3;
        if($rules->{lc $cmd}){
            my $answer = $rules->{lc $cmd}->{answer}->({
                    string => $string,
                    heap => $params->{heap},
                    nick => $params->{nick},
                });
            return $answer;
        }
    }
    elsif($msg =~ /^yoda/ || $params->{type} eq 'private') {
        my $response = $responses[rand @responses];
        return RED . $response;
    }
}

1;
