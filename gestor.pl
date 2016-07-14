use strict;
use warnings;
use feature 'say';
# use v5.20;

use Data::Dumper;
use Data::Uniqid qw ( luniqid );


use DateTime;


# use DateTime;

use File::Slurp;

use JSON qw( );

# Args / Params
my $verbose = 0;
if('v' ~~ @ARGV){ $verbose = 1; }

# Defaults Globales
my ($sec,$min,$hour,$day,$month,$yr19,@rest) = localtime(time);
my $anio = $yr19+1900; # año actual ¿salvo q se espesifique?
my $limite_duracion = 24;

# Inventario (items disponibles) 
my @inventario =  split /\W/, read_file('inventario');
my %inventario = map { $_ => 1 } @inventario; # CABEZEADA POR REVISAR


# Pedidos (input) 
my @pedidos = read_file('pedidos.csv');

# Registro (almacen de reservas) 
my $registro_text = read_file('registro.json');
my $json = JSON->new;
my $registroJson = $json->decode($registro_text); 
my %registros = %$registroJson;



foreach (@pedidos){
	# chomp;
	if( $_ =~ /^\s*item,mes,/ ){ # borrrar primera linea
		next;
	}
	prosesar($_);
}



# Subs
sub prosesar{
	my ($resultado, $mensaje) = comprobrar_pedido($_);
	print "\n" if $verbose;

	# say $mensaje;
}




# Subrutinas
sub comprobrar_pedido {

	my $id = luniqid; # ID de pedido

	my ($item, 
		$mes, 
		$dia, 
		$hora, 
		$duracion,
		$quien,
		$comment ) =  split /\,/, $_;


=pod
	Esta sub creo, deberia returnear pedido ya normalizado
	para ingresar a los registros

	my $pedidoNormalizado = {
	  item => $item,
	  reservas => {arboldereservas}
	};
=cut

	my $por_que = "";
	my $congrats = "";

	my $item_existe;
	my $duracion_correcta;
	my $fecha_correcta;

	my $sin_registros;
	my $item_disponible;


	if(!exists($inventario{$item})){
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

				# Obtener timestamp salida y calcular vuelta
				# my $retira_t = POSIX::mktime(0,0,$hora,$dia,$mes-1,$anio-1900);
				# my $devuelve_t = POSIX::mktime(0,0,$hora+$duracion,$dia,$mes-1,$anio-1900);
				
				my $retira_t = $hora;
				my $devuelve_t = $hora+$duracion;




				# Armar array/hash para pasarlos a evaluacion/reserva

				my $pedido_ok = {
					$item => {
						$id  => {
							cuando		=> $retira_t."-".$devuelve_t, 
							quien		=> $quien,
							comentario	=> $comment
						}
					}
				};

                

				# print Dumper($pedido_ok);



				if($item_existe && $registros{$item}){

					$por_que = "Debo consultar disponiblidad";

					# Comprobar disponibilidad del item

					foreach my $i (keys %{$registros{$item}}){
						say "p: ".$retira_t."-".$devuelve_t;
						say "r: ".$registros{$item}{$i}{'cuando'};

                    	my ($s,$v) = split /-/,$registros{$item}{$i}{'cuando'};
                    
                    	if (($retira_t > $s && $retira_t < $v) || 
	                    	( $devuelve_t < $s && $devuelve_t > $v )){
	                        say "$item,NO se puede prestar"
	                   	} else {
	                        say "$item,SI se puede prestar";
	                    }
	               	}

					# $item_disponible = $disponble;
					# $por_que = $mensaje;
					# $congrats = $mensaje;


				}else{

					$sin_registros = 1;
					$congrats = 'registro LIBRE de reservas';

					# Ver como hacer esto aca y despues encapsular
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




# http://docstore.mik.ua/orelly/perl3/prog/ch03_15.htm

#DATE RELATED
# Converts a time as returned by the time function to a 9-element
#        		list with the time analyzed for the local time zone. Typically
#        		used as follows:

#             #     0    1    2     3     4    5     6     7     8
#             my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
#                                                         localtime(time);




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
