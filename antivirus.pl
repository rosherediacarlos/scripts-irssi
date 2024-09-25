use strict;
use warnings;
use Irssi;

sub respuesta {
    my ($servidor, $mensaje, $nick, $direccion, $target) = @_;

    if ($mensaje =~ /^!errores$/i) {
        my $canal_info = $servidor->channel_find($target);
            if ($canal_info) {
            my @usuarios = $canal_info->nicks();
            my @nicks_encontrados = map { $_->{nick} } 
                                grep { $_->{nick} =~ /error/i } 
                                @usuarios;
            if (@nicks_encontrados) {
                my $nicks_lista = join(', ', @nicks_encontrados);
                my $numero_erroes = scalar @nicks_encontrados;
                my $window = Irssi::active_win;  
                $window->command("me Ha encontrado $numero_erroes errores: $nicks_lista");
            }
        }

    }
    if ($mensaje =~ /^!virus$/i) {
            my $window = Irssi::active_win;  
            $window->command("me Analizando la sala de posibles virus");
            $window->command("me Se ha encontrado una amenaza. Eliminando...");
            $servidor->command("kick $target $nick Eliminando amenza!");
    }
}
Irssi::signal_add('message public', 'respuesta');
