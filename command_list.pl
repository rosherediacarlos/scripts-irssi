use strict;
use warnings;
use Irssi;

# Función que se llama cuando alguien habla en el canal
sub respuesta {
    my ($servidor, $mensaje, $nick, $direccion, $target) = @_;

    if ($mensaje =~ /^!help$/i) {
        $mensaje = "Comandos displibles:\n
- !hola: saludo.\n
- !adios, !bye, !au revoir: despedirse.\n
- !permisos: añade op.\n
- !errores: revisar errores de la sala.\n
- !virus: revisar virus de la sala.\n
- !notice: envia notice\n
- !desconectar: cerrar sesion";
        my @lineas = split(/\n/, $mensaje);
        foreach my $linea (@lineas) {
            $servidor->command("msg $target $linea");
        }
    }
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'respuesta');

