my @admin_nicks = ("error_404_","CoraIine", "luck", "Mai");

sub restart_bot_tmux {
    Irssi::print("Restarting Irssi via tmux...");
    
    # Ejecuta un comando de sistema que reinicia la sesión de tmux donde se ejecuta irssi
    # Reemplaza 'irssi' con el nombre de tu sesión si es diferente
    Irssi::command("exec tmux kill-session -t irssi && tmux new-session -d -s irssi /usr/bin/irssi");
}

# Función que maneja el comando !restartbot en el canal
sub handle_restart_command {
    my ($server, $message, $nick, $address, $target) = @_;
    
    # Eliminar códigos de color si es necesario
    $message =~ s/\x03(?:\d{1,2}(?:,\d{1,2})?)?//g;

    if ($message =~ /^!restartbot\b/i) {
        if (grep { $_ eq $nick } @admin_nicks){
            # Llamar a la función que reinicia el bot en tmux
            restart_bot_tmux();
            $server->command("msg $target Restarting Irssi bot via tmux...");
        }
    }
}

# Vincular el comando al evento de mensajes públicos
Irssi::signal_add('message public', 'handle_restart_command');
Irssi::signal_add('message private', 'handle_restart_command');
