use strict;
use warnings;
use Irssi;
use Data::Dumper;

#Frases para los que no acierten
my @tortures = (
"Le cae un globo lleno de salsa de soja a",
"Le tiran una pelota de espaguetis con salsa a la cara a",
"Le rocian con un chorrito de vinagre agridulce a",
"Le salpican crema batida en la cara a",
"Le cae un balde de salsa barbacoa sobre la espalda a",
"Chapuzón de salsa de tomate por todo el cuerpo de",
"Le cae una lluvia de lentejas cocidas a",
"Le lanzan una botella de salsa picante abierta a",
"Le cubren con una capa de guacamole a",
"Le vierten una olla de caldo hirviendo (¡cuidado!) sobre los pies de",
"Le rocían miel pegajosa por la cabeza a",
"Le lanzan un puñado de arroz pegajoso a",
"Le tiran una ensalada de frutas encima a",
"Un tartazo de mousse de chocolate aterriza en la cabeza de",
"Embadurnan con puré de papas a",
); 
#plato de comida
my $food_plate;
#Nick del que prepara el plato
my $chef_nick;
#lista de pistas
my @clues;
# Temporizador para controlar los 30 segundos
my $timer;       
# 5 minutos en milisegundos           
my $timeout_interval = 300000;  
#Para pruebas reducimos el tiempo a 1 min
#my $timeout_interval = 30000;  
#Sala para jugar
my $channel = "#prueba-test";

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
sub start_gastronomic_torture{
    my ($server, $message, $nick, $addess, $target) = @_;
    
    #Comando !menu <plato> para indiciar el juego, en privado
    if ($message =~ /^!menu\s+(\w+)/i){
        if ($food_plate){
            $server->command("msg $nick El juego ya está en marcha.");
            return 
        }
        my @words = split(' ', $message);
        my $menu = join(" ", @words[1..$#words]);
        $server->command("msg $nick Hoy vas a preparar \x02$menu\x02, para la tortura gastronómica.
Por favor indica si lo deseas unas pistas con el comando \x02!pista (add, list, del)\x02 para gestionar las pistas, o sin nada para ver los comandos (como ayuda). 
Una vez insertadas las pistas, utiliza el comando \x02!empezar_tortura\x02 para empezar el sufrimiento de la sala");
        $chef_nick = $nick;
        $food_plate = $menu;
    }
    #Añadir pistas
    elsif ($message =~ /^!pista/i){
        manage_clues($server, $message, $nick, $addess, $target);
    #Empezar el juego
    }elsif ($message =~ /^!empezar_tortura/i && $food_plate){
        if ($chef_nick =~ $nick){
            
            start_timer($server, $target);
        }
    }      
}

sub check_food_plate{
    my ($server, $message, $nick, $addess, $target) = @_;
    #Comprobar si el juego sigue iniciado
    if ($food_plate && $message =~ /^!plato\s+(\w+)/i) {
        # Respuesta del usuario
        my $user_plate = $1;
        #Si acierta el usuario
        if (lc($user_plate) eq lc($food_plate)){
            $server->command("msg $target $nick \x02\x0303Has acertado el plato\x02\x0303");
            $server->command("mode $target +v $nick");
            $server->command("msg $target $nick \x02\x0303Aquí tienes tu estrella michelin por salir con vida de la tortura gastronómica.\x02\x0303");
            $food_plate = "";
        #En caso de fallo se elige una tortura aleatoria para el usuario
        }else {
            my $random_index = int(rand(scalar @tortures));
            my $random_torture = $tortures[$random_index];
            $server->command("msg $target \x02\x0304$random_torture\x02\x0304 $nick ");
        }
    }
}

# Función para manejar el temporizador de X segundos
sub start_timer {
    my ($server, $target) = @_;
    
    $server->command("msg $channel Ya tenemos al chef $chef_nick preparando la tortura gastronómica. ¿Quién adivinará el plato sin sufrir en el camino? (Para probar suerte utiliza '!plato opción')");
    
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
            if ($food_plate){
                $server->command("msg $channel \x02Nueva pista:\x02 $clue");
            }
        }, undef);
        
        # Incrementar el tiempo de espera acumulativo para la siguiente pista
        $time_offset += $time_for_clue;
    }
    
    # Añadir un temporizador final para mostrar el mensaje de finalización
    Irssi::timeout_add_once(($timeout_interval+10), sub {
        if ($food_plate) {
            Irssi::print($food_plate);
            $server->command("msg $channel \x0304¡La \x02tortura gastronómica \x02 ha terminado y nadie ha sido capaz de acertar!\x0304");
            $food_plate = "";
        }
    }, undef);

}


# Enlazar la señal 'message private' a nuestra función
Irssi::signal_add('message private', 'start_gastronomic_torture');

# Enlazar la señal 'message public' a nuestra función
Irssi::signal_add('message public', 'check_food_plate');
