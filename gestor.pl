use strict;
use warnings;
use feature 'say';
use Data::Dumper;

# use DateTime;

use File::Slurp;

use JSON qw( );
my $filename = 'registro.json';
my $registro_text = do {
   open(my $json_fh, "<:encoding(UTF-8)", $filename)
	  or die("Can't open \$filename\": $!\n");
   local $/;
   <$json_fh>
};

# Inventario (items disponibles) ###
my @inventario =  split /\W/, read_file('inventario');

# Pedidos (input) ##################
my @pedidos = read_file('pedidos.csv');

# Registro (almacen de reservas) ###
my $json = JSON->new;
my $registroJson = $json->decode($registro_text); # Cambiar nombre Registro

my %registros = %$registroJson;


informeReservas();

foreach (@pedidos){
	# chomp;
	if( $_ =~ /^\s*item,mes,/ ){ # borrrar primera linea
		next;
	}
	consultar($_);
}

informeReservas();

# Subs
sub consultar{
	my ($item,$mes,$dia,$hora,$duracion) =  split /\W/, $_;

	my $pedidoItem = {
		# item =>		$item,
		mes => $mes,
		dia => $dia,
		hora => $hora,
		duracion => $duracion
	};

	# Limitar/filtrar  mes (1..12) dia (1...dias en el mes) hora(1..24)
	# AGREGAR CAMPOS: COMENTARIO Y FAMILIA/TIPO

	# print Dumper($pedidoItem);

	header($item);

	if($item ~~ @inventario){ # en inventario?
		say "Ingresando pedido: $item $mes $dia $hora $duracion";

		if($registros{$item}){ #esto se va lamar registros{item}
			my @reservasItem = @{$registros{$item}{reservas}};
			my $nReservasItem = scalar @reservasItem;
			say "| Existen $nReservasItem reservas registrdas para: $item";

			# MATRIX de reservas que tiene hasta el momento el item
			# Es mejor guardarlo en registro para no repetir
			# YA VA DECANTAR CUANDO GRABE ESTOS REGISTROS

			my %reservasMatrix = (); # {$mese}{$dia}$hora} = $duracion
			for (@reservasItem){
				my $l = $_->{duracion};
				my $h = $_->{hora};
				my $d = $_->{dia};
				my $m = $_->{mes};
				$reservasMatrix{$m}{$d}{$h} = $l;
			}

			# Buscar lugar libre en la matriz...
			# ??? Encapsular buscarenmatrix(matriz, pedido) para poder hacer recursivo
			# en duraciones mayores a 1

			if($mes ~~ %reservasMatrix){
				say "| Mes: $mes ocupado, voy a buscar en los dias...";

				if($dia ~~ %{$reservasMatrix{$mes}}){
					say "|| Dia: $dia ocupado, voy q buscar en las horas...";

					if($hora ~~ %{$reservasMatrix{$mes}{$dia}}){
						say "||| Hora: $hora ocupada, hay q buscar otra fecha disponible...";

						# LISTO hasta aca tengo QUE:
						# * Mostrar algo como el proximo dia mes hora disponible
						#   AKA Cuando vuelve el item
						# ??? continuar ???

					}else{
						say "||| Hora: $hora libre!";


						# Temas relacionados a la duracion del pedido...

						# ??? Ordenar la matriz ???
						# ??? para consular horas / tiempo hasta proxima reserva ???
						# para preguntar: Quiere guardar la reserva? (tenga en
						# cuenta debera devolver el item antes)

						# Si dice que SI, recursivear hasta que "choque"
						# con una hora ocupada y ?continue?.
						# ??? poner limite de hora + duracion < 24 ???

						# Si dice que NO, exit!

						# Armar ARRAY de PEDIDOS X proximas horas
						# desde ahora hasta $duracion

						# CALCULAR SALTOS DE DIA {$h+i%24}

						# Y PASAR CADA hora POR LA MATRIX para reservar
						# wile(@PEDIDOS < duracion)){
						# 	reservarHora(matrix, pedido)
						# 		= $duracion - $delta (rampa hasta que libera ;)
						# }

						##########################################################
						# poniendo valores de durcion decendentes (duracion - i )
						# que hay entre el hago que cuqndo sea 1 termine el loop


						# Evaluar duracion:

						if($duracion > 1){
							say "Duracion mayor a 1 hr (deberia reservar las proximas $duracion hs)";
							say "por ahora, continuo."; next;
						}else{
							# Antes de agregar tengo QUE:
							reservarHora($registros{$item}{reservas}, $pedidoItem);
							say "continuo."; next;
						}
					}

				}else{
					say "|| Dia: $dia libre!";

					# Habria que estar seguros que la duracion no pisa otra
					# reserva del proximo dia...

					reservarHora($registros{$item}{reservas}, $pedidoItem);
					say "continuo."; next;
					next;
				}

			}else{
				say "| Mes: $mes libre!";

				# Habria que estar seguros que la duracion no pisa otra
				# reserva del proximo dia..

				reservarHora($registros{$item}{reservas}, $pedidoItem);
				say "continuo."; next;
				next;
			} # Termina matrix

		}else{
			say "| No se encontraron reservas para: $item";
			$registros{$item} = {"reservas" => [$pedidoItem]}; # Revisar estructura
			say "Creo primer registro para este item,\ncontinuo."; next;
		}

	}else{
		say "\nNo existe: $item en el inventario ###";
	}

}

# Subs


sub reservarHora {

	my $p = $_[-1];
	push $_[0], $p;

	# mostrar esto en la matrix para ver que estebien
	print "+ Agregue la reserva: ";
	print_hash($_[0][-1]);

}

sub informePedido {
	header('informe de Pedidos');

	# foreach my $key ( sort keys %registros ){
	# 	my $cuantasReservas = scalar @{$registros{$key}{reservas}};
	# 	say "Item: $key -> $cuantasReservas reservas";
	# }
}

sub informeReservas {
	header('informe de Registros');

	foreach my $key ( sort keys %registros ){
		my $cuantasReservas = scalar @{$registros{$key}{reservas}};
		say "Item: $key -> $cuantasReservas reservas";
	}
}

sub print_hash {
	my $href = shift;
	print "$_:$href->{$_} " for keys %{$href};
	print "\n";

}

sub header {
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
