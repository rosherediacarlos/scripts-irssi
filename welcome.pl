use strict;
use warnings;
use Irssi;
use Irssi::Irc;
use utf8;

# Convertir el código Unicode a un carácter
sub unicode_to_char {
    my ($unicode) = @_;
    return chr(hex($unicode));
}
# Declarar el nombre del script, autor y licencia
Irssi::settings_add_str('welcome', 'welcome_message', 'Bienvenido al hotel fantasmal');

# Función que se ejecuta cuando alguien se une al canal
sub event_join {
    my ($server, $channel, $nick, $address) = @_;

    # No dar la bienvenida a ti mismo
    return if ($nick eq $server->{nick});

    # Obtener el mensaje de bienvenida desde la configuración
    my $welcome_message = Irssi::settings_get_str('welcome_message');

    my $emoji_code = "1F56F";  # Código Unicode sin "U+"
    my $emoji = unicode_to_char($emoji_code);        
    my $request= "Enciende una vela para dar la bienvenida a la sala a $nick $emoji";
    utf8::decode($request);
    
    #$servidor->command("msg $canal $welcome_message $usuario");
    my $window = Irssi::active_win; 
    $window->command("me $request");
}

# Registrar el evento que detecta cuando alguien se une al canal
Irssi::signal_add('message join', 'event_join');
