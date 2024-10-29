use strict;
use warnings;
use Irssi;
use Irssi::Irc;

#lista de nicks baneados
my @ban_nicks = ("amanecer_andaluz","pau__", "paula__", "paulita___");

# Declarar el nombre del script, autor y licencia
Irssi::settings_add_str('ban_empotrador', 'ban_empotrador_message', 'Ban empotrador');

# Función que se ejecuta cuando alguien se une al canal
sub event_join {
    my ($server, $channel, $nick, $address) = @_;

    # No dar la bienvenida a ti mismo
    return if ($nick eq $server->{nick});
    #poner el nick en minusculas para la comprobación
    my $nick_lowercase = lc($nick);
    
    if (grep { $_ eq $nick_lowercase } @ban_nicks){
        $server->command("ban $channel $nick No esta permitido el acceso");
        $server->command("kick $channel $nick No esta permitido el acceso");
    }
        
}

# Registrar el evento que detecta cuando alguien se une al canal
Irssi::signal_add('message join', 'event_join');
