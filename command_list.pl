use strict;
use warnings;
use Irssi;

#comandos que faltan
#!felicidades
#!zapatos

my $commands = "\x02\x0302Comandos:\x03\x02
\x02!hola:\x02 Saludo.  
\x02!felicidades <nick>:\x02 felicitar al usuario.
\x02!adios, !bye, !au revoir:\x02 Despedirse. 
\x02!Mon dieu:\x02 Quejarse en Francés. 
\x02!fantasmas:\x02 Llamará a sus amigos. 
\x02!comandos: \x02 mostrar todos los comandos.";

my $games ="\x02\x0302Juegos disponibles:\x03\x02
\x02!virus: \x02 buscar virus en la sala. 
\x02!hack <nick>:\x02 Hackear usuario. 
\x02!gol <nick>: \x02 Pasar el balón para intentar marcar gol.
                  
\x02!susto <nick>:\x02 Dar un susto al usuario. 
\x02!patata:\x02 reaccionar al susto.
\x02!bola de fuego <nick>:\x02 lanzar una bola de fuego. 
\x02!zap <nick>:\x02 lanzar una descarga. 
\x02!sombrero seleccionador:\x02 Elegir la casa a la que pertenecerás. 
\x02!minipekka <nick>:\x02 Enviar al miniPEKKA al ataque. 
\x02!juego_animales: \x02 Juego de los animales (Los admins tienen el comando \x02!fin\x02 para indicar el usaurio que ha perdido). 
\x02!usuario <nick>:\x02 Juego para adivinar una persona (este comando debe ser en pv a Greavard).
\x02!pelicula <pelicula>:\x02 Iniciar una sesión de cine para adivinar serie/pelicula/anime (este comando debe ser en pv a Greavard). 
\x02!menu <plato>: \x02 (este comando debe ser en pv a Greavard) Juego de la tortura gastronómica.
\x02!ahorcado <palabra>: \x02 (este comando debe ser en pv a Greavard) juego del ahorcado
      
\x02!copa libertadores <numero equipos>:\x02 Simular la Copa Libertadores (El número de equipos debe ser 2,4,8 o 16, tambien esta el comando !fin copa para terminar la simulación) " ;

my $hidden_commands = "\x02!desconectar:\x02 Cerrar sesión.
\x02!permisos:\x02 Añade op.
\x02!restartbot:\x02 si algun script queda en bucle puedes probar este comando antes de desconectarlo.";
#

my @admin_nicks = ("error_404_","CoraIine", "luck", "Mai");

#comandos ocultos
#!notice: envia notice a CoraIine
#!errores:\x02 Revisar errores de la sala. 
#!mariposa: busca el nick de cora y escribe una frase.

sub close_windows_except_1_and_2 {
    my $server = shift;
    
    foreach my $window (Irssi::windows()) {
        my $win_number = $window->{refnum};
        $server->command("/window $win_number close") if $win_number != 1 && $win_number != 2;
    }
}

# Ejecutar cada hora
#Irssi::timeout_add(3600000, 'close_windows_except_1_and_2', undef);

# Funcion que envia los mensajes
sub send_messages{
    my ($server,$nick) = @_;
    
    #$server->command("/msg $nick Comandos disponibles:");
    #$server->command("/msg $nick \x02\x0301Comandos disponibles:\x02\x0301 $commands");
    #$server->command("/msg $nick Juegos disponibles:");
    my $command_msg = $commands . $games;
    
    if (grep { $_ eq $nick } @admin_nicks){
        #$server->command("/msg $nick Comandos administradores:");
        $command_msg = $command_msg . " \x02\x0302Comandos administradores:\x03\x02 $hidden_commands";
    }
    $server->command("/msg $nick $command_msg");
        
    
}

# Función que se llama cuando alguien habla en el canal
sub response {
    my ($server, $message, $nick, $address, $target) = @_;
    $message =~ s/\x03(?:\d{1,2}(?:,\d{1,2})?)?//g;
    if ($message =~ /^!comandos$/i) {
        send_messages($server,$nick);
        #close_windows_except_1_and_2();
    }
    
}

# Función que se ejecuta cuando alguien se une al canal
sub event_join {
    my ($server, $message, $nick, $address, $target) = @_;

    # No dar la bienvenida a ti mismo
    return if ($nick eq $server->{nick});

    # Enviar el mensaje de bienvenida
    send_messages($server,$nick);
    #close_windows_except_1_and_2();
    
}

# Registrar el evento que detecta cuando alguien se une al canal
Irssi::signal_add('message join', 'event_join');

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'response');

