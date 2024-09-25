use strict;
use warnings;
use Irssi;

# Registra el script con irssi
#Irssi::script_register('mi_bot', '1.0', 'Bot simple de prueba');

# Función que se llama cuando alguien habla en el canal
sub respuesta {
    my ($servidor, $mensaje, $nick, $direccion, $target) = @_;
    
    if ($mensaje =~ /^!notice$/i) {
        
        my @frases = (
            'Todavía no estoy programado para "Bailar" pero me han dicho que lo haces muy bien.',
            'Tienes permisos especiales en mi código.',
            'Ojalá Carlos fuera un blog para que le visitaras todos los días.',
            'El .gif que anima la vida de Carlos.',
            'Quisiera ser teclado para que me tocaras con tus manitas. Pero mi dueño se pondria celoso XD',
            'Eres como Google tienes todo lo que mi dueño busca.');
            
        my $indice_aleatorio = int(rand(scalar @frases));
        my $frase_aleatoria = @frases[$indice_aleatorio];
        
        if ($nick =~ "CoraIine"){
            
            $servidor->command("notice $nick $frase_aleatoria");
        }
        elsif ($nick =~ "error_404_"){
            my $canal_info = $servidor->channel_find($target);
            if ($canal_info) {
                my @usuarios = $canal_info->nicks();
                my @nicks_encontrados = map { $_->{nick} } 
                                    grep { $_->{nick} =~ /CoraIine/i } 
                                    @usuarios;
                if (@nicks_encontrados) {
                    $servidor->command("notice CoraIine $frase_aleatoria");
                }
            }
        }
        else{
            $servidor->command("msg $target buen intento campeon/a $nick!");
        }
    }
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'respuesta');

