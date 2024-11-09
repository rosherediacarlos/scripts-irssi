use strict;
use warnings;
use Irssi;
use List::Util 'shuffle';

# Variables del juego
my $host_player;                # Jugador anfitrión
my $lives = 7;                  # Número total de vidas
my $current_lives = $lives;     # Número de vidas restantes
my $secret_word;                # Palabra secreta
my $guessed_letters = '';       # Letras adivinadas
my $channel = "#hotelfantasma"; # Sala para jugar
#my $channel = "#prueba-test"; # Sala para pruebas

# Función para iniciar el juego
sub hangman_game {
    my ($server, $message, $nick, $address, $target) = @_;
    $message =~ s/\x03(?:\d{1,2}(?:,\d{1,2})?)?//g;

    # Iniciar juego con !ahorcado <palabra>
    if ($message =~ /^!ahorcado\s+(\w+)/i) {
        if ($secret_word) {
            $server->command("msg $nick El juego ya está en marcha.");
            return;
        }
        
        # Limpiar variables antes de empezar el juego
        $secret_word = lc $1;    # Guardar en minúsculas para facilitar comparaciones
        $guessed_letters = '';   # Letras adivinadas reiniciadas
        $host_player = $nick;    # Jugador que inició el juego
        $current_lives = $lives; # Reiniciar vidas
        print($secret_word);
        $server->command("msg $channel $nick ha iniciado el juego del ahorcado. (Usa el comando !letra <letra> para probar con una letra o !resolver <palabra> para intentar resolver la palabra.)");
    }
}

# Función para cancelar el juego
sub cancel_game {
    my ($server, $target) = @_;
    $secret_word = "";
    $host_player = "";
    $current_lives = $lives;
    $guessed_letters = '';
    $server->command("msg $target El juego ha sido cancelado.");
}

# Función para manejar las opciones de usuario (adivinanzas de letras o palabras)
sub hangman_game_check_user_option {
    my ($server, $message, $nick, $address, $target) = @_;
    $message =~ s/\x03(?:\d{1,2}(?:,\d{1,2})?)?//g;

    # Verificar si el juego está activo
    if ($secret_word && $message) {
        # Intento de resolver la palabra completa
        if ($message =~ /^!resolver\s+(.+)/i) {
            my $guess = lc $1;
            if ($guess eq $secret_word) {
                $server->command("msg $target \x0303¡$nick ha acertado la palabra secreta '$secret_word'! ¡Felicidades!\x0303");
                cancel_game($server, $target);
            } else {
                $current_lives--;
                $server->command("msg $target \x0304Incorrecto. Os quedan $current_lives vidas.\x0304");
                check_game_status($server, $target);
            }
        }

        # Intento de adivinar una letra
        if ($message =~ /^!letra\s+(\w)/i) {
            my $letter = lc $1;
            
            # Verificar si la letra ya fue adivinada
            if (index($guessed_letters, $letter) != -1) {
                $server->command("msg $target $nick, ya habeis intentado con la letra '$letter'.");
                return;
            }

            # Agregar letra a las letras adivinadas
            $guessed_letters .= $letter;

            # Verificar si la letra está en la palabra secreta
            if (index($secret_word, $letter) != -1) {
                $server->command("msg $target $nick, ¡la letra '$letter' está en la palabra!");
            } else {
                $current_lives--;
                $server->command("msg $target $nick, la letra '$letter' no está en la palabra. Os quedan $current_lives vidas.");
            }

            # Mostrar el estado actual de la palabra con letras acertadas y asteriscos
            my $display_word = get_display_word();
            $server->command("msg $target Progreso: $display_word");

            # Verificar si el juego ha terminado
            check_game_status($server, $target);
        }
    }
}

# Función para mostrar letras acertadas y asteriscos para las no adivinadas
sub get_display_word {
    my $display = '';
    foreach my $char (split //, $secret_word) {
        if (index($guessed_letters, $char) != -1) {
            $display .= $char;
        } else {
            $display .= '*';
        }
    }
    return $display;
}

# Verificar el estado del juego y finalizar si es necesario
sub check_game_status {
    my ($server, $target) = @_;

    # Si no quedan vidas
    if ($current_lives <= 0) {
        $server->command("msg $target \x0304¡Juego terminado! Habéis perdido. La palabra era '$secret_word'.\x0304");
        cancel_game($server, $target);
    }
    # Si todas las letras han sido adivinadas
    elsif (get_display_word() !~ /\*/) {
        $server->command("msg $target \x0303¡Felicidades! Has adivinado la palabra secreta '$secret_word'.\x0303");
        cancel_game($server, $target);
    }
}

# Enlazar las señales 'message private' y 'message public' a las funciones correspondientes
Irssi::signal_add('message private', 'hangman_game');
Irssi::signal_add('message public', 'hangman_game_check_user_option');
