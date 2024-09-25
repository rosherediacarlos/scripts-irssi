use strict;
use warnings;
use Irssi;

# Función que se llama cuando alguien habla en el canal
sub response {
    my ($server, $message, $nick, $address, $target) = @_;
    
    if ($message =~ /^!desconectar$/i) {
        if ($nick =~ "error_404_" or $nick =~ "CoraIine"){
            my $server = Irssi::active_server();
            Irssi::print("Desconectando del servidor: " . $server->{address});
        
            # Desconectar del servidor
            $server->disconnect();

            # Cerrar todas las ventanas (canales, conversaciones privadas)
            my @windows = Irssi::windows();
            foreach my $window (@windows) {
                $window->command("window close");
                
            }
            $server->command("/quit");
        }
        else{
            $server->command("msg $target buen intento campeon/a $nick!");
        }
    }
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'response');

