use strict;
use warnings;
use Irssi;
use Data::Dumper;
use List::Util 'shuffle';

# Equipos iniciales
my @teams = (
    "Independiente", "Boca Juniors", "Peñarol", "River Plate", 
    "Estudiantes de La Plata", "Olimpia", "Nacional", "Sao Paulo", 
    "Palmeiras", "Santos", "Gremio", "Flamengo", 
    "Cruzeiro", "Internacional", "Atletico Nacional", "Colo-Colo"
);

# Partidos y resultados
my @matches = ();
# Para almacenar ganadores de cada ronda
my @round_winners = ();  
my $playing_cup = 0;
my $current_match_index = 0;
# 30 segundos
my $timeout_interval = 30000;  
my %result;
my $team_win;
my %rounds = (
    16 => 'Octavos',
    8 => 'Cuartos',
    4 => 'Semifinal',
    2 => 'Final',
);

# Función para votar por un equipo
sub vote_team {
    my ($server, $message, $nick, $target) = @_;
    my $team_name = lc($message);
    # Primera letra en mayúscula
    $team_name =~ s/\b(\w)/\U$1/g; 
    if (lc($message) eq 'peñarol'){
        $team_name = "Peñarol";
    }
    if (exists $result{$team_name}) {
        # Incrementar el contador de votos
        $result{$team_name}++; 
        my @match_teams = keys %result;
        my $string_result = "$match_teams[0] $result{$match_teams[0]} vs $match_teams[1] $result{$match_teams[1]}"; 
        $server->command("msg $target !GOL! para $team_name. El partido va $string_result");
    } else {
        $server->command("msg $target $nick. $team_name no está jugando el partido.");
    }
}

# Función para obtener el equipo ganador
sub get_win_team {
    my $max_votes = -1;
    my @most_voted_teams;

    while (my ($team_name, $votes) = each %result) {
        if ($votes > $max_votes) {
            $max_votes = $votes;
            # Nuevo equipo con más votos
            @most_voted_teams = ($team_name);  
        } elsif ($votes == $max_votes) {
            # Empate, agregar equipo
            push(@most_voted_teams, $team_name);  
        }
    }

    # Si hay más de un equipo empatado, se elige uno aleatorio
    if (@most_voted_teams > 1) {
        @most_voted_teams = shuffle(@most_voted_teams);
    }
    
    # Ganador final del partido
    $team_win = $most_voted_teams[0];
}

# Función para iniciar los partidos de una ronda
sub start_matches {
    my ($server, $nick, $target) = @_;
    start_single_match($server, $nick, $target);
}

# Iniciar un partido individual
sub start_single_match {
    my ($server, $nick, $target) = @_;
    # Reiniciar resultados del partido
    %result = ();  

    if ($current_match_index < @matches) {
        my $match = $matches[$current_match_index];
        my $string_match = join(" vs ", @{$match});
        %result = (
            @{$match}[0] => 0,
            @{$match}[1] => 0,
        );
        $server->command("msg $target \x0302Partido número " . ($current_match_index + 1) . ": \x02$string_match\x02 comienza. ¡Voten por el equipo ganador (30 segundos)!\x0302");
        $current_match_index++;
        start_timer($server, $nick, $target);
    } else {
        if (@round_winners > 1) {
            # Obtener la ronda actual
            my $remaining_teams = scalar @round_winners;
            my $round = string_round($remaining_teams);
            $server->command("msg $target \x0303La ronda ha terminado. Emparejando los ganadores para \x02$round.\x02\x0303");
            @matches = ();
            # Los ganadores pasan a la siguiente ronda
            @teams = @round_winners; 
            # Imprimir los ganadores
            my $string_winers = join(", ",@teams);
            $server->command("msg $target \x02\x0301Equipos que pasan de ronda son:\x0301 \x0302$string_winers\x0302\x02");
            # Reiniciar ganadores para la nueva ronda 
            @round_winners = ();  
            $current_match_index = 0;
            draw_pairings();
            #print_draw_pairings($server, $target);
            start_matches($server, $nick, $target);
        } else {
            # Ya tenemos un único ganador
            my $team_winner = $round_winners[0];
            $server->command("msg $target \x0303¡El campeón de la Copa Libertadores es \x02$team_winner\x02\x0303!");
            reset_tournament();
        }
    }
}

