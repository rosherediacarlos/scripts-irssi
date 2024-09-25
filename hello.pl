use strict;
use warnings;
use Irssi;

# Función que se llama cuando alguien habla en el canal
sub response {
    my ($server, $message, $nick, $address, $target) = @_;

    if ($message =~ /^!hola$/i) {
        # Envía un mensaje de respuesta al canal donde se envió el comando
        $server->command("msg $target Hola, $nick!");
    }
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'response');

