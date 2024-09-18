use strict;
use warnings;
use Irssi;
use Data::Dumper;

# Lista global para almacenar los animales que ya se han usado
my %animales_usados;

# Función que se llama cuando alguien envía un mensaje público
sub buscar_nick_por_animal {
    my ($servidor, $mensaje, $nick, $direccion, $target) = @_;

    # Verifica si el mensaje es el comando !animal
    if ($mensaje =~ /^!animal\s+(\w+)/i) {
        my $animal = lc($1);  # Convertir a minúsculas para consistencia

        # Verificar si el animal ya fue utilizado
        if (exists $animales_usados{$animal}) {
            $servidor->command("msg $target El animal '$animal' ya ha sido utilizado, por favor elige otro.");
            return;
        }

        # Asegúrate de que el animal tenga al menos 3 letras
        if (length($animal) < 3) {
            $servidor->command("msg $target El nombre del animal debe tener al menos 3 letras.");
            return;
        }

        # Obtén la tercera letra del nombre del animal
        my $tercera_letra = substr($animal, 2, 1);

        # Obtener información del canal
        my $canal_info = $servidor->channel_find($target);

        # Si el canal no existe
        unless ($canal_info) {
            $servidor->command("msg $target No se puede obtener información del canal.");
            return;
        }

        # Recorre la lista de nicks en el canal
        foreach my $nick_info ($canal_info->nicks()) {
            my $nombre_nick = lc($nick_info->{nick});

            # Verifica si el nick tiene al menos 3 caracteres y si la tercera letra coincide
            if (length($nombre_nick) >= 3 && substr($nombre_nick, 2, 1) eq $tercera_letra) {
                # Añadir el animal a la lista de usados
                $animales_usados{$animal} = 1;

                # Enviar mensaje al canal
                $servidor->command("msg $target El siguiente nick con la tercera letra '$tercera_letra' es: $nombre_nick");
                return;
            }
        }

        # Si no se encuentra ningún nick con esa tercera letra
        $servidor->command("msg $target No se encontró ningún nick con la tercera letra '$tercera_letra'.");
    }
}

Irssi::command_bind('reset_animales_usados', sub {
    %animales_usados = ();  # Vacía el hash
    Irssi::print("La lista de animales usados ha sido reseteada.");
});

# Enlazar la señal 'message public' a nuestra función
Irssi::signal_add('message public', 'buscar_nick_por_animal');

Irssi::print("Script de bot de animal con verificación de animales usados cargado.");
