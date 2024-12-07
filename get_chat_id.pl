use LWP::UserAgent;
use JSON;


# Reemplaza con el token de tu bot de Telegram
my $bot_token = '7531069061:AAGXjkY9QmLfvVdHkt_S7KdI9lqF2PKJ4RU';  
my $api_url = "https://api.telegram.org/bot$bot_token/getUpdates";

# Instanciamos el objeto LWP::UserAgent para hacer solicitudes HTTP
my $ua = LWP::UserAgent->new;
my $response = $ua->get($api_url);

# Comprobamos si la solicitud fue exitosa
if ($response->is_success) {
    my $content = $response->decoded_content;
    my $updates = decode_json($content);

    # Itera sobre las actualizaciones y extrae el chat_id
    for my $update (@{$updates->{result}}) {
        if ($update->{message}) {
            my $chat_id = $update->{message}{chat}{id};
            my $from = $update->{message}{from}{first_name};
            print "Chat ID: $chat_id - Mensaje de: $from\n";
        }
    }
} else {
    print "Error al obtener mensajes: " . $response->status_line . "\n";
}
