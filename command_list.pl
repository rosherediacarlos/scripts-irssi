use strict;
use warnings;
use Irssi;

my $commands = "\x02!hola:\x02 Saludo.  
\x02!adios, !bye, !au revoir:\x02 Despedirse. 
\x02!Mon dieu:\x02 Frances. 
\x02!comandos: \x02 mostrar todos los comandos.";

my $games ="\x02!virus: \x02 buscar virus en la sala.
\x02!hack <nick>:\x02 Hackear usuario. 
\x02!juego_animales: \x02 Juego de los animales. (Los admins tienen el comando \x02!fin\x02 para indicar el usaurio que ha perdido)
\x02!!gol <nick>: \x02 Juego para intentar marcar gol." ;

my $hidden_commands = "\x02!desconectar:\x02 Cerrar sesion.
\x02!permisos:\x02 Añade op.";

my @admin_nicks = ("error_404_","CoraIine", "luck");

#comandos ocultos
#!notice: envia notice a CoraIine
#!errores:\x02 Revisar errores de la sala. 
#!mariposa: busca el nick de cora y escribe una frase.

# Función que se llama cuando alguien habla en el canal
sub response {
    my ($server, $message, $nick, $address, $target) = @_;

    if ($message =~ /^!comandos$/i) {
        $server->command("/msg $nick Comandos disponibles:");
        $server->command("/msg $nick $commands");
        $server->command("/msg $nick Juegos disponibles:");
        $server->command("/msg $nick $games");
        if (grep { $_ eq $nick } @admin_nicks){
            $server->command("/msg $nick Comandos administradores:");
            $server->command("/msg $nick $hidden_commands");
        }
        
    }
    
}

# Función que se ejecuta cuando alguien se une al canal
sub event_join {
    my ($server, $message, $nick, $address, $target) = @_;

    # No dar la bienvenida a ti mismo
    return if ($nick eq $server->{nick});

    # Enviar el mensaje de bienvenida
    
    my $window = Irssi::active_win; 
    $window->command("/msg $nick Comandos disponibles:");
        $window->command("/msg $nick $commands");
        $window->command("/msg $nick Juegos disponibles:");
        $window->command("/msg $nick $games");
        if (grep { $_ eq $nick } @admin_nicks){
            $window->command("/msg $nick Comandos administradores:");
            $window->command("/msg $nick $hidden_commands");
        }
}

# Registrar el evento que detecta cuando alguien se une al canal
Irssi::signal_add('message join', 'event_join');

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'response');

