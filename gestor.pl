#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
# use v5.20;
use Data::Dumper;
use Data::Uniqid qw ( luniqid );
use File::Slurp;
use JSON;

# Args / Params
my $verbose = 0;
if( 'v' ~~ @ARGV ){ $verbose = 1; }

# Defaults Globales
my ($sec,$min,$hour,$day,$month,$yr19,@rest) = localtime(time);
my $anio = $yr19+1900; # año actual ¿salvo q se indique?



my $limite_duracion = 24;

# Inventario (items disponibles)
my @inventario =  split /\W/, read_file('inventario');
my %inventario = map { $_ => 1 } @inventario; # CABEZEADA POR REVISAR

# Pedidos (input)
my @pedidos = read_file('pedidos.csv');

# Registro (almacen de reservas)
my $registro_text = read_file('registro.json');
my $json = JSON->new;
my $registro_json = $json->decode($registro_text);
my %registros = %$registro_json;

# Main Loop
foreach (@pedidos){
	# chomp;
	if( $_ =~ /^\s*item,mes,/ ){ # borrrar primera linea
		next;
	}
	procesar_linea($_);
}

print Dumper(%registros) if $verbose;

# Grabar Registros
my $registro_actualizado = $json->encode(\%registros);
write_file( 'registro.json', $registro_actualizado );


# Subrutinas ### ### ###
sub procesar_linea{
	my (
		$reporte,
		$pedido_normalizado
	) = formular_pedido($_);


	# Procesar pedido
	if($pedido_normalizado){
		my (
			$msj,
			$pedido_disponible
		) = disponibilidad($pedido_normalizado);
		$reporte .=  " -> ".$msj;

		if($pedido_disponible){
			$reporte .= " -> ".registrar_pedido($pedido_disponible);
		}
	}
	say $reporte;
}

sub formular_pedido {

	my (
		$item,
		$mes,
		$dia,
		$hora,
		$duracion,
		$quien,
		$comentario
	) =  split /\,/, $_;

	# Condiciones del pedido
	my $item_existe;

	# Integridad de las fechas
	my $duracion_correcta;
	my $fecha_correcta;

	# Pedido listo para procesar
	my $pedido_OK;

	# Informacion para el usuario
	my $porque = "";

	if(!exists($inventario{$item})){
		$item_existe = 0;
		$porque = "$item: No encontrado";

	}else {
		$item_existe = 1;
		if( ($duracion >= $limite_duracion) || ($duracion <= 0)  ){
			$porque = "Duracion: 0 < $duracion? > $limite_duracion";

		}else {
			$duracion_correcta = 1;
			my ($resultado, $mensaje) = fecha_correcta( $mes, $dia, $hora );
			$fecha_correcta = $resultado;

			if(!$fecha_correcta) {
				$porque = $mensaje;

			}else {

				# Obtener timestamp retira
				my $pedido_retira = POSIX::mktime(0,0,
					$hora,$dia,$mes-1,$anio-1900);

				# Calcular vuelta
				my $pedido_vuelve = POSIX::mktime(0,0,
					$hora+$duracion,$dia,$mes-1,$anio-1900);

				$pedido_OK = {
					item		=> $item,
					cuando		=> $pedido_retira."-".$pedido_vuelve,
					quien		=> $quien,
					comentario	=> $comentario
				};

=pod
ESTRUCTURA DE PEDIDO
	Item ( como en inventario )
	Cuando ( $pedido_retira."-".$pedido_vuelve )
	Quien Hizo el pedido
	Comentario
=cut

			}
		}
	}

	if (
		$item_existe &&
		$duracion_correcta &&
		$fecha_correcta
	){
		return
			"[$item-".
			"$anio/$mes/$dia:$hora".
			"x$duracion] ".
			"aprobado",
			$pedido_OK;
	}else{
		return
			"[$item-".
			"$anio/$mes/$dia:$hora".
			"x$duracion] ".
			"RECHAZADO ".
			"($porque)";
	}
}


sub fecha_correcta {
	my ($mes, $dia, $hora ) =  @_;

	my $mes_correcto;
	my $dia_correcto;
	my $hora_correcta;

	my $porque;
	my $limite_mes = cantidad_dias($mes);


	if( ($mes >= 1) && ($mes <= 12) ) {
		$mes_correcto = 1;
		if( ($dia >= 1) && ($dia <= $limite_mes) ) {

			$dia_correcto = 1;

			if ( $hora < 24 ){
				$hora_correcta = 1;
			}else{
				$porque = "hora $hora?"
			}
		}else{
			$porque = "dia $dia > $limite_mes?"
		}
	}else{
		$porque = "mes $mes?"
	}

	if( $mes_correcto && $dia_correcto && $hora_correcta ){
		return 1;
	}else{
		return 0, $porque;
	}
}

sub cantidad_dias{
	my $month = $_[0];

	my %mon2num = qw(
		1 31  2 28  3 31  4 30  5 31  6 30
		7 31  8 30  9 31  10 31  11 30  12 31
	);
	# ARevisar esto
	if(es_bisiesto($anio)){
		%mon2num = qw(
			1 31  2 29  3 31  4 30  5 31  6 30
			7 31  8 30  9 31  10 31  11 30  12 31
		);
	}
	return $mon2num{ lc substr($month, 0, 3) };
}

