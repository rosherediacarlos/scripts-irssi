use strict;
use warnings;
use Irssi;

sub response {
    my ($server, $message, $nick, $address, $target) = @_;
    $message =~ s/\x03(?:\d{1,2}(?:,\d{1,2})?)?//g;
    if ($message =~ /^!errores$/i) {
        my $chanel_info = $server->channel_find($target);
            if ($chanel_info) {
            my @users = $chanel_info->nicks();
            my @found_nicks = map { $_->{nick} } 
                                grep { $_->{nick} =~ /error/i } 
                                @users;
            if (@found_nicks) {
                my $list_nicks = join(', ', @found_nicks);
                my $number_errors = scalar @found_nicks;
                my $window = Irssi::active_win;  
                $window->command("me Ha encontrado $number_errors errores: $list_nicks");
            }
        }

    }
    if ($message =~ /^!virus$/i) {
            my $window = Irssi::active_win;  
            $window->command("me Analizando la sala de posibles virus");
            $window->command("me Ha encontrado una amenaza. Procede a eliminarla...");
            $server->command("kick $target $nick Amaneza eliminada!");
    }
}
Irssi::signal_add('message public', 'response');
