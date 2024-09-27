use strict;
use warnings;
use Irssi;
use Data::Dumper;

#Frases para los que no acierten
my @tortures = (
"frase1",
"frase2"
); 
#plato de comida
my $food_plate;
#Nick del que prepara el plato
my $chef_nick;
#lista de pistas
my @clues;
# Temporizador para controlar los 30 segundos
my $timer;       
# 5minutos en milisegundos           
#my $timeout_interval = 300000;  
my $timeout_interval = 60000;  
#Sala para jugar
my $channel = "#prueba-test";

#Funcion para gestionar las pistas
sub manage_clues {
    my ($server, $message, $nick, $addess, $target) = @_;
    
        
}

#Funcion para empezar el juego
sub start_gastronomic_torture{
    my ($server, $message, $nick, $addess, $target) = @_;
    
    #Comando !menu <plato> para indiciar el juego, en privado
    if ($message =~ /^!menu\s+(\w+)/i){
        if ($food_plate){
            $server->command("msg $nick el juego ya esta en marcha");
            return 
        }
        my @words = split(' ', $message);
        my $menu = join(" ", @words[1..$#words]);
        $server->command("msg $nick Hoy vas a preparar \x02$menu\x02, para la tortura gastronomica, 
por favor indica si lo deseas unas pistas con el comando \x02!pista 'pista'\x02 (Sin las comillas). 
Una vez insertadas las pistas, utiliza el comando \x02!empezar_tortura\x02 para empezar el sufrimiento de la sala");
        $chef_nick = $nick;
        $food_plate = $menu;
    }
    #Añadir pistas
    elsif ($message =~ /^!pista\s+(\w+)/i){
        #Estaria bien crear una funcion para gestion las pistas
        #poder eliminar o consultarlas
        if ($message =~ /^\S+\s+(.+)/) {
            my @words = split(' ', $message);
            my $clue = join(" ", @words[1..$#words]);
            push @clues, $clue;
            
            $server->command("msg $nick hemos añadido la pista $clue a la lista");
        }
    #Empezar el juego
    }elsif ($message =~ /^!empezar_tortura/i){
        if ($chef_nick =~ $nick){
            
            start_timer($server, $target);
        }
    }      
}

sub check_food_plate{
    my ($server, $message, $nick, $addess, $target) = @_;
    #Comprobar si el juego sigue iniciado
    if ($food_plate) {
        #Si acierta el usuario
        if ($message =~ $food_plate){
            $server->command("msg $target $nick Ha acertado el plato");
            $server->command("mode $target +v $nick");
            $food_plate = "";
        #En caso de fallo se elige una tortura aleatoria para el usuario
        }else {
            my $random_index = int(rand(scalar @tortures));
            my $random_torture = $tortures[$random_index];
            $server->command("msg $target $nick ha sufrido con $random_torture");
        }
    }
}

# Función para manejar el temporizador de X segundos
sub start_timer {
    my ($server, $target) = @_;
    
    $server->command("msg $channel Ya tenemos al chef $chef_nick preparando la tortura gastronomica. Quien se adivinará el plato sin sufrir en el camino?");
    
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
            $server->command("msg $channel \x02Nueva pista:\x02 $clue");
        }, undef);
        
        # Incrementar el tiempo de espera acumulativo para la siguiente pista
        $time_offset += $time_for_clue;
    }
    if ($food_plate) {
        # Añadir un temporizador final para mostrar el mensaje de finalización
        Irssi::timeout_add_once(($timeout_interval+10), sub {
            $server->command("msg $channel ¡La tortura ha terminado y nadie ha sido capaz de acertar!");
            $food_plate = "";
        }, undef);
    }

}


# Enlazar la señal 'message private' a nuestra función
Irssi::signal_add('message private', 'start_gastronomic_torture');

# Enlazar la señal 'message public' a nuestra función
Irssi::signal_add('message public', 'check_food_plate');
