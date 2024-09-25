use strict;
use warnings;
use Irssi;
use Irssi::Irc;

# Declarar el nombre del script, autor y licencia
Irssi::settings_add_str('welcome', 'welcome_message', 'Ban empotrador');

# Función que se ejecuta cuando alguien se une al canal
sub event_join {
    my ($server, $channel, $nick, $address) = @_;

    # No dar la bienvenida a ti mismo
    return if ($nick eq $server->{nick});
    
    if ($nick eq 'amanecer_andaluz'){
        $server->command("ban $channel $nick No esta permitido el acceso");
        $server->command("kick $channel $nick No esta permitido el acceso");
    }
        
}

# Registrar el evento que detecta cuando alguien se une al canal
Irssi::signal_add('message join', 'event_join');
