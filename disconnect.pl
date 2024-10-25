use strict;
use warnings;
use Irssi;

my @admin_nicks = ("error_404_","CoraIine", "luck", "Mai");

# Función que se llama cuando alguien habla en el canal
sub response {
    my ($server, $message, $nick, $address, $target) = @_;
    $message =~ s/\x03(?:\d{1,2}(?:,\d{1,2})?)?//g;
    if ($message =~ /^!desconectar$/i) {
        if (grep { $_ eq $nick } @admin_nicks){
            my $server = Irssi::active_server();
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