sub string_round{
    my ($number_of_teams) = @_;
    
    my $round_name = $rounds{$number_of_teams};
    # Determinar el artículo correcto según la ronda
    my $round;
    if ($number_of_teams == 2 || $number_of_teams == 4) {
        # "La Final" o "La Semifinal"
        $round = "La $round_name";  
    } else {
        # "Los Octavos" o "Los Cuartos"
        $round = "Los $round_name";  
    }
    return $round;
}

# Iniciar temporizador para votar
sub start_timer {
    my ($server, $nick, $target) = @_;
    
    Irssi::timeout_add_once($timeout_interval, sub {
        get_win_team();
        # Agregar el ganador a la lista de ganadores de la ronda
        push(@round_winners, $team_win);  
        my @match_teams = keys %result;
        my $string_result = "El partido ha terminado: $match_teams[0] $result{$match_teams[0]} vs $match_teams[1] $result{$match_teams[1]}. El ganador es $team_win!";
        $server->command("msg $target $string_result");
        start_single_match($server, $nick, $target);
    }, undef);
}

# Emparejar equipos para la ronda
sub draw_pairings {
    # Barajar equipos
    @teams = shuffle(@teams);  
    @matches = ();

    while (@teams >= 2) {
        # Emparejar dos equipos
        my @match = splice(@teams, 0, 2);  
        push(@matches, [@match]);
    }

    if (@teams == 1) {
        # Si hay un equipo sin rival, pasa automáticamente a la siguiente ronda
        push(@round_winners, shift @teams);
    }
}

sub print_draw_pairings {
    my ($server, $target) = @_;
    my $complete_message = '';
    my $change_color;  
    foreach my $match (@matches) {
        my $string_match = join(" vs ", @{$match});
        if ($change_color) {
            $complete_message .= "\x02\x0302$string_match\x02\x0302. ";
            $change_color = 0;
        } else {
            $complete_message .= "\x02\x0312$string_match\x02\x0312. ";
            $change_color = 1;
        }
    }

    $server->command("msg $target $complete_message");
}

sub reset_tournament {
    # Reinicia todas las variables del torneo
    @teams = (
        "Independiente", "Boca Juniors", "Peñarol", "River Plate", 
        "Estudiantes de La Plata", "Olimpia", "Nacional", "Sao Paulo", 
        "Palmeiras", "Santos", "Gremio", "Flamengo", 
        "Cruzeiro", "Internacional", "Atlatico Nacional", "Colo-Colo"
    );
    # Reinicia los emparejamientos
    @matches = ();   
    # Reinicia los ganadores de las rondas        
    @round_winners = ();
    # Permite iniciar un nuevo torneo     
    $playing_cup = 0;    
    # Reinicia el índice del partido actual    
    $current_match_index = 0; 
    # Limpia los resultados
    %result = ();            
}


# Iniciar el torneo de la Copa Libertadores
sub start_libertadores_cup {
    my ($server, $message, $nick, $address, $target) = @_;

    if ($message =~ /^!copa libertadores (\d+)/i) {
        my $num_teams = $1;

        if (!$playing_cup && ($num_teams == 2 || $num_teams == 4 || $num_teams == 8 || $num_teams == 16)) {
            # Barajar equipos
            @teams = shuffle(@teams);  
            # Cortar la lista de equipos
            @teams = splice(@teams, 0, $num_teams);  
            draw_pairings();
            $playing_cup = 1;
            my $round = string_round($num_teams);
            $server->command("msg $target \x02\x0301¡El sorteo para los partidos de $round está listo!\x02\x0301");
            
            print_draw_pairings($server, $target);
            start_matches($server, $nick, $target);
        } else {
            $server->command("msg $nick Por favor, elige 2, 4, 8 o 16 equipos.");
        }
    } elsif ($message =~ /^!fin copa/i) {
        $playing_cup = 0;
        $server->command("msg $target La Copa Libertadores ha sido interrumpida.");
    } elsif ($playing_cup) {
        vote_team($server, $message, $nick, $target);
    }
}

Irssi::signal_add('message public', 'start_libertadores_cup');
