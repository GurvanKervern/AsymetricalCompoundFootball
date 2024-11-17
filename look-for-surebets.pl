#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Text::CSV;

my $capital = 10000;
my $bet_percentage = 5;
my $bookmaker = 'WH';
my $bets_won = 0;
my $bets_lost = 0;
my @bookmakers = qw(B365 WH VC SJ PS PSC LB IW BW);
my %best_quotes = ();
my %worst_quotes = ();
my $nb_fixtures = 0;
my $nb_surebets = 0;

my $csv = Text::CSV->new();
my @files = @ARGV;

for my $file (@files) {
    open my $fh, '<', $file or die("couldn't open $file : $!");

    process_file($fh);

    close($fh);
}

sub process_file {
    my $fh = shift;
    my @columns = $csv->column_names ($csv->getline ($fh));
    #print "@columns\n";
    while(my $row = $csv->getline_hr($fh)) {
        $nb_fixtures++;
        #print Dumper($row);
        #bet_on_fixture($row);
        get_quotes($row);
        #print "best";
        #print Dumper(\%best_quotes);
        #print "worst";
        #print Dumper(\%worst_quotes);
    }
    print "$nb_fixtures $nb_surebets\n";
}

sub get_quotes {
    my $hash_ref = shift;
    my @highest_quotes = ();
    for my $letter ('A', 'D', 'H') {
        my %outcome_quotes = ();
        my $high = 0;
        for my $bookmaker (@bookmakers) {
            my $bookmaker_quote_name = $bookmaker . $letter;
            #print "Looking for $bookmaker_quote_name\n";
            my $result = $hash_ref->{$bookmaker_quote_name};
            if($result) {
                $outcome_quotes{$bookmaker} = $result;
                if($result > $high) {
                    $high = $result;
                }
            }
        }
        #print Dumper(\%outcome_quotes);
        my @best_bookmakers = sort { $outcome_quotes{$a} <=> $outcome_quotes{$b} } keys %outcome_quotes;
        #print Dumper(\@best_bookmakers);
        my $best = $best_bookmakers[-1];
        my $worst = $best_bookmakers[0];
        $best_quotes{$best}++;
        $worst_quotes{$worst}++;
        push(@highest_quotes, $high) if ($high > 0);
    }
    my $total = 0;
    foreach my $num (@highest_quotes) {
        $total += 1 / $num;
    }
    if($total < 1) {
        print "\nSUREBET! $total\t";
        print "@highest_quotes\t";
        print $hash_ref->{'Date'} ."\t";
        print $hash_ref->{'HomeTeam'} .' ';
        print $hash_ref->{'AwayTeam'};
        $nb_surebets++;
    }
}

sub bet_on_fixture {
    my $hash_ref = shift;
    my $date = $hash_ref->{'Date'};
    my $home_team = $hash_ref->{'HomeTeam'};
    my $away_team = $hash_ref->{'AwayTeam'};
    my $favorite = who_is_favorite($hash_ref);
    if($favorite eq "C") {
        print "No data, cancelling bet";
        return;
    }
    my $bet_choice = $favorite;
    my $bet_quote = $hash_ref->{$bookmaker . $bet_choice};
    my $bet_amount = 100;
    #my $bet_amount = $capital / 100 * $bet_percentage;
    my $winner = who_won($hash_ref);
    
    if($bet_amount > $capital) {
        print "You're ruined. Nb bets : " ;
        print $bets_won + $bets_lost;
        print " Percentage won : " . $bets_won / ($bets_won + $bets_lost) * 100 ."\n";
        exit(0);
    } else {
        my $won = $bet_choice eq $winner;
        $capital -= $bet_amount;
        if($won) {
            $capital += $bet_amount * $bet_quote;
            $bets_won++;
            print "$capital     $bet_quote      $bet_choice   WON  $winner      :       $date - $home_team      -       $away_team\n"; 
        } else {
            $bets_lost++;
            print "$capital     $bet_quote      $bet_choice   LOST  $winner      :       $date - $home_team      -       $away_team\n"; 
        }
    }
}

sub who_is_favorite {
    my $hash_ref = shift;
    my %quotes = ();
    $quotes{$bookmaker . 'H'} = $hash_ref->{$bookmaker . 'H'};
    $quotes{$bookmaker . 'A'} = $hash_ref->{$bookmaker . 'A'};
    $quotes{$bookmaker . 'D'} = $hash_ref->{$bookmaker . 'D'};
    if( $quotes{$bookmaker .'H'} eq "" or $quotes{$bookmaker .'A'} eq "" or $quotes{$bookmaker .'D'} eq "" ) {
        warn Dumper(\%quotes);
        return "C";
    }
    my $favorite = (sort { $quotes{$a} <=> $quotes{$b} } keys %quotes)[0] ;
    $favorite = chop($favorite);
    return $favorite;
}

sub who_won {
    my $hash_ref = shift;
    my $home_goals = $hash_ref->{'FTHG'};
    my $away_goals = $hash_ref->{'FTAG'};
    my $winner;
    if($home_goals > $away_goals) {
        $winner = 'H';
    } elsif ( $away_goals > $home_goals) {
        $winner = 'A';
    } else {
        $winner = 'D';
    }
    return $winner;
}

