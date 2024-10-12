package JuegoEstado;

my $juego_en_progreso = 0;

sub esta_en_progreso {
    return $juego_en_progreso;
}

sub iniciar {
    $juego_en_progreso = 1;
}

sub terminar {
    $juego_en_progreso = 0;
}

1;
# Codigo para usar el fichero y comprobar el estado
use JuegoEstado;

sub iniciar_juego {
    my ($server, $target) = @_;

    if (JuegoEstado::esta_en_progreso()) {
        $server->command("msg $target Ya hay un juego en curso.");
        return;
    }

    JuegoEstado::iniciar();
    $server->command("msg $target ¡El juego ha comenzado!");

    # Lógica del juego...

    JuegoEstado::terminar();
}
