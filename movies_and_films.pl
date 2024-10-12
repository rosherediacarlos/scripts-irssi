use strict;
use warnings;
use Irssi;
use List::Util 'shuffle';

# Variables del juego
my $current_player;            # Jugador actual
my $host_player;               # Jugador anfitrion
my $timer;                     # Temporizador para controlar los 30 segundos
my $timeout_interval = 300000; # 5 min en milisegundos
my $game_active = 0;           # Indicador de si el juego está en curso
my $movie;                     # Pelicula/serie
my @clues;                     # Lista de pistas
my $channel = "#prueba-test";  # Sala para jugar


#Funcion para gestionar las pistas
sub manage_clues {
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
    
    #Comando !menu <plato> para indiciar el juego, en privado
    if ($message =~ /^!pelicula\s+(\w+)/i){
        if ($movie){
            $server->command("msg $nick El juego ya está en marcha.");
            return 
        }
        my @words = split(' ', $message);
        $current_player = join(" ", @words[1]);
        $movie = join(" ", @words[2..$#words]);
        $server->command("msg Vas a invitar a $current_player a ver la pelicula $movie !pista (add, list, del)\x02 para gestionar las pistas, o sin nada para ver los comandos (como ayuda). 
Una vez insertadas las pistas, utiliza el comando \x02!proponer_pelicula\x02 para adivinar la pelicula/serie");
        $host_player = $nick;
    }
    #Añadir pistas
    elsif ($message =~ /^!pista/i){
        manage_clues($server, $message, $nick, $addess, $target);
    #Empezar el juego
    }elsif ($message =~ /^!proponer_pelicula/i && $movie){
        start_timer($server, $target);
    }      
}

# Función para manejar el temporizador de X segundos
sub start_timer {
    my ($server, $target) = @_;
    
    $server->command("msg $channel $current_player invita a $host_player a ver una pelicula ¿Adivinarás cuál? ('!veremos opción')");
    
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
        Irssi::timeout_add_once($current_timeout, sub {
            if ($movie){
                $server->command("msg $channel \x02Nueva pista:\x02 $clue");
            }
        }, undef);
        
        # Incrementar el tiempo de espera acumulativo para la siguiente pista
        $time_offset += $time_for_clue;
    }
    
    # Añadir un temporizador final para mostrar el mensaje de finalización
    Irssi::timeout_add_once(($timeout_interval+10), sub {
        if ($movie) {
            $server->command("msg $channel \x0304¡Vaya llegas tarde. Ha iniciado la pelicuca/serie y ya no llegas a tiempo, mejr suerte para la proxima \x02$current_player-kun\x02!\x0304");
            $movie = "";
            @clues = ();
        }
    }, undef);

}

sub check_user_option{
    my ($server, $message, $nick, $addess, $target) = @_;
    #Comprobar si el juego sigue iniciado
    if ($movie && $message =~ /^!veremos\s+(\w+)/i && $nick =~ $current_player) {
        # Respuesta del usuario
        my $user_option = $1;
        #Si acierta el usuario
        if (lc($user_option) eq lc($guess_user)){
            $server->command("msg $target $nick \x0303\x02Has acertado el la pelicula/serie.\x02 Ponte un buen traje de gala! PD: Nada de camisetas de futbol\x0303");
            $movie = "";
            @clues = ();
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