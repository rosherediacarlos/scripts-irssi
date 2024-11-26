use strict;
use warnings;
use Irssi;
use List::Util 'shuffle';

# Variables del juego
my $current_player;             # Jugador actual
my $host_player;                # Jugador anfitrion
my $timer;                      # Temporizador para controlar los 30 segundos
my $timeout_interval = 240000;  # 3 min en milisegundos
my $game_active = 0;            # Indicador de si el juego está en curso
my $movie;                      # Pelicula/serie
my @clues;                      # Lista de pistas
my $channel = "#hotelfantasma"; # Sala para jugar
#my $channel = "#prueba-test";  # Sala para pruebas 
my @timeouts = ();              # Lista para almacenar los IDs de los timeouts activos

#Funcion para gestionar las pistas
sub manage_movie_clues {
    my ($server, $message, $nick, $addess, $target) = @_;
    my @words = split(' ', $message);
    my $command_option=" ";
    if (@words){
        $command_option = $words[1];
    }
    if ($command_option){
        #Añadir pista
        if ($command_option =~ /^add/i) {
            my $clue = join(" ", @words[2..$#words]);
            push @clues, $clue;
            print('aaa');
            $server->command("msg $nick Se ha añadido la pista $clue a la lista");
        #mostrar las pistas
        }elsif ($command_option =~ /^list/i) {
            my $count = 1;
            my $clue;
            if (!@clues){
                $server->command("msg $nick No hay pistas.");
            }else{
                foreach $clue (@clues) {
                    $server->command("msg $nick \x02Pista numero $count:\x02 $clue");
                    $count= $count + 1;
                }
            }
            
        #Eliminar una pista
        }elsif ($command_option =~ /^del/i) {
            my $index_to_remove = $words[2] - 1;
            my @clues = splice(@clues, $index_to_remove, 1);
            $server->command("msg $nick se ha eliminado la pista");
        }
    #ayuda mostrar comandos
    }else {
        $server->command("msg $nick Comandos para las pistas: 
\x02!pista add <pista>\x02 añade una pista en la lista. 
\x02 !pista list\x02 muestra una lista de las pistas.
\x02 !pista del <numero>\x02 elimina una pista de la lista.");
        }
}

#Funcion para empezar el juego
sub serie_and_movies_games{
    my ($server, $message, $nick, $addess, $target) = @_;
    $message =~ s/\x03(?:\d{1,2}(?:,\d{1,2})?)?//g;
    #Comando !menu <plato> para indiciar el juego, en privado
    if ($message =~ /^!pelicula\s+([\w\-]+)/i){
        if ($movie){
            $server->command("msg $nick El juego ya está en marcha.");
            return 
        }
        
        # Limpiar variables antes de empezar el juego
        $movie = "";
        @clues = ();
        $host_player = "";
        
        my @words = split(' ', $message);
        #$current_player = join(" ", $   words[1]);
        $movie = join(" ", @words[1..$#words]);
        $server->command("msg $nick Vas a iniciar una sesión de cine para ver $movie. Usa el comando \x02!pista (add, list, del)\x02 para gestionar las pistas, o \x02!pista\x02 para ver los comandos (como ayuda). 
Una vez insertadas las pistas, utiliza el comando \x02!proponer_pelicula\x02 para adivinar la pelicula/serie. Tambien puedes usar \x02!pelicula_cancelar\x02 para cancelar el juego.");
        $host_player = $nick;
    }
    #Añadir pistas
    elsif ($movie && $message =~ /^!pista/i){
        manage_movie_clues($server, $message, $nick, $addess, $target);
    #Empezar el juego
    }elsif ($movie && $message =~ /^!proponer_pelicula/i && $movie){
        start_timer($server, $target);
    }
    elsif ($movie && $message =~ /^!pelicula_cancelar/i && $movie){
        if ($host_player =~ $nick){
            $server->command("msg $nick El juego ha sido cancelado.");
            cancel_game($server, $target);
            
        }
    }    
}

# Función para manejar el temporizador de X segundos
sub start_timer {
    my ($server, $target) = @_;
    
    $server->command("msg $channel $host_player organiza una cinema en el salón con palomitas de maíz y gaseosas ¿Adivinas que cinta será? ('!veremos opción')");
    
    #Dividir el tiempo entre el numero de pistas
    my $time_for_clue = 1;
    my $time_offset = 10;
    my $clue;
    
    if (@clues) {
        $time_for_clue = $timeout_interval / ((scalar @clues)+1);
        $time_offset = $time_for_clue;
    }
    
    foreach $clue (@clues) {
        # Aumentamos el tiempo acumulativo para cada pista
        my $current_timeout = $time_offset;
        my $timeout_id = Irssi::timeout_add_once($current_timeout, sub {
            if ($movie) {
                $server->command("msg $channel \x02Nueva pista:\x02 $clue");
            }
        }, undef);
        push @timeouts, $timeout_id;
        $time_offset += $time_for_clue;
    }
    
    # Añadir un temporizador final para mostrar el mensaje de finalización
    my $final_timeout_id = Irssi::timeout_add_once($timeout_interval + 10, sub {
        if ($movie) {
            $server->command("msg $channel \x0304¡Se cancela el cinema, mejor suerte a la próxima perdedores-chan!\x0304");
            cancel_game($server, $target);
        }
    }, undef);
    push @timeouts, $final_timeout_id;

}

sub cancel_game {
    my ($server, $target) = @_;

    $movie = "";
    @clues = ();
    $host_player = "";

    # Eliminar todos los timeouts activos
    foreach my $timeout_id (@timeouts) {
        Irssi::timeout_remove($timeout_id);
    }
    @timeouts = ();  # Limpiar la lista de timeouts
}

sub check_user_option{
    my ($server, $message, $nick, $addess, $target) = @_;
    $message =~ s/\x03(?:\d{1,2}(?:,\d{1,2})?)?//g;
    #Comprobar si el juego sigue iniciado
    #&& $nick =~ $current_player
    #se ha quitado la comprobacion para que todos puedan responder
    if ($movie && $message =~ /^!veremos\s+([\w\-]+)/i) {
        # Respuesta del usuario
        my @words = split(' ', $message);
        my $user_option = join(" ", @words[1..$#words]);
        #Si acierta el usuario
        if (lc($user_option) eq lc($movie)){
            $server->command("msg $target \x0303¡$nick has acertado, puedes elegir entre 2 entradas gratis para invitar a alguien o un cubo de palomitas de maíz gratis!\x0303");
            cancel_game($server, $target);  # Terminar el juego
        #En caso de fallo se elige una tortura aleatoria para el usuario
        }else {
            $server->command("msg $target ¿$nick de verdad pensabas que te invitaria a ver eso?");
        }
    }
}

# Enlazar la señal 'message private' a nuestra función
Irssi::signal_add('message private', 'serie_and_movies_games');

# Enlazar la señal 'message public' a nuestra función
Irssi::signal_add('message public', 'check_user_option');
