use strict;
use warnings;
use Irssi;
use List::Util 'shuffle';

# Variables del juego
my $host_player;               # Jugador actual
my $timer;                     # Temporizador para controlar los 30 segundos
my $timeout_interval = 300000; # 5 min en milisegundos
my $game_active = 0;           # Indicador de si el juego está en curso
my $guess_user;                # Usuario para acertar
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
sub guess_user_games{
    my ($server, $message, $nick, $addess, $target) = @_;
    
    #Comando !menu <plato> para indiciar el juego, en privado
    if ($message =~ /^!usuario\s+(\w+)/i){
        if ($guess_user){
            $server->command("msg $nick El juego ya está en marcha.");
            return 
        }
        my @words = split(' ', $message);
        $host_player = $nick;
        $guess_user = join(" ", @words[1..$#words]);
        $server->command("msg Vas a describir al usuario $guess_user para que el resto lo intenten adivinar. Para añadir pistas usa el comando !pista (add, list, del)\x02 para gestionar las pistas, o sin nada para ver los comandos (como ayuda). 
Una vez insertadas las pistas, utiliza el comando \x02!adivinar_usuario\x02 para adivinar la pelicula/serie");
    }
    #Añadir pistas
    elsif ($message =~ /^!pista/i){
        manage_clues($server, $message, $nick, $addess, $target);
    #Empezar el juego
    }elsif ($message =~ /^!adivinar_usuario/i && $guess_user){
        start_timer($server, $target);
    }      
}

# Función para manejar el temporizador de X segundos
sub start_timer {
    my ($server, $target) = @_;
    
    $server->command("msg $channel ¿Quien sera capaz de adivinar el usuario con el que piensa $host_player?('!usuario opción')");
    
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
            if ($guess_user){
                $server->command("msg $channel \x02Nueva pista:\x02 $clue");
            }
        }, undef);
        
        # Incrementar el tiempo de espera acumulativo para la siguiente pista
        $time_offset += $time_for_clue;
    }
    
    # Añadir un temporizador final para mostrar el mensaje de finalización
    Irssi::timeout_add_once(($timeout_interval+10), sub {
        if ($guess_user) {
            $server->command("msg $channel \x0304¡Vaya se ha acabado el tiempo parece que no conoceis tanto a \x02$guess_user\x02\x0304");
            $guess_user = "";
            @clues = ();
        }
    }, undef);

}

sub check_user_option{
    my ($server, $message, $nick, $addess, $target) = @_;
    #Comprobar si el juego sigue iniciado
    if ($guess_user && $message =~ /^!usuario\s+(\w+)/i ) {
        # Respuesta del usuario
        my $user_option = $1;
        #Si acierta el usuario
        if (lc($user_option) eq lc($guess_user)){
            $server->command("msg $target $nick \x0303\x02Has acertado!\x02 Parece que si conocias a $guess_user\x0303");
            $guess_user = "";
            @clues = ();
        #En caso de fallo se elige una tortura aleatoria para el usuario
        }else {
            $server->command("msg $target $nick, lo siento pero $user_option no es la persona en la que piensa $host_player. Prueba otra vez");
        }
    }
}

# Enlazar la señal 'message private' a nuestra función
Irssi::signal_add('message private', 'guess_user_games');

# Enlazar la señal 'message public' a nuestra función
Irssi::signal_add('message public', 'check_user_option');