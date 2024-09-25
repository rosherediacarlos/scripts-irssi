use strict;
use warnings;
use Irssi;

# Función que se llama cuando alguien habla en el canal
sub response {
    my ($server, $message, $nick, $address, $target) = @_;
    
    if ($message =~ /^!notice$/i) {
        
        my @phrases = (
            'Todavía no estoy programado para "Bailar" pero me han dicho que lo haces muy bien.',
            'Tienes permisos especiales en mi código.',
            'Ojalá Carlos fuera un blog para que le visitaras todos los días.',
            'El .gif que anima la vida de Carlos.',
            'Quisiera ser teclado para que me tocaras con tus manitas. Pero mi dueño se pondria celoso XD',
            'Eres como Google tienes todo lo que mi dueño busca.');
            
        my $random_index = int(rand(scalar @phrases));
        my $random_phrase = @phrases[$random_index];
        
        if ($nick =~ "CoraIine"){
            
            $server->command("notice $nick $frase_aleatoria");
        }
        elsif ($nick =~ "error_404_"){
            my $channel_info = $server->channel_find($target);
            if ($channel_info) {
                my @users = $channel_info->nicks();
                my @found_nicks = map { $_->{nick} } 
                                    grep { $_->{nick} =~ /CoraIine/i } 
                                    @users;
                if (@found_nicks) {
                    $server->command("notice CoraIine $frase_aleatoria");
                }
            }
        }
        else{
            $server->command("msg $target buen intento campeon/a $nick!");
        }
    }
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'response');

