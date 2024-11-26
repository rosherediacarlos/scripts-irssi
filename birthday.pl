use strict;
use warnings;
use Irssi;
use utf8;

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

# Convertir el código Unicode a un carácter
sub unicode_to_char {
    my ($unicode) = @_;
    return chr(hex($unicode));
}

# Función que se llama cuando alguien habla en el canal
sub response {
    my ($server, $message, $nick, $address, $target) = @_;
    $message =~ s/\x03(?:\d{1,2}(?:,\d{1,2})?)?//g;
    if ($message =~ /^!felicidades\s+([\w\-]+)/i) {
        # Extraemos el nick al que va dirigido el pase
        my $tarject_nick = $1;  
        # Verificar si el nick está en el canal
        my $found_nick = check_user_channel($server,$tarject_nick, $target);
        if ($found_nick){
            
            my $window = Irssi::active_win; 
            my $emoji_code = "1F973";  # Código Unicode sin "U+"
            my $emoji = unicode_to_char($emoji_code);
            my $request= "¡Cumpleaños feliz! ¡Cumpleaños feliz! ¡Te desean tus amigos desde aquí! $emoji";
            utf8::decode($request);
            $window->command("/me saca el reproductor de CDs y prepara el cd de música, para celebrar el cumpleaños de $tarject_nick");
            $server->command("msg $target $request");
        }
    }

}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'response');

