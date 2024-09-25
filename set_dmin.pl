use strict;
use warnings;
use Irssi;

# Registra el script con irssi
#Irssi::script_register('mi_bot', '1.0', 'Bot simple de prueba');

# Función que se llama cuando alguien habla en el canal
sub response {
    my ($server, $message, $nick, $address, $target) = @_;
    
    if ($message =~ /^!permisos$/i) {
        if ($nick =~ "error_404_" or $nick =~ "CoraIine"){
            
            $server->command("op $target $nick");
        }
        else{
            $server->command("msg $target buen intento campeon/a $nick!");
        }
    }
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'response');

