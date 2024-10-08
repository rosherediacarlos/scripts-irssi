use strict;
use warnings;
use Irssi;

my @houses = (
"Gryffindor",
"Hufflepuff",
"Ravenclaw",
"Slytherin",
);

my %description = (
    'Gryffindor'   => "\x0304Te caracterizas por tu valentía, disposición, coraje y caballerosidad. Tu símbolo será ahora el león.\x0304",
    'Hufflepuff' => "\x0308Bienvenido. Eres muy leal, honesto y sin miedo a los trabajos pesados. Tu nuevo símbolo será el tejón negro.\x0308",
    'Ravenclaw'    => "\x0312Eres muy creativo, curioso y siempre buscas una respuesta. El Águila será tu nuevo símbolo.\x0312",
    'Slytherin'    => "\x0303Nos caracterizamos por la ambición y astucia. Nuestro animal representativo es la serpiente.\x0303",
);

# Función que se llama cuando alguien ejecuta cuando alguien del 
# chat indica unos de los siguientes comandos
sub response {
    my ($server, $message, $nick, $address, $target) = @_;

    if ($message =~ /^!sombrero seleccionador/i) {
        my $window = Irssi::active_win; 
        $window->command("me Empuja a $nick contra el trono. Le coloca el sombrero seleccionador en la cabeza.");
        
        # Elegir la casa aleatoriamente
        my $random_index = int(rand(scalar @houses));
        my $random_house = $houses[$random_index];
        
        # Descripcion
        my $description = $description{$random_house};
       
        my $request= "¡La casa elegida para $nick, es $random_house! $description";
        $server->command("msg $target $request");
    }
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'response');

