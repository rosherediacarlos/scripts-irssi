#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use MIME::Base64;
use Irssi;
use utf8;         # Para que Perl interprete correctamente las cadenas UTF-8 en el código fuente
use open ':std', ':encoding(UTF-8)';   # Asegura que la entrada/salida también sea en UTF-8
use Encode;       # Para manejar la conversión de codificación si es necesario
use Time::Piece;

# Archivo de credenciales y configuración
my $SERVICE_ACCOUNT_FILE = '/home/pi/.irssi/scripts/autorun/irssi-bot-ip-eecc7ce36b17.json';
my $SPREADSHEET_ID = '1vHzX9Ii4s5a7IzECcoQtobZB69-E2KggXTVszfIUjb4';
my $SHEET_NAME = 'Sheet1';

# Leer el archivo de credenciales JSON
sub read_service_account_file {
    my $file = shift;
    open my $fh, '<', $file or die "No se puede abrir el archivo $file: $!";
    local $/;
    my $json_text = <$fh>;
    close $fh;
    return decode_json($json_text);
}

# Generar un token JWT para autenticar las solicitudes
sub generate_jwt {
    my $credentials = shift;
    my $header = encode_base64('{"alg":"RS256","typ":"JWT"}', '');
    my $now = time();
    my $expiry = $now + 3600;
    my $claim_set = {
        iss => $credentials->{client_email},
        scope => 'https://www.googleapis.com/auth/spreadsheets',
        aud => $credentials->{token_uri},
        exp => $expiry,
        iat => $now,
    };
    my $claims = encode_base64(encode_json($claim_set), '');
    my $signing_input = "$header.$claims";

    # Firmar el JWT con la clave privada
    use Crypt::OpenSSL::RSA;
    my $rsa = Crypt::OpenSSL::RSA->new_private_key($credentials->{private_key});
    $rsa->use_sha256_hash();
    my $signature = encode_base64($rsa->sign($signing_input), '');

    return "$signing_input.$signature";
}

# Obtener un token de acceso utilizando el JWT
sub get_access_token {
    my $jwt = shift;
    my $ua = LWP::UserAgent->new;
    my $response = $ua->post(
        'https://oauth2.googleapis.com/token',
        {
            grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            assertion  => $jwt,
        }
    );

    die "Error obteniendo el token de acceso: " . $response->status_line
        unless $response->is_success;

    my $data = decode_json($response->decoded_content);
    return $data->{access_token};
}

# Insertar datos en la hoja de Google Sheets
sub insert_data {
    my ($access_token,$nick_complete, $nick, $ip, $description, $formatted_date) = @_;

    my $ua = LWP::UserAgent->new;
    my $url = "https://sheets.googleapis.com/v4/spreadsheets/$SPREADSHEET_ID/values/$SHEET_NAME:append?valueInputOption=RAW&insertDataOption=INSERT_ROWS";
    
    # Crear los nuevos datos a insertar
    my @new_data = ($nick_complete,$nick, $ip, $description, $formatted_date);

    my $body = encode_json({ values => [\@new_data] });

    my $response = $ua->post(
        $url,
        'Authorization' => "Bearer $access_token",
        'Content-Type'  => 'application/json',
        Content         => $body,
    );

    if ($response->is_success) {
        Irssi::print("Datos añadidos correctamente: $nick, $ip, $description");
    } else {
        Irssi::print("Error añadiendo datos: " . $response->status_line);
    }
}

sub get_credentials {
    # Leer las credenciales y obtener el token de acceso
    my $credentials = read_service_account_file($SERVICE_ACCOUNT_FILE);
    my $jwt = generate_jwt($credentials);
    my $access_token = get_access_token($jwt);
    
    return $access_token
}

