use strict;
use warnings;
use Irssi;
use List::Util 'shuffle';

# Variables del juego
my @animals;                # Lista de animales mencionados
my @players;                # Lista de jugadores
my $current_player;         # Jugador actual
my $timer;                  # Temporizador para controlar los 30 segundos
my $timeout_interval = 30000;  # 30 segundos en milisegundos
my $game_active = 0;        # Indicador de si el juego está en curso
my $letter_start;

# Función para comenzar el juego
sub start_game {
    my ($server, $channel, $target) = @_;
    
    if ($game_active) {
        $server->command("msg $target ¡Ya hay un juego en curso!");
        return;
    }

    # Reiniciar el juego
    @animals = ();
    @players = shuffle map { $_->{nick} } $channel->nicks();
    #my $my_bot_nick = Irssi::active_win()->{active}->{nick};
    #Irsssi:print($my_bot_nick);
    @players = grep { $_ ne 'Greavard' } @players;
    $current_player = shift @players;
	
	$server->command("msg $target \x02\x0302El juego de los animales consiste en nombrar un animal y 
otro usuario aleatorio debera indicar otro animal que empiece por la 3a letra.\x02\x0302 
\x02\x0301Por ejemplo:\x02\x0301 \x02\x0314 nick1 \x02\x0314 dice 'Perro ' \x02\x0314 Nick2 \x02\x0314 dice 'Raton'");
    $server->command("msg $target ¡El juego ha comenzado! $current_player, di un animal.");
    $game_active = 1;
    
    # Iniciar el temporizador de 30 segundos
    start_timer($server, $channel, $target);
}

# Función que maneja cuando se dice un animal
sub handle_animal {
    my ($server, $channel,$target, $player, $animal) = @_;
    
    return unless $game_active;
	
    if ($player ne $current_player) {
        $server->command("msg $target No es tu turno, $player.");
        return;
    }
    
    if (grep { $_ eq $animal } @animals) {
        $server->command("msg $target ¡Ese no es un animal válido, $player!");
        return;
    }
    #Comprobar que el animal empiece por la letra designada
	if ($letter_start){
		if (lc($letter_start) ne lc(substr($animal, 0, 1))){
			$server->command("msg $target ¡Ese no es un animal valido, debe empezar por la letra \x02".uc($letter_start)."\x02, $player!");
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
    $server->command("msg $target $player dijo $animal.");
    
    # Seleccionar siguiente jugador
	if (scalar(@players) <= 0){	
		end_game($server,$channel, $target);
		$server->command("msg $target ¡No quedan mas nicks en la sala!");
		return
	}
	Irssi::print(scalar(@players));
    $current_player = shift @players;
    #push @players, $current_player;
    $server->command("msg $target $current_player, es tu turno. Di un animal.");

    # Reiniciar el temporizador
    reset_timer($server, $channel, $target);
}

# Función para manejar el temporizador de 30 segundos
sub start_timer {
    my ($server, $channel, $target) = @_;
    
    $timer = Irssi::timeout_add($timeout_interval, sub {
        $server->command("msg $target ¡$current_player ha perdido por no responder en 30 segundos!");
        end_game($server,$channel, $target);
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
    
}

sub start_timer_to_expose {
	my ($server, $channel, $target) = @_;
    
    $timer = Irssi::timeout_add($timeout_interval, sub {
        $server->command("msg $target ¡Todos listos poder criticar a $current_player en la sala! (teneis 1min, no hacer flood, siempre respetando las normas y sin faltar el respeto)");
        end_game($server,$channel, $target);
    }, undef);
}

# Evento cuando alguien envía un mensaje
Irssi::signal_add('message public', sub {
    my ($server, $msg, $nick, $address, $target) = @_;
    
    if ($msg =~ /^!animalgame$/i) {
        # Comenzar el juego si alguien escribe !animalgame        
        my $channel = $server->window_item_find($target);
        start_game($server, $channel, $target);
        
    } elsif ($game_active && $msg =~ /^(\w+)$/) {
        # Manejar cuando alguien dice un animal
        my $animal = $1;
        my $channel = $server->window_item_find($target);
        handle_animal($server, $channel, $target, $nick, $animal);
    }
});
