use strict;
use warnings;
use Irssi;

# Función para comprobar si existe el nick en la sala
sub check_user_channel{
    my ($server,$tarject_nick, $target) = @_;
    my $found_nick = 0;
    # Obtener información del canal
    my $channel_info = $server->channel_find($target);
    foreach my $nick_info ($channel_info->nicks()) {
        if (lc($nick_info->{nick}) eq lc($tarject_nick)) {
            $found_nick = 1;
            last;
        }
    }
    return $found_nick;
}

sub send_request{
    my ($server, $request, $target,$found_nick) = @_;
    
    if ($found_nick) {
        $server->command("msg $target $request");
    }
}

# Función que se llama cuando alguien ejecuta cuando alguien del 
# chat indica unos de los siguientes comandos
sub response {
    my ($server, $message, $nick, $address, $target) = @_;
    $message =~ s/\x03(?:\d{1,2}(?:,\d{1,2})?)?//g;
    if ($message =~ /^!minipekka\s+([\w\-]+)/i) {
        # Extraemos el nick al que va dirigido el pase
        my $tarject_nick = $1;  
        # Verificar si el nick está en el canal
        my $found_nick = check_user_channel($server,$tarject_nick, $target);
        my $request= "$nick ha lanzado la carta del miniPEKKA contra $tarject_nick, por el camino va abriendo el apetito a la gente repitiendo 'pancakes'";
        send_request($server, $request, $target,$found_nick);
    }
    elsif ($message =~ /^!bola de fuego\s+([\w\-]+)/i) {
        # Extraemos el nick al que va dirigido el pase
        my $tarject_nick = $1;  
        # Verificar si el nick está en el canal
        my $found_nick = check_user_channel($server,$tarject_nick, $target);
        my $request= "$nick lanza una bola de fuego a $tarject_nick. El miedo te paraliza. 
Te golpea en la frente, destruyendo todo a tu alrededor y convirtiéndote en un pollo frito churruscado";
        send_request($server, $request, $target,$found_nick);
    }
    elsif ($message =~ /^!zap\s+([\w\-]+)/i) {
        # Extraemos el nick al que va dirigido el pase
        my $tarject_nick = $1;  
        # Verificar si el nick está en el canal
        my $found_nick = check_user_channel($server,$tarject_nick, $target);
        my $request= "$nick te lanza una descarga reiniciándote, $tarject_nick!";
        send_request($server, $request, $target,$found_nick);
    }
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'response');

