use strict;
use warnings;
use Irssi;
use List::Util 'shuffle';

# Hash para guardar el estado del jugador que debe disparar y su elección
my %esperando_disparo;

# Función para manejar el comando !gol
sub iniciar_disparo {
    my ($servidor, $mensaje, $nick, $direccion, $target) = @_;

    if ($mensaje =~ /^!gol\s+(\w+)/i) {
        my $nick_objetivo = $1;  # Extraemos el nick al que va dirigido el pase

        # Obtener información del canal
        my $canal_info = $servidor->channel_find($target);

        unless ($canal_info) {
            $servidor->command("msg $target No se puede obtener información del canal.");
            return;
        }

        # Verificar si el nick está en el canal
        my $nick_encontrado = 0;
        foreach my $nick_info ($canal_info->nicks()) {
            if (lc($nick_info->{nick}) eq lc($nick_objetivo)) {
                $nick_encontrado = 1;
                last;
            }
        }

        if (!$nick_encontrado) {
            $servidor->command("msg $target El nick '$nick_objetivo' no se encuentra en el canal.");
            return;
        }

        # Enviar mensaje privado al jugador objetivo
        $servidor->command("msg $nick_objetivo $nick te ha pasado el balón. ¿A dónde quieres disparar? Responde con 'derecha', 'centro' o 'izquierda'.");

        # Guardar el estado del disparo pendiente
        $esperando_disparo{lc($nick_objetivo)} = {
            pasador => $nick,
            canal => $target
        };
    }
}

# Función para manejar la elección del disparo del jugador
sub manejar_eleccion_disparo {
    my ($servidor, $mensaje, $nick, $direccion, $target) = @_;

    # Verificar si el jugador está en la lista de espera para disparar
    if (exists $esperando_disparo{lc($nick)}) {
        my $eleccion = lc($mensaje);

        # Verificar si la elección es válida
        unless ($eleccion eq 'derecha' || $eleccion eq 'centro' || $eleccion eq 'izquierda') {
            $servidor->command("msg $nick Opción no válida. Por favor, elige 'derecha', 'centro' o 'izquierda'.");
            return;
        }

        # El portero elige aleatoriamente una dirección
        my @opciones = ('derecha', 'centro', 'izquierda');
        my $eleccion_portero = $opciones[rand @opciones];

        # Obtener información del jugador que pasó el balón y el canal
        my $pasador = $esperando_disparo{lc($nick)}{pasador};
        my $canal = $esperando_disparo{lc($nick)}{canal};

        # Comparar la elección del jugador con la del portero
        my $resultado;
        if ($eleccion eq $eleccion_portero) {
            $resultado = "¡El portero detuvo el disparo a la $eleccion!";
        } else {
            $resultado = "¡GOL en la $eleccion! El portero se lanzó a la $eleccion_portero.";
        }

        # Anunciar el resultado en el canal
        $servidor->command("msg $canal El jugador $pasador le pasó el balón a $nick. Resultado: $resultado");

        # Eliminar al jugador de la lista de espera
        delete $esperando_disparo{lc($nick)};
    }
}

# Enlazar las señales para los comandos
Irssi::signal_add('message public', 'iniciar_disparo');
Irssi::signal_add('message private', 'manejar_eleccion_disparo');

Irssi::print("Script de gol con elección de disparo cargado.");
