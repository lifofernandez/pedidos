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
	prosesar($_);
}


# informeReservas();

# Subs
sub prosesar{
	my ($resultado, $mensaje) = comprobrar_pedido($_);
	print "\n" if $verbose;

	say $mensaje;
}




# Subrutinas
sub comprobrar_pedido {

	my $limite_duracion = 24;

	my ( $item, $mes, $dia, $hora, $duracion ) =  split /\W/, $_;

	# Esta sub creo, deberia returnear pedido ya normalizado
	# para ingresar a los registros

	# my $pedidoNormalizado = {
	#   item => $item,
	#   reservas => {arboldereservas}
	# };

	my $por_que = "";
	my $congrats = "";

	my $item_existe;
	my $duracion_correcta;
	my $fecha_correcta;

	my $sin_registros;
	my $item_disponible;

	my %palabras = map { $_ => 1 } @inventario; # CABEZEADA POR REVISAR

	if(!exists($palabras{$item})){
		$por_que = "No existe [$item] en el inventario";
		$item_existe = 0;
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

				if($item_existe && $registros{$item}){
					$por_que = "hay q Consultar Disponiblidad";

					# Ahora comprobar disponibilidad del item
					# obtener timestam salida y calular vuelta
					# armar array/hash para pasarlos a evaluacion

					my ( $y, $m, $d ) = unpack 'A4 A2 A2', $date;
					my $start_ts      = POSIX::mktime( 0, 0, 0, $d,     $m - 1, $y - 1900 );
					my $end_ts        = POSIX::mktime( 0, 0, 0, $d + 1, $m - 1, $y - 1900 );

					my $pedido_OK = {$item,@fechas = ($sale,$vuelve]};
					my ($disponble,$mensaje) = disponiblidad_pedido(
						# %pedido,
						$registros{$item}{reservas}
					);

					$item_disponible = $disponble;
					$por_que = $mensaje;
					$congrats = $mensaje;


				}else{

					$sin_registros = 1;
					$congrats = 'registro LIBRE de reservas';

					# Ver como hacer esto aca y encapsular
					# push $registros{$item}{reservas}{2016}, $matriz_pedido->{2016};

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

	if (($mes > 0) && ($mes < 13) ) {
		$mes_correcto = 1;
		if (($dia > 0) && ($dia < 32) ) {
			$dia_correcto = 1; # TO DO: 'dias en el mes' dinamico :)

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

	# my $pedidoJson = $json->encode($pedido); # Cambiar nombre Registro
	# print Dumper($pedidoJson);


}



sub reservar_pedido {

	# my $p = $_[-1];
	# push $_[0], $p;


	# # cuando los pedidos lleguen con la duracion chequeada vamos a

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

sub informeReservas {
	header('Informe de Registros');

	foreach my $key ( sort keys %registros ){
		my $cuantasReservas = scalar @{$registros{$key}{reservas}};
		say "Item: $key -> $cuantasReservas reservas";
	}
}

# Utiles

# sub print_hash{
# 	my $href = shift;
# 	print "$_:$href->{$_} " for keys %{$href};
# }

# sub header{
# 	print "\n";
# 	my $s = shift;
# 	my $l = length $s;
# 	my $dif = 26 - $l;
# 	print "### ";
# 	print $s;
# 	print " ";
# 	print "#"x$dif;
# 	print "\n";
# }






# Basura / Reserva

# my ($sec,$min,$hour,$day,$month,$yr19,@rest) = localtime(time);
# ####### To get the localtime of your system
# printf qq{Date:\t%02d-%02d-%02d\n}, $day, $month, $yr19+1900;
# printf qq{Time:\t%02d:%02d:%02d\n}, $hour, $min, $sec;

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