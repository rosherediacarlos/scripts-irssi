use strict;
use warnings;
use Irssi;

my %users_to_kick;  # Hash para almacenar usuarios que aún no han cambiado el nick

# Función para verificar si el nick parece genérico y dar un tiempo límite
sub check_generic_nick {
    my ($server, $channel, $nick, $address) = @_;
    
    # Patrón para detectar nicks que empiecen con 'invitado' o 'guest' y tengan números
    if ($nick =~ /^invitado\d*$/i || $nick =~ /^guest\d*$/i || $nick =~ /^invitado_\d*$/i) {
        # Envía un mensaje privado al usuario pidiéndole que cambie el nick
        $server->command("msg $channel hola $nick, por favor cambia el nick con /nick <nuevo_nick>.");
        
        # Guardar el usuario en la lista de usuarios pendientes de cambiar el nick
        $users_to_kick{$nick} = {
            server => $server,
            channel => $channel,
            timeout => Irssi::timeout_add_once(60000, sub {
                # Después de 2 minutos, verificar si el nick no ha cambiado
                if (exists $users_to_kick{$nick}) {
                    # Hacer el kick al usuario
                    $server->command("kick $channel $nick No cambiaste tu nick en el tiempo permitido.");
                    #Irssi::print("El usuario $nick ha sido expulsado del canal $channel por no cambiar su nick.");
                    delete $users_to_kick{$nick};  # Eliminar de la lista después del kick
                }
            }, [])
        };
 
    }
}

# Función que se llama cuando alguien cambia su nick
sub on_nick_change {
    my ($server, $newnick, $oldnick, $address) = @_;
    
    # Si el usuario estaba en la lista de pendientes y cambió su nick, cancelar el kick
    if (exists $users_to_kick{$oldnick}) {
        Irssi::timeout_remove($users_to_kick{$oldnick}{timeout});  # Cancelar el temporizador
        delete $users_to_kick{$oldnick};  # Eliminar de la lista
        $server->command("msg $newnick Gracias por cambiar tu nick.");
    }
}

# Vincular la función a los eventos de cuando alguien se une al canal y cuando cambia su nick
Irssi::signal_add('message join', 'check_generic_nick');
Irssi::signal_add('nick', 'on_nick_change');


