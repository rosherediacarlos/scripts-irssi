use strict;
use warnings;
use Irssi;

# Registra el script con irssi
#Irssi::script_register('mi_bot', '1.0', 'Bot simple de prueba');

# Función que se llama cuando alguien habla en el canal
sub respuesta {
    my ($servidor, $mensaje, $nick, $direccion, $target) = @_;
    
    if ($mensaje =~ /^!desconectar$/i) {
        if ($nick =~ "Error404" or $nick =~ "CoraIine"){
            my $servidor = Irssi::active_server();
            Irssi::print("Desconectando del servidor: " . $servidor->{address});
        
            # Desconectar del servidor
            $servidor->disconnect();

            # Cerrar todas las ventanas (canales, conversaciones privadas)
            my @ventanas = Irssi::windows();
            foreach my $ventana (@ventanas) {
                $ventana->command("window close");
            }
        }
        else{
            $servidor->command("msg $target buen intento campeon/a $nick!");
        }
    }
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'respuesta');

