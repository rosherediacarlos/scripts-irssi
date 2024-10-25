use strict;
use warnings;
use Irssi;

my $channel = "#hotelfantasma";

# Función que se llama cuando alguien habla en el canal
sub response {
    my ($server, $message, $nick, $address, $target) = @_;
    $message =~ s/\x03(?:\d{1,2}(?:,\d{1,2})?)?//g;
    if ($message =~ /^!mariposa$/i) {
        if ($nick eq "error_404_"){
            my $chanel_info = $server->channel_find($channel);
            if ($chanel_info) {
            my @users = $chanel_info->nicks();
            my @found_nicks = map { $_->{nick} } 
                                grep { $_->{nick} =~ /CoraIine/i } 
                                @users;
                
                if (@found_nicks) { 
                    
                    my $list_nicks = join(', ', @found_nicks);
                    my $window = Irssi::active_win;  
                    $window->command("/msg $list_nicks Observa la mariposa $list_nicks volar libre por sala con sus preciosas alas");
                }
            }
        }elsif ($nick =~ "CoraIine"){
            my $chanel_info = $server->channel_find($channel);
            if ($chanel_info) {
            my @users = $chanel_info->nicks();
            my @found_nicks = map { $_->{nick} } 
                                grep { $_->{nick} =~ /error_404_/i } 
                                @users;
                
                if (@found_nicks) { 
                    
                    my $list_nicks = join(', ', @found_nicks);
                    my $window = Irssi::active_win;  
                    $window->command("/msg $list_nicks Se posa sobre los labios y de la unos USB a su hello world  $list_nicks");
                }
            }
        }
    }
    
    if ($message =~ /^!notice$/i) {
        
        my @phrases = ('Todavía no estoy programado para "Bailar" pero me han dicho que lo haces muy bien.',
            'Tienes permisos especiales en mi código.',
            'Ojalá Carlos fuera un blog para que le visitaras todos los días.',
            'El .gif que anima la vida de Carlos.',
            'Quisiera ser teclado para que me tocaras con tus manitas. Pero mi dueño se pondría celoso XD',
            'Eres como Google tienes todo lo que mi dueño busca.');
            
        my $random_index = int(rand(scalar @phrases));
        my $random_phrase = $phrases[$random_index];
        
        if ($nick =~ "CoraIine"){
            
            $server->command("notice $nick $random_phrase");
        }
        elsif ($nick =~ "error_404_"){
            my $channel_info = $server->channel_find($target);
            if ($channel_info) {
                my @users = $channel_info->nicks();
                my @found_nicks = map { $_->{nick} } 
                                    grep { $_->{nick} =~ /CoraIine/i } 
                                    @users;
                if (@found_nicks) {
                    $server->command("notice CoraIine $random_phrase");
                }
            }
        }
        else{
            $server->command("msg $target buen intento campeon/a $nick!");
        }
    }
}

# Enlaza el evento de recibir un mensaje público con la función respuesta
Irssi::signal_add('message private', 'response');

