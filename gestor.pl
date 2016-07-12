use strict;
use warnings;
use feature 'say';
# use v5.20;

use Data::Dumper;
use DateTime;


# use DateTime;

use File::Slurp;

use JSON qw( );


# Defaults Globales
my ($sec,$min,$hour,$day,$month,$yr19,@rest) = localtime(time);
my $anio = $yr19+1900; #año actual, (salvo q se especifique?)

my $verbose = 0;
if('v' ~~ @ARGV){
	$verbose = 1;
}

# Inventario (items disponibles) ###
my @inventario =  split /\W/, read_file('inventario');

# Pedidos (input) ##################
my @pedidos = read_file('pedidos.csv');

# Registro (almacen de reservas) ###
my $registro_text = read_file('registro.json');
my $json = JSON->new;
my $registroJson = $json->decode($registro_text); # Cambiar nombre Registro

my %registros = %$registroJson;


# informeReservas();

foreach (@pedidos){
	# chomp;
	if( $_ =~ /^\s*item,mes,/ ){ # borrrar primera linea
		next;
	}
	consultar($_);
}


# informeReservas();

# Subs
sub consultar{
	my ($resultado, $mensaje) = comprobrar_pedido($_);
	say $mensaje;

	# my ( $item, $mes, $dia, $hora, $duracion ) =  split /\W/, $_;
	# my $pedidoItem = {
	# 	item => $item,
	# 	mes => $mes,
	# 	dia => $dia,
	# 	hora => $hora,
	# 	duracion => $duracion
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

}




# Subrutinas
sub comprobrar_pedido {

	my $limite_duracion = 24;

	my ( $item, $mes, $dia, $hora, $duracion ) =  split /\W/, $_;

	# Deberia returnear pedido ya normalizado
	# my $pedidoNormalizado = {
	#   item => $item,
	#   duracion => $duracion
	#   %matriz_horaria,
	# };


	my $por_que = "";
	my $congrats = "";

	my $item_existe;
	my $duracion_correcta;

	my $fecha_correcta; # si la fecha esta bien formada

	my $sin_registros;


	my $item_disponible; # si el item esta en el rago de fechas solicitado


	if(!$item ~~ @inventario){
		$por_que = "No existe [$item] en el inventario";

	}else {
		$item_existe = 1;

		if($duracion > $limite_duracion){
			$por_que = "La duracion [$duracion] > $limite_duracion";

		}else {
			$duracion_correcta = 1;

			my ($resultado, $mensaje) = fecha_correcta($mes,$dia,$hora);
			$fecha_correcta = $resultado;

			if(!$fecha_correcta) {
				$por_que = $mensaje;

			}else{

				my $date_retira = DateTime->new(
					year      => $anio, # Defaults Globales
					month     => $mes,
					day       => $dia,
					hour      => $hora,
				);


				my $date_devulve = $date_retira->clone->add( hours => $duracion );

				# Recoreremos todas las horas del pedido


				my %matriz_pedido;
				my $c = 0;
				while ($date_retira <= $date_devulve) { # mientras que el comienzo no sea mas grande...
					my $y = $date_retira->year;
					my $m = $date_retira->month;
					my $d = $date_retira->day;
					my $h = $date_retira->hour;

					$matriz_pedido{$y}{$m}{$d}{$h} = $duracion - $c;

					# para evitar iteraciones podria fijarme en las reservas acá

					$date_retira->add(hours => 1); # siguiente 1 dia
					$c++;
				}

				if($registros{$item}){
					$por_que = "hay q buscar disponiblidad";

					# Ahora comprobar disponibilidad del item
					my ($disponble,$mensaje) = disponiblidad_pedido(
						\%matriz_pedido,
						$registros{$item}{reservas}
					);
					$item_disponible = $disponble;
					$por_que = $mensaje;
					$congrats = $mensaje;


				}else{
					$sin_registros = 1;
						$congrats = 'registro LIBRE de reservas';
				}

			}

		}
	}


	if ($item_existe
		&& $duracion_correcta
		&& $fecha_correcta
		&& ($sin_registros || $item_disponible)
		){
		return 1, "$item\t$dia/$mes:$hora\tx$duracion\tAPROBADO\t($congrats)";
	}else{
		return 0, "$item\t$dia/$mes:$hora\tx$duracion\tRECHAZADO\t($por_que)";
	}




}