sub es_bisiesto{
	my $y = shift;
	my $bisiesto = 0;
	if($y =~ /^\d+?$/) {
		if(!($y % 400)){
			$bisiesto = 1;
		}elsif(!($y % 100)){
			$bisiesto = 0;
		}
		elsif(!($y % 4  )){
			$bisiesto = 1;
		}
	}
	return $bisiesto;
}

sub disponibilidad{

	my $p  = $_[0];
	my $item   = $p->{item};
	my $ocupado = 0;

	if($registros{$item}) {

		my (
			$pedido_retira,
			$pedido_vuelve
		) = split /-/, $p->{cuando};

		# Consultar reservas
		foreach my $reserva ( keys %{$registros{$item}} ) {
			my (
				$registro_retira,
				$registro_vuelve
			) = split /-/, $registros{$item}{$reserva}{cuando};

			# http://c2.com/cgi/wiki?TestIfDateRangesOverlap
			if( $pedido_retira < $registro_vuelve &&
				$registro_retira < $pedido_vuelve ){
				$ocupado = 1;
				# Aca habria que dar info de cual molesta?
			}
		}
	}

	if(!$ocupado){
		return "recurso disponible",$p;
	}else{
		return "recurso OCUPADO";
	}
}

sub registrar_pedido {
	my $p  = $_[0];

	my $item  = $p->{item};
	my $pedido_id = luniqid; # ID de pedido

	my $pedido_embalado = {
		cuando		=> $p->{cuando},
		quien		=> $p->{quien},
		comentario	=> $p->{comentario}
	};
	$registros{$item}{$pedido_id} = $pedido_embalado;
	return "RESERVO: $pedido_id";
}



# Basura / Reserva
# http://docstore.mik.ua/orelly/perl3/prog/ch03_15.htm

# DATE RELATED
# Converts a time as returned by the time function to a 9-element
# list with the time analyzed for the local time zone. Typically
# used as follows:

#  #     0    1    2     3     4    5     6     7     8
#  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);


# timestamp to fecha
# my $date = 20160131;


# my ( $y, $m, $d ) = unpack 'A4 A2 A2', $date;

# my $start_ts      = POSIX::mktime( 0, 0, 1, $d, $m - 1, $y - 1900 );
# my $end_ts        = POSIX::mktime( 0, 0, 23, $d, $m - 1, $y - 1900 );
# print Dumper($start_ts."-".$end_ts);

# say "retira = ", POSIX::ctime($start_ts),"devuelve = ",POSIX::ctime($end_ts);

# see POSIX

# And with mktime it's perfectly okay to just add negatives to values.
# So if you need to have 23:59:59 as your end date as suggested in the comments,
# you can just fix it up with this:

# Technically $end_ts is the first timestamp of the next day.
# Easily fixed by subtracting 1 though, if necessary. – Anomie Mar 16 '11 at 14:08


# my $end_ts = POSIX::mktime( -1, 0, 0, $d + 1, $m - 1, $y - 1900 );
# (Although, I would just like to note that the excluded endpoint is not an
# unknown case in programming.)

# my ($sec,$min,$hour,$day,$month,$yr19,@rest) = localtime(time);
# ####### To get the localtime of your system
# printf qq{Date:\t%02d-%02d-%02d\n}, $day, $month, $yr19+1900;
# printf qq{Time:\t%02d:%02d:%02d\n}, $hour, $min, $sec;

# my ( $item, $mes, $dia, $hora, $duracion ) =  split /\W/, $_;
# my $pedidoItem = {
#   item => $item,
#   mes => $mes,
#   dia => $dia,
#   hora => $hora,
#   duracion => $duracion
# };

# header($item);

# if( $item ~~ @inventario ){ # en inventario?
#   # say "Ingresando pedido: $item $mes $dia $hora $duracion";

#   if($registros{$item}){
#       my @reservasItem = @{$registros{$item}{reservas}}; #  copy or ref ?

#       my $nReservasItem = scalar @reservasItem;

#       # say "| Existen $nReservasItem reservas registrdas para: $item";

#       # MAtriz de reservas que tiene hasta el momento el item
#       # Es mejor guardar e esta manera la info en registro para no repetir
#       # YA VA DECANTAR CUANDO GRABE ESTOS REGISTROS

#       my %matrizHoraria = (); # {$mese}{$dia}$hora} = $duracion
#       for (@reservasItem){
#           my $l = $_->{duracion};
#           my $h = $_->{hora};
#           my $d = $_->{dia};
#           my $m = $_->{mes};
#           $matrizHoraria{$m}{$d}{$h} = $l;
#       }

#   }else{
#       # say "| No se encontraron reservas para: $item";
#       # $registros{$item} = { "reservas" => [$pedidoItem] };
#       # say "Creo primer registro para este item,\ncontinuo."; next;
#   }

# }
