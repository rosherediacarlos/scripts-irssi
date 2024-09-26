use strict;
use warnings;
use Irssi;
use List::Util 'shuffle';

# Hash para guardar el estado del jugador que debe disparar y su elección
my %waiting_shot;

# Función para manejar el comando !gol
sub start_shot {
    my ($server, $message, $nick, $address, $target) = @_;

    if ($message =~ /^!gol\s+(\w+)/i) {
        my $tarject_nick = $1;  # Extraemos el nick al que va dirigido el pase

        # Obtener información del canal
        my $channel_info = $server->channel_find($target);

        unless ($channel_info) {
            $server->command("msg $target No se puede obtener información del canal.");
            return;
        }

        # Verificar si el nick está en el canal
        my $found_nick = 0;
        foreach my $nick_info ($channel_info->nicks()) {
            if (lc($nick_info->{nick}) eq lc($tarject_nick)) {
                $found_nick = 1;
                last;
            }
        }

        if (!$found_nick) {
            $server->command("msg $target El nick '$tarject_nick' no se encuentra en el canal.");
            return;
        }

        # Enviar mensaje privado al jugador objetivo
        $server->command("msg $target Rapido $tarject_nick, $nick te ha pasado el balón. ¿A dónde quieres disparar? Responde con 'derecha', 'centro' o 'izquierda'.");

        # Guardar el estado del disparo pendiente
        $waiting_shot{lc($tarject_nick)} = {
            passer => $nick,
            channel => $target
        };
    }
}

# Función para manejar la elección del disparo del jugador
sub handle_shot_choice {
    my ($server, $message, $nick, $address, $target) = @_;

    # Verificar si el jugador está en la lista de espera para disparar
    if (exists $waiting_shot{lc($nick)}) {
        my $choice = lc($message);

        # Verificar si la elección es válida
        unless ($choice eq 'derecha' || $choice eq 'centro' || $choice eq 'izquierda') {
            $server->command("msg $nick Opción no válida. Por favor, elige 'derecha', 'centro' o 'izquierda'.");
            return;
        }

        # El portero elige aleatoriamente una dirección
        my @options = ('derecha', 'centro', 'izquierda');
        my $golkeaper_choise = $options[rand @options];

        # Obtener información del jugador que pasó el balón y el canal
        my $passer = $waiting_shot{lc($nick)}{passer};
        my $channel = $waiting_shot{lc($nick)}{channel};

        # Comparar la elección del jugador con la del portero
        my $result;
        if ($choice eq $golkeaper_choise) {
            $result = "¡El portero detuvo el disparo a la $choice!";
        } else {
            $result = "¡GOL en la $choice! El portero se lanzó a la $golkeaper_choise.";
        }

        # Anunciar el resultado en el canal
        $server->command("msg $channel El jugador $passer le pasó el balón a $nick. Resultado: $result");

        # Eliminar al jugador de la lista de espera
        delete $waiting_shot{lc($nick)};
    }
}

# Enlazar las señales para los comandos
Irssi::signal_add('message public', 'start_shot');
Irssi::signal_add('message public', 'handle_shot_choice');

