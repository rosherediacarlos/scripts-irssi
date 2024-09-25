use strict;
use warnings;
use Irssi;

my $comandos = "\x02!hola:\x02 Saludo.  
\x02!adios, !bye, !au revoir:\x02 Despedirse. 
\x02!Mon dieu:\x02 Frances. 
\x02!permisos:\x02 Añade op. 
\x02!errores:\x02 Revisar errores de la sala. 
\x02!virus:\x02 Revisar virus de la sala. 
\x02!notice:\x02 Envia notice 
\x02!hack <nick>:\x02 Hackear usuario. 
\x02!desconectar:\x02 Cerrar sesion";

# Función que se llama cuando alguien habla en el canal
sub respuesta {
    my ($servidor, $mensaje, $nick, $direccion, $target) = @_;

    if ($mensaje =~ /^!help$/i) {

        $servidor->command("/msg $nick Comandos displibles:");
        $servidor->command("/msg $nick $comandos");
    }
    
}

# Función que se ejecuta cuando alguien se une al canal
sub event_join {
    my ($servidor, $mensaje, $nick, $direccion, $target) = @_;

    # No dar la bienvenida a ti mismo
    return if ($nick eq $servidor->{nick});

    # Enviar el mensaje de bienvenida
    
    #$servidor->command("msg $canal $welcome_message $usuario");
    my $window = Irssi::active_win; 
    $window->command("/msg $nick Comandos displibles:");
    $window->command("/msg $nick $comandos");
}

# Registrar el evento que detecta cuando alguien se une al canal
Irssi::signal_add('message join', 'event_join');

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'respuesta');

