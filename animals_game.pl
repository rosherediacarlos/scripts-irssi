use strict;
use warnings;
use Irssi;
use List::Util 'shuffle';

# Variables del juego
my @animals;                   # Lista de animales mencionados
my @players;                   # Lista de jugadores
my $current_player;            # Jugador actual
my $last_player;               # Ultimo jugador
my $timer;                     # Temporizador para controlar los 30 segundos
my $timeout_interval = 30000;  # 30 segundos en milisegundos
my $game_active = 0;           # Indicador de si el juego está en curso
my $letter_start;              # Letra de inicio
my $timer_to_expose = 60000;  # 1 minuto en milisegundos

# Función para comenzar el juego
sub start_game {
    my ($server, $channel, $target) = @_;
    
    #Comprobar si ya esta iniciado el juego
    if ($game_active) {
        $server->command("msg $target ¡El juego ya está iniciado!");
        return;
    }

    # Reiniciar el juego
    @animals = ();
    #Obtener todos los nicks eliminando el bot
    @players = shuffle map { $_->{nick} } $channel->nicks();
    @players = grep { $_ ne 'Greavard' } @players;
    #Otener el primer nick aleatorio
    $current_player = shift @players;
	
	$server->command("msg $target 
\x02\x0302El juego de los animales ha iniciado. 
En este juego saldrá un nick aleatorio y debera decir un animal, seguido de esto, 
pasará el testigo a otro nick aleatorio. Este nuevo nick deberá decir otro animal, 
no repetido, que empiece por la 3a letra del animal nombrado anteriormente.
Tienes 30 segundos para pensar el animal o perderás el juego. 
El juego acabará cuando no queden más usuarios para decir animal o alguien pierda.\x02\x0302 
\x02\x0314 Por ejemplo, empieza nick2 el cual dice 'Perro', 
el siguiente nick debe decir un animal que empiece por R 'Ratón'.\x02\x0314");
    $server->command("msg $target ¡El juego ha comenzado! $current_player, di un animal (Usando el comando !animal <animal>).");
    $game_active = 1;
    
    # Iniciar el temporizador de 30 segundos
    start_timer($server, $channel, $target);
}

# Función que maneja cuando se dice un animal
sub handle_animal {
    my ($server, $channel, $target, $player, $animal) = @_;
    
    return unless $game_active;
	
    if ($player ne $current_player) {
        $server->command("msg $target No es tu turno, $player.");
        return;
    }
    
    #Revisar si el animal ya lo han dicho anteriormente
    if (grep { $_ eq $animal } @animals) {
        $server->command("msg $target ¡Ese animal lo ha dicho otro usuario, nombra otro $player!");
        return;
    }
    #Comprobar que el animal empiece por la letra designada
	if ($letter_start){
		if (lc($letter_start) ne lc(substr($animal, 0, 1))){
			$server->command("msg $target  $player ¡Ese no es un animal válido, debe empezar por la letra \x02".uc($letter_start)."\x02!");
			return;
		}
		else{
			$letter_start = substr($animal, 2, 1);
		}
			
	}
	else{
		$letter_start = substr($animal, 2, 1);
	}
    
   
    push @animals, $animal;  # Añadir animal a la lista
    $server->command("msg $target $player Ha dicho $animal.");
    
	# Seleccionar siguiente jugador
	if (scalar(@players) <= 0){	
	    #end_game($server,$channel, $target);
	    #$server->command("msg $target ¡No quedan más  nicks en la sala!");
	    #return
	    # Volvermos a rellenar la lista de los nick de la sala
	    @players = shuffle map { $_->{nick} } $channel->nicks();
	    @players = grep { $_ ne 'Greavard' } @players;
	}
    
    $last_player = $current_player;
    $current_player = select_next_user($channel);
    $server->command("msg $target $current_player es tu turno. Di un animal,
que empiece por la letra \x02".uc($letter_start)."\x02.");

    # Reiniciar el temporizador
    reset_timer($server, $channel, $target);
}

sub select_next_user {
    my ($channel) = @_;
    my $random_nick;

    # Bucle while que se ejecuta hasta que se encuentre un nick válido o se agote la lista
    while (!$random_nick && @players) {
        # Obtener un nick aleatorio de la lista
        my $new_nick = shift @players;

        # Verificar si el nick aún está en el canal
        if ($channel->nick_find($new_nick)) {
	    # Asignar el nick encontrado
            $random_nick = $new_nick;  
        }
    }
    # Retornar el nick encontrado (o undef si no se encuentra)
    return $random_nick;  
}

# Función para manejar el temporizador de 30 segundos
sub start_timer {
    my ($server, $channel, $target) = @_;
    
    $timer = Irssi::timeout_add($timeout_interval, sub {
        $server->command("msg $target ¡$current_player ha perdido por no responder en los 30 segundos!");
        end_game($server,$channel, $target);
	$server->command("msg $target ¡Todos listos para criticar a $current_player en la sala! (teneis 1min, no hacer flood, siempre respetando las normas y sin faltar el respeto)");
        start_timer_to_expose($server,$channel, $target);
    }, undef);
}

# Reiniciar el temporizador
sub reset_timer {
    my ($server, $channel, $target) = @_;
    Irssi::timeout_remove($timer);
    start_timer($server, $channel, $target);
}

# Finalizar el juego
sub end_game {
    my ($server, $channel, $target) = @_;
    $server->command("msg $target ¡El juego ha terminado!");
    Irssi::timeout_remove($timer);
    $game_active = 0;
    $letter_start = "";
    
}

sub start_timer_to_expose {
    my ($server, $channel, $target) = @_;
    
    $timer = Irssi::timeout_add($timer_to_expose, sub {
        $server->command("msg $target ¡Se ha acabado el tiempo!");
        Irssi::timeout_remove($timer);
	$game_active = 0;
	$letter_start = "";
    }, undef);
}

# Evento cuando alguien envía un mensaje
Irssi::signal_add('message public', sub {
    my ($server, $msg, $nick, $address, $target) = @_;
    
    if ($msg =~ /^!juego_animales$/i) {
        # Comenzar el juego si alguien escribe !animalgame        
        my $channel = $server->window_item_find($target);
        start_game($server, $channel, $target);
        
    } elsif ($msg =~ /^!fin$/i) {
	my $channel = $server->window_item_find($target);
	my $nick_object = $channel->nick_find($nick);
	
	if ($nick_object->{op} && $game_active) {

	    end_game($server, $channel, $target);

	    if ($last_player) {
		$server->command("msg $target $last_player ha perdido. ¡Todos listos para criticar a $last_player en la sala! (tienen 1min, no hacer flood, siempre respetando las normas y sin faltar el respeto)");
		start_timer_to_expose($server, $channel, $target);
	    }

	    return;

	}
    } elsif ($game_active && $msg =~ /^!animal\s+([\w\-]+)/i) {
        # Manejar cuando alguien dice un animal
        my $animal = $1;
        my $channel = $server->window_item_find($target);
        handle_animal($server, $channel, $target, $nick, $animal);
    }
});
