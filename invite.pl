$VERSION = "1.0";
%IRSSI = (
    authors     => 'Tu Nombre',
    contact     => 'tuemail@example.com',
    name        => 'auto_invite',
    description => 'Detecta cuando un usuario se conecta y lo invita automáticamente a un canal.',
    license     => 'Public Domain',
);

# Configura el canal al que quieres invitar al usuario
my $invite_channel = "#prueba-test";

# Función que se ejecuta cuando un usuario se une a la red
sub detect_user_connect {
    my ($server, $channel, $nick, $address) = @_;
    
    # Evita que el script se ejecute para ti mismo
    return if ($nick eq $server->{nick});
    
    # Invitar al usuario al canal configurado
    $server->command("invite $nick $invite_channel");
    
    # Mensaje de log para saber que el script ha invitado al usuario
    Irssi::print("Invitado $nick al canal $invite_channel");
}

# Vincular el script al evento de 'join' (cuando un usuario se conecta a la sala)
Irssi::signal_add("message join", "detect_user_connect");