sub fecha_correcta {

	my ($mes, $dia, $hora ) =  @_;

	my $mes_correcto;
	my $dia_correcto;
	my $hora_correcta;

	my $por_que;


	if (($mes > 0) && ($mes < 13) ){
		$mes_correcto = 1;
		if (($dia > 0) && ($dia < 32) ){
			# TO DO 'dias en el mes' dinamico :)
			$dia_correcto = 1;
			if ($hora < 24){
				$hora_correcta = 1;
			}else{
				$por_que = "la HORA [$hora]"
			}
		}else{
			$por_que = "el DIA [$dia]"
		}
	}else{
		$por_que = "el mes: [$mes]"
	}




	if ($mes_correcto && $dia_correcto && $hora_correcta){
		return 1;
	}else{
		return 0, "Hay un problema con $por_que";
	}

}

sub disponiblidad_pedido {
	my $pedido = $_[0];
	my $registro_reservas = $_[1];
	# print Dumper($registro_reservas);

	# my $pedidoJson = $json->encode($pedido); # Cambiar nombre Registro
	# print Dumper($pedidoJson);


	foreach my $anio (sort keys $pedido) {
		say "anio:$anio" if $verbose;

		foreach my $mes ( sort keys $pedido->{$anio} ) {
			say "-mes: $mes" if $verbose;

			foreach my $dia ( sort keys $pedido->{$anio}{$mes} ) {
				say "--dia:$dia" if $verbose;

				say "---horas:" if $verbose;

				my $libre = 0; # CABEZEADA POR MEJORAR
				foreach my $hora ( sort { $a <=> $b } keys $pedido->{$anio}{$mes}{$dia} ) {
					my $duracion = $pedido->{$anio}{$mes}{$dia}{$hora};
					print "$hora:" if $verbose;

					# comparar con registros:
					$libre = 0; # CABEZEADA POR MEJORAR
					if($registro_reservas->{$anio}{$mes}{$dia}{$hora}){
						my $vuelve = $registro_reservas->{$anio}{$mes}{$dia}{$hora};
						print "ocupado " if $verbose;
						return 0,"el $dia/$mes a las $hora ocupado x $vuelve hs";
					}else{
						print "libre " if $verbose;
						$libre = 1; # CABEZEADA POR MEJORAR
					}

				}
				print "\n" if $verbose;

				if($libre) {
					return 1,"todas las horas LIBRES";
				}
			}
		}
	}
}



sub reservarPedido {

	# my $p = $_[-1];
	# push $_[0], $p;


	# # cuando los pedidos lleguen con la duracion chequeada vamos a
	# # poder hacer algo como esto: REVISAR RECURCION

	# # for ($i = 0, $i < $p{duracion}, $i++){
	# #     my $pedido = {
	# #         # item =>$item,
	# #         mes => $mes,
	# #         dia => $dia,
	# #         hora => $hora,
	# #         duracion => $duracion,
	# #     };
	# # reservarPedido($registros{$item}{reservas}, $pedido);
	# # }


	# # mostrar esto en la matriz para ver que estebien
	# print "+ Agregue la reserva: ";
	# print_hash($_[0][-1]);

}



# Informes

sub informePedidos {
	header('Informe de Pedidos');

	# foreach my $key ( sort keys %registros ){
	#   my $cuantasReservas = scalar @{$registros{$key}{reservas}};
	#   say "Item: $key -> $cuantasReservas reservas";
	# }

}

sub informeReservas {
	header('Informe de Registros');

	foreach my $key ( sort keys %registros ){
		my $cuantasReservas = scalar @{$registros{$key}{reservas}};
		say "Item: $key -> $cuantasReservas reservas";
	}

}

# Utiles

sub print_hash{
	my $href = shift;
	print "$_:$href->{$_} " for keys %{$href};
}

sub header{
	print "\n";
	my $s = shift;
	my $l = length $s;
	my $dif = 26 - $l;
	print "### ";
	print $s;
	print " ";
	print "#"x$dif;
	print "\n";
}


# my ($sec,$min,$hour,$day,$month,$yr19,@rest) = localtime(time);
# ####### To get the localtime of your system
# printf qq{Date:\t%02d-%02d-%02d\n}, $day, $month, $yr19+1900;
# printf qq{Time:\t%02d:%02d:%02d\n}, $hour, $min, $sec;
