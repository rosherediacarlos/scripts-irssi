use strict;
use warnings;
use Irssi;

# Registra el script con irssi
#Irssi::script_register('mi_bot', '1.0', 'Bot simple de prueba');

# Función que se llama cuando alguien habla en el canal
sub respuesta {
    my ($servidor, $mensaje, $nick, $direccion, $target) = @_;
    
    if ($mensaje =~ /^!permisos$/i) {
        if ($nick =~ "error_404_" or $nick =~ "CoraIine"){
            
            $servidor->command("op $target $nick");
        }
        else{
            $servidor->command("msg $target buen intento campeon/a $nick!");
        }
    }
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'respuesta');

