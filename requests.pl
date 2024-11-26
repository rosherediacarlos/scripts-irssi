use strict;
use warnings;
use Irssi;
use utf8;

# Convertir el código Unicode a un carácter
sub unicode_to_char {
    my ($unicode) = @_;
    return chr(hex($unicode));
}

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
    if ($message =~ /^!susto\s+([\w\-]+)/i) {
        # Extraemos el nick al que va dirigido el pase
        my $tarject_nick = $1;  
        # Verificar si el nick está en el canal
        my $found_nick = check_user_channel($server,$tarject_nick, $target);
        my $request= "$nick se pone la capa de invisibilidad para darle un susto de muerte a $tarject_nick!";
        send_request($server, $request, $target,$found_nick);
    }
    elsif ($message =~ /^!patata$/i) {
        my $found_nick = $nick;
        my $request= "A $nick casi le peta la patata del susto. ¡Estuvo a punto de convertirse en puré para la sala!";
        send_request($server, $request, $target, $found_nick);
    }
    elsif ($message =~ /^!zapatos\s+([\w\-]+)/i) {
        # Extraemos el nick al que va dirigido el pase
        my $tarject_nick = $1;  
        # Verificar si el nick está en el canal
        my $found_nick = check_user_channel($server,$tarject_nick, $target);

        my $emoji_code = "1F969";  # Código Unicode sin "U+"
        my $emoji = unicode_to_char($emoji_code);        
        my $request= "se acerca y le quita de las manos a $tarject_nick los zapatos regresándolos al lugar donde los guarda su dueña. Ahora va feliz por su premio $emoji.";
        utf8::decode($request);
        send_request($server, $request, $target,$found_nick);
    }
    elsif ($message =~ /^!vela\s+([\w\-]+)/i) {
        # Extraemos el nick al que va dirigido el pase
        my $tarject_nick = $1;  
        # Verificar si el nick está en el canal
        my $found_nick = check_user_channel($server,$tarject_nick, $target);
        my $emoji_code = "1F56F";  # Código Unicode sin "U+"
        my $emoji = unicode_to_char($emoji_code);        
        my $request= "colocare una cuantas velas rodeando a $emoji $emoji $tarject_nick $emoji $emoji!";
        utf8::decode($request);
        send_request($server, $request, $target,$found_nick);
    }   
    elsif ($message =~ /^!fantasmas$/i) {
        my $found_nick = $nick;
        my $emoji_code = "1F47B";  # Código Unicode sin "U+"
        my $emoji = unicode_to_char($emoji_code);       
        my $request= " $emoji $emoji $emoji $emoji $emoji";
        utf8::decode($request);
        
        my $window = Irssi::active_win; 
        $window->command("me llama a sus amigos");
    
        send_request($server, $request, $target,$found_nick);
    } 
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'response');

