use strict;
use warnings;
use Irssi;
use Irssi::Irc;

# Declarar el nombre del script, autor y licencia
Irssi::settings_add_str('welcome', 'welcome_message', 'Bienvenido hotel fantasmal');

# Función que se ejecuta cuando alguien se une al canal
sub event_join {
    my ($servidor, $canal, $usuario, $direccion) = @_;

    # No dar la bienvenida a ti mismo
    return if ($usuario eq $servidor->{nick});

    # Obtener el mensaje de bienvenida desde la configuración
    my $welcome_message = Irssi::settings_get_str('welcome_message');

    # Enviar el mensaje de bienvenida
    
    #$servidor->command("msg $canal $welcome_message $usuario");
    my $window = Irssi::active_win; 
    $window->command("me Enciende una vela para dar la bienvenida a la sala a $usuario");
}

# Registrar el evento que detecta cuando alguien se une al canal
Irssi::signal_add('message join', 'event_join');
