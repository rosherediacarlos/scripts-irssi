use strict;
use warnings;
use Irssi;

# Registra el script con irssi
#Irssi::script_register('mi_bot', '1.0', 'Bot simple de prueba');

# Función que se llama cuando alguien habla en el canal
sub respuesta {
    my ($servidor, $mensaje, $nick, $direccion, $target) = @_;
    Irssi::print("mensaje: $mensaje");
    if ($mensaje =~ /^!adios$/i) {
        # Envía un mensaje de respuesta al canal donde se envió el comando
        $servidor->command("msg $target Hasta la proxima, $nick!");
    }
    if ($mensaje =~ /^!bye$/i) {
        # Envía un mensaje de respuesta al canal donde se envió el comando
        $servidor->command("msg $target Reproduciré bye bye bye, mientras $nick se marcha moviendo el esqueleto");
    }
    if ($mensaje =~ /^!au revoir$/i or $mensaje =~ /^!Mon dieu$/i) {
        # Envía un mensaje de respuesta al canal donde se envió el comando
        $servidor->command("kick $target $nick Franceses los justos!");
        $servidor->command("msg $target Franceses los justos!");
    }
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'respuesta');

