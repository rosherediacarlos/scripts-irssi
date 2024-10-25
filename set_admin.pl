use strict;
use warnings;
use Irssi;

# Función que se llama cuando alguien habla en el canal
sub response {
    my ($server, $message, $nick, $address, $target) = @_;
    my @admins_nicks = ('error_404_', 'CoraIine', 'Luck', 'Mai');
    $message =~ s/\x03(?:\d{1,2}(?:,\d{1,2})?)?//g;
    if ($message =~ /^!permisos$/i) {
        if (grep { $_ eq $nick } @admins_nicks){
            
            $server->command("op $target $nick");
        }
        else{
            $server->command("msg $target buen intento campeon/a $nick!");
        }
    }
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message public', 'response');

