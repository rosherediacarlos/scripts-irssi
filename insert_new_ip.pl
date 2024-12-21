#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use MIME::Base64;
use Irssi;
use utf8;         
use open ':std', ':encoding(UTF-8)';
use Encode;
use Time::Piece;

# Archivo de credenciales y configuración
my $SERVICE_ACCOUNT_FILE = '/home/pi/.irssi/scripts/autorun/irssi-bot-ip-eecc7ce36b17.json';
my $SPREADSHEET_ID = '1vHzX9Ii4s5a7IzECcoQtobZB69-E2KggXTVszfIUjb4';
my $SHEET_NAME = 'Sheet1';

my $insert_ip = 0;

#descipcion para insertar datos con el whois
my $description_encoded = "";

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
    my ($server,$user, $access_token,$nick_complete, $nick, $ip, $description, $formatted_date) = @_;

    my $ua = LWP::UserAgent->new;
    my $url = "https://sheets.googleapis.com/v4/spreadsheets/$SPREADSHEET_ID/values/$SHEET_NAME:append?valueInputOption=RAW&insertDataOption=INSERT_ROWS";
    
    # Crear los nuevos datos a insertar
    my @new_data = ($nick_complete,$nick, $ip, $description, $formatted_date);

    my $body = encode_json({ values => [\@new_data] });
    
    #Enviar datos excel
    my $response = $ua->post(
        $url,
        'Authorization' => "Bearer $access_token",
        'Content-Type'  => 'application/json',
        Content         => $body,
    );

    if ($response->is_success) {
        $server->command("msg $user Datos añadidos correctamente: $nick, $ip, $description");
    } else {
        $server->command("msg $user Datos añadidos correctamente: $nick, $ip, $description");
    }
}

#Obtener las credenciales y token para la conexión
sub get_credentials {
    # Leer las credenciales y obtener el token de acceso
    my $credentials = read_service_account_file($SERVICE_ACCOUNT_FILE);
    my $jwt = generate_jwt($credentials);
    my $access_token = get_access_token($jwt);
    
    return $access_token
}

#buscar ips en el fichero
sub find_data_in_excel {
    my ($server, $data_to_find, $access_token, $option) = @_;

    # Leer los datos actuales del Google Sheet
    my $sheet_data = get_sheet_data($access_token);

    # Recopilar todas las coincidencias
    my @matching_rows;
    # Recorremos todas las filas del sheet_data
    foreach my $row (@$sheet_data) {

        # La IP está en la columna 3 (índice 2 en 0-indexed)
        my $ip = $row->[2];  # Ajustado al índice correcto (columna IP)
        # La descripción está en la columna 4 (índice 3 en 0-indexed)
        my $description = $row->[3] // '';
        #nick
        my $nick = $row->[1] // ''; 
        #date
        my $date = $row->[4] // ''; 

        # Verificar si la IP coincide con la que estamos buscando
        if ($option eq 'ip' && $ip && $ip eq $data_to_find) {
            # Agregar un hash con la IP y la descripción a las coincidencias
            push @matching_rows, { nick => $nick, description => $description , date => $date};
        }
        # Verificar si el nick coincide con la que estamos buscando
        # Si queremos que distinga mayusculas de minuculas usaremos el siguiente condición
        # ($option eq 'nick' && $nick && $nick eq $data_to_find)
        if ($option eq 'nick' && $nick && lc($nick) eq lc($data_to_find)) {
            # Agregar un hash con la IP y la descripción a las coincidencias
            push @matching_rows, { nick => $nick, description => $description , date => $date, ip => $ip};
        }
    }

    if (@matching_rows) {
        return \@matching_rows; # Retornar referencia a la lista de coincidencias
    } else {
        return [];
    }
}

#obtener datos del fichero
sub get_sheet_data {
    my ($access_token) = @_;
    my $range = $SHEET_NAME . '!A2:E'; # Cambia el rango según tus columnas y filas
    
    # Hacer una solicitud GET a la API de Google Sheets
    #my $url = "https://sheets.googleapis.com/v4/spreadsheets/$SPREADSHEET_ID/values/$range";
    my $url = "https://sheets.googleapis.com/v4/spreadsheets/$SPREADSHEET_ID/values:batchGet?ranges=$range";
    my $response = `curl -s -X GET -H "Authorization: Bearer $access_token" "$url" | iconv -f ISO-8859-1 -t UTF-8`;
    $response = decode('UTF-8', $response, Encode::FB_CROAK); # Detecta errores en la codificación
    $response = encode('UTF-8', $response); # Re-encode para limpiar errores
    
    # Decodificar el JSON de respuesta
    my $data = decode_json($response);
    # Verificar si hay valores
    if ($data->{valueRanges} && @{$data->{valueRanges}} > 0 && $data->{valueRanges}[0]{values}) {
        return $data->{valueRanges}[0]{values}; # Array de filas
    } else {
        return [];
    }
}


