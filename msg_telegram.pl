use strict;
use warnings;
use Irssi;
use LWP::UserAgent;
use JSON;
use Irssi::Irc;

# Configuración de Telegram
my $bot_token = '7531069061:AAGXjkY9QmLfvVdHkt_S7KdI9lqF2PKJ4RU';   # Reemplaza con el token de tu bot de Telegram
my $chat_id = '1718911779';               # Reemplaza con el ID de tu chat de Telegram
my $api_url = "https://api.telegram.org/bot$bot_token";

my $send_message = 0;
my $tlg_message = "";

# Instancia de LWP::UserAgent para hacer solicitudes HTTP
my $ua = LWP::UserAgent->new;

# Función para enviar mensajes a Telegram
sub send_to_telegram {
    my ($message) = @_;
    
    my $response = $ua->post("$api_url/sendMessage", [
        'chat_id' => $chat_id,
        'text'    => $message,
        'parse_mode' => 'Markdown',
    ]);

    if ($response->is_success) {
        Irssi::print("Mensaje enviado a Telegram");
    } else {
        Irssi::print("Error al enviar mensaje a Telegram: " . $response->status_line);
    }
}

# Función para manejar el comando !tlg en Irssi
sub handle_tlg_command {
    my ($server, $msg, $nick, $address, $target) = @_;

    if ($msg =~ /^!tlg\s+(.+)/) {
        my $message = $1;
        $send_message = 1;
        # Envia el mensaje a Telegram con el texto solicitado
        #send_to_telegram("Mensaje de $nick: $message");
        $tlg_message = "\n*Mensaje:* $message";
        # Ejecuta /whois para obtener IP o hostname
        $server->command("whois $nick");
    }
}

# Captura la respuesta del comando whois (event 311)
Irssi::signal_add("event 311", sub {
    my ($server, $data) = @_;
    my (undef, $nick, $user, $host) = split(" ", $data);
    if ($send_message){

        $tlg_message = "*Nick:* $nick \n*IP/Host:* $host" . $tlg_message;
        # Envia el host/IP a Telegram
        send_to_telegram($tlg_message);
        $send_message = 0;
        $tlg_message = "";
    }
    
});

# Enlaza el comando !tlg a la función handle_tlg_command
Irssi::signal_add('message private', 'handle_tlg_command');

#Irssi::print("Bot de Telegram cargado. Usa !tlg <mensaje> para enviar mensajes a Telegram.");