sub find_ip_in_excel {
    my ($server, $ip_to_find, $access_token) = @_;

    # Leer los datos actuales del Google Sheet
    my $sheet_data = get_sheet_data($access_token);

    # Recopilar todas las coincidencias
    my @matching_rows;
    # Recorremos todas las filas del sheet_data
    foreach my $row (@$sheet_data) {

        # La IP está en la columna 3 (índice 2 en 0-indexed)
        my $ip = $row->[2];  # Ajustado al índice correcto (columna IP)
        

        # Verificar si la IP coincide con la que estamos buscando
        if ($ip && $ip eq $ip_to_find) {
            # Si hay coincidencia, agregar la fila completa a las coincidencias
            push @matching_rows, $row;
        }
    }

    if (@matching_rows) {
        return \@matching_rows; # Retornar referencia a la lista de coincidencias
    } else {
        return [];
    }
}

sub get_sheet_data {
    my ($access_token) = @_;
    my $range = $SHEET_NAME . '!A2:C'; # Cambia el rango según tus columnas y filas
    
    # Hacer una solicitud GET a la API de Google Sheets
    #my $url = "https://sheets.googleapis.com/v4/spreadsheets/$SPREADSHEET_ID/values/$range";
    my $url = "https://sheets.googleapis.com/v4/spreadsheets/$SPREADSHEET_ID/values:batchGet?ranges=$range";
    my $response = `curl -s -X GET -H "Authorization: Bearer $access_token" "$url"`;
    $response = decode('UTF-8', $response, 1);

    # Decodificar el JSON de respuesta
    my $data = decode_json($response);
    # Verificar si hay valores
    if ($data->{valueRanges} && @{$data->{valueRanges}} > 0 && $data->{valueRanges}[0]{values}) {
        return $data->{valueRanges}[0]{values}; # Array de filas
    } else {
        Irssi::print("No se pudieron obtener datos del Google Sheet.");
        return [];
    }
}


# Función que se llama cuando recibimos un mensaje privado
sub add_new_ip_to_excel {
    my ($server, $msg, $nick, $address, $target) = @_;

    # Comprobar si el mensaje empieza con !add_ip
    if ($msg =~ /^!add_ip (\S+) (.*)$/) {
        my $nick_complete = $1;               # El nick completo, antes del '@'
        my $description_received = decode('utf-8', $2) || '';   # Si no hay descripción, se deja vacía
        my @nick_splited = split /@/, $nick_complete;
        my $nick = $nick_splited[0];           # El nombre del nick antes del '@'
        my $ip = $nick_splited[1];             # La IP después del '@'
        
        # Leer las credenciales y obtener el token de acceso
        my $access_token = get_credentials();

        # Usar Time::Piece para obtener la fecha y hora actual
        my $t = localtime;
        my $formatted_date = $t->strftime("%d.%m.%Y");

        # Insertar los datos en Google Sheets
        insert_data($access_token, $nick_complete, $nick, $ip, $description_received, $formatted_date);
    }
    if ($msg =~ /^!search_ip (\S+)$/) {
        my $ip_to_find = $1;

        # Leer las credenciales y obtener el token de acceso
        my $access_token = get_credentials();

        #aviso que estamos buscando ips
        $server->command("msg $nick buscando coincidencias");

        # Buscar todas las coincidencias para la IP
        my $matching_rows = find_ip_in_excel($server, $ip_to_find, $access_token);

        # Verificar si hay coincidencias
        if (@$matching_rows) {
            # Extraer solo los nicks (columna 2)
            my @nicks = map { $_->[1] // "Desconocido" } @$matching_rows;

            # Enviar el resultado al usuario
            my $response_message = "Coincidencias encontradas para \x02\x0304$ip_to_find\x03\x02: " . join(", ", map { "\x02$_\x02" } @nicks);

            $server->command("msg $nick $response_message");
        } else {
            $server->command("msg $nick No se encontraron coincidencias para la IP: $ip_to_find");
        }
    }
}

# Añadir la señal para escuchar los mensajes privados
Irssi::signal_add('message private', 'add_new_ip_to_excel');
