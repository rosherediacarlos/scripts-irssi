use strict;
use warnings;
use Irssi;

# Hash para almacenar los estados de hackeo pendientes
my %pending_hacks;

# Función para manejar el comando !hack
sub hack_command {
    my ($server, $msg, $nick, $address, $channel) = @_;
    $msg =~ s/\x03(?:\d{1,2}(?:,\d{1,2})?)?//g;
    my @split_msg = split(' ', $msg);
    my $hack_nick = $split_msg[-1];
    
    if ($msg =~ /^!hack\s+([\w\-]+)/i) {
        # Verifica que el nick esté presente
        unless ($nick) {
            $server->command("msg $channel Uso: !hack <nick>");
            return;
        }

        # Verifica si el hackeo ya está en proceso
        if (exists $pending_hacks{$hack_nick}) {
            $server->command("msg $channel $nick, ya estás en proceso de hackeo. Por favor, elige una opción.");
            return;
        }

        # Almacena el estado del hackeo
        $pending_hacks{$hack_nick} = 1;

        # Envía un mensaje al canal solicitando la elección
        $server->command("msg $channel $hack_nick Estas siendo hackeado por $nick, elige una opción: vpn, antivirus, firewall (Solo escribe en la sala la opcion elegida) Para defenderte del hackeo.");
    }
}

# Función para manejar los mensajes en el canal
sub handle_message {
    my ($server, $msg, $nick, $address, $channel) = @_;
    
    
    # Verifica si el mensaje es una respuesta a un hackeo pendiente
    if (exists $pending_hacks{$nick}) {
        my $message = lc($msg);  # Convertir a minúsculas para la comparación
        
        # Opciones disponibles
        my %valid_options = (
            'vpn'       => 1,
            'antivirus' => 1,
            'firewall'  => 1
        );
        my @keys = keys %valid_options;
        my $correct_defense = $keys[rand @keys];

        # Verifica la opción seleccionada
        if (exists $valid_options{$message}) {
            # Elimina el hackeo pendiente
            delete $pending_hacks{$nick};
            
            # Simula el resultado del hackeo
            if ($correct_defense =~ $message) {
                $server->command("msg $channel $nick has podido defenderte del hackeo con un/una $message");
            } else {
                # Generar IP aleatoria 
                my $ip = join('.', map { int(rand(256)) } 1..4);
                # Longitud de la contraseña
                my $length = 12;

                # Conjunto de caracteres para la contraseña
                my @chars = ('A'..'Z', 'a'..'z', 0..9, qw(! @ $ % ^ & *));
                # Generar contraseña aleatoria
                my $password = '';
                $password .= $chars[rand @chars] for 1..$length;
                $server->command("msg $channel $nick No has podido defenderte del hackeo con el $message");
                $server->command("msg $channel \x02\x0304Hackeo Completado.\x02\x0304");
                $server->command("msg $channel \x02Datos obtenidos. Nick:\x02 $nick, \x02IP:\x02 $ip, \x02Contraseña:\x02 $password");
            }
        } else {
            $server->command("msg $channel $nick, opción inválida. Por favor, elige entre vpn, antivirus, firewall.");
        }
    }
}

# Enlaza el comando !hack con la función
Irssi::signal_add('message public', 'hack_command');

# Enlaza el evento de recibir mensajes con la función handle_message
Irssi::signal_add('message public', 'handle_message');