# Función que se llama cuando recibimos un mensaje privado
sub add_new_ip_to_excel {
    my ($server, $msg, $user, $address, $target) = @_;

    # Comprobar si el mensaje empieza con !add_ip
    if ($msg =~ /^!add_ip (\S+)(?:\s+(.*))?$/) {
        # El nick completo
        my $nick_complete = $1;      
        # Si no hay descripción, se deja vacía        
        my $description_received = decode('UTF-8', $2) || ''; 
        $description_encoded = encode('UTF-8', $description_received); 
        #divivir el nick 
        my @nick_splited = split /@/, $nick_complete;
         # El nombre del nick antes del '@'
        my $nick = $nick_splited[0];
        # La IP después del '@'          
        my $ip = $nick_splited[1];             
        
        # Leer las credenciales y obtener el token de acceso
        my $access_token = get_credentials();

        # Usar Time::Piece para obtener la fecha y hora actual
        my $t = localtime;
        my $formatted_date = $t->strftime("%d.%m.%Y");

        # Insertar los datos en Google Sheets
        insert_data($server,$user, $access_token, $nick_complete, $nick, $ip, $description_received, $formatted_date);
    }
    if ($msg =~ /^!search_ip (\S+)$/) {
        my $ip_to_find = $1;

        # Leer las credenciales y obtener el token de acceso
        my $access_token = get_credentials();

        #aviso que estamos buscando ips
        $server->command("msg $user buscando coincidencias");

        my $matching_rows = find_data_in_excel($server, $ip_to_find, $access_token, 'ip');

        # Verificar si hay coincidencias
        if (@$matching_rows) {
            # Construir un mensaje con nick y descripción
            my @details = map { 
                my $nick = $_->{nick} // "Desconocido"; # Suponiendo que nick esté en el hash
                my $description = $_->{description} // "Sin descripción";
		        my $date = $_->{date} // "Sin fecha";
                "{\x02$nick\x02 \x1Fdescripción:\x1F$description, \x1Ffecha\x1F:$date}" 
            } @$matching_rows;

            # Enviar el resultado al usuario
            my $response_message = "Coincidencias encontradas para \x02\x0304$ip_to_find\x03\x02: " . join(", ", @details);
            $server->command("msg $user $response_message");
        } else {
            $server->command("msg $user No se encontraron coincidencias para la IP: $ip_to_find");
        }
    }
    if ($msg =~ /^!search_nick (\S+)$/) {
        my $nick_to_find = $1;

        # Leer las credenciales y obtener el token de acceso
        my $access_token = get_credentials();

        #aviso que estamos buscando ips
        $server->command("msg $user buscando coincidencias");

        my $matching_rows = find_data_in_excel($server, $nick_to_find, $access_token, 'nick');

        # Verificar si hay coincidencias
        if (@$matching_rows) {
            # Construir un mensaje con nick y descripción
            my @details = map { 
                my $nick = $_->{nick} // "Desconocido"; # Suponiendo que nick esté en el hash
                my $description = $_->{description} // "Sin descripción";
		        my $date = $_->{date} // "Sin fecha";
                my $ip = $_->{ip} // "";
                "{ \x02\x1FIP/Vhost:\x1F\x02$ip \x02\x1Fdescripción:\x1F\x02$description, \x02\x1Ffecha:\x1F\x02$date}" 
            } @$matching_rows;

            # Enviar el resultado al usuario
            my $response_message = "Coincidencias encontradas para \x02\x0304$nick_to_find\x03\x02: " . join(", ", @details);
            $server->command("msg $user $response_message");
        } else {
            $server->command("msg $user No se encontraron coincidencias para la IP: $nick_to_find");
        }
    }
    if ($msg =~ /^!add_whois (\S+)(?:\s+(.*))?$/) {
        # El nick para añadir
        my $nick_to_add = $1;
   
        # Si no hay descripción, se deja vacía        
        my $description_received = decode('UTF-8', $2) || ''; 
        $description_encoded = encode('UTF-8', $description_received); 
        $insert_ip = 1;
        #Hacer whois al nick para agregar los datos   
        $server->command("whois $nick_to_add");
        
    }
}

# Captura la respuesta del comando whois (event 311)
Irssi::signal_add("event 311", sub {
    my ($server, $data) = @_;
    my (undef, $nick, $user, $ip) = split(" ", $data);
    if ($nick && $insert_ip){
         # Leer las credenciales y obtener el token de acceso
        my $access_token = get_credentials();

        # Usar Time::Piece para obtener la fecha y hora actual
        my $t = localtime;
        my $formatted_date = $t->strftime("%d.%m.%Y");

        #nick completo
        my $nick_complete = $nick."@".$ip;

        # Insertar los datos en Google Sheets
        insert_data($server,$user, $access_token, $nick_complete, $nick, $ip, $description_encoded, $formatted_date);
    }
    
});

# Añadir la señal para escuchar los mensajes privados
Irssi::signal_add('message private', 'add_new_ip_to_excel');
